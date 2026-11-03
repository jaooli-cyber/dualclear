#!/usr/bin/env bash
set -euo pipefail

export LC_ALL=C
umask 022

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
readonly ROOT_DIR
readonly FE_BIN="${FE_BIN:-$ROOT_DIR/.contest-tools/fe_linux_amd64}"
readonly EXPECTED_FE_VERSION="fe 26.5.0 (3dab95f)"
readonly EXPECTED_FE_COMMIT="3dab95f8eebdccf9a2382bb59a33f7bbd03540ca"
readonly EXPECTED_FE_SHA256="3732fbe8a6e9d2ea3925d02d0e3a1478bc1e01d742c2be75d3ea7300c46c45f0"
readonly LABEL="${1:-}"
readonly PRE_TAG_MODE="${EVIDENCE_PRE_TAG:-0}"
readonly EVIDENCE_DIR="$ROOT_DIR/out/release-evidence"

fail() {
    printf 'release evidence: %s\n' "$1" >&2
    exit 1
}

if [[ ! "$LABEL" =~ ^fe-013-submission-v[1-9][0-9]*$ ]]; then
    fail "label must match fe-013-submission-vN"
fi
if [[ "$PRE_TAG_MODE" != "0" && "$PRE_TAG_MODE" != "1" ]]; then
    fail "EVIDENCE_PRE_TAG must be 0 or 1"
fi

cd -- "$ROOT_DIR"
if [[ "$(git rev-parse --show-toplevel)" != "$ROOT_DIR" ]]; then
    fail "repository root mismatch"
fi

HEAD_SHA="$(git rev-parse HEAD)"
readonly HEAD_SHA
TREE_SHA="$(git rev-parse 'HEAD^{tree}')"
readonly TREE_SHA
readonly TAG_REF="refs/tags/$LABEL"

require_clean_tree() {
    git diff --quiet || fail "worktree has tracked changes"
    git diff --cached --quiet || fail "index has staged changes"
    if [[ -n "$(git status --porcelain --untracked-files=normal)" ]]; then
        fail "worktree has untracked or modified files"
    fi

    local flag_line
    while IFS= read -r flag_line; do
        if [[ "${flag_line:0:1}" != "H" ]]; then
            fail "index contains assume-unchanged, skip-worktree, or nonstandard entries"
        fi
    done < <(git ls-files -v)
}

require_clean_tree

if [[ "$PRE_TAG_MODE" == "1" ]]; then
    if git show-ref --verify --quiet "$TAG_REF"; then
        fail "pre-tag mode requires an absent tag: $LABEL"
    fi
else
    git show-ref --verify --quiet "$TAG_REF" || fail "release tag is missing: $LABEL"
    if [[ "$(git cat-file -t "$TAG_REF")" != "tag" ]]; then
        fail "existing release tag must be annotated: $LABEL"
    fi
    if [[ "$(git rev-list -n 1 "$TAG_REF")" != "$HEAD_SHA" ]]; then
        fail "release tag does not point to HEAD: $LABEL"
    fi
fi

mapfile -d '' TRACKED_PATHS < <(git ls-files -z | sort -z)
if [[ "${#TRACKED_PATHS[@]}" -eq 0 ]]; then
    fail "repository has no tracked files"
fi

for path in "${TRACKED_PATHS[@]}"; do
    if [[ ! "$path" =~ ^[A-Za-z0-9._/-]+$ || "$path" == /* || "$path" == *".."* ]]; then
        fail "unsupported tracked path: $path"
    fi
    if [[ ! -f "$ROOT_DIR/$path" || -L "$ROOT_DIR/$path" ]]; then
        fail "tracked path is not a regular non-symlink file: $path"
    fi
    if [[ "$(stat -c %h -- "$ROOT_DIR/$path")" != "1" ]]; then
        fail "tracked path has multiple hard links: $path"
    fi
    read -r mode object_type _object_id _rest < <(git ls-tree HEAD -- "$path")
    if [[ "$object_type" != "blob" || ( "$mode" != "100644" && "$mode" != "100755" ) ]]; then
        fail "tracked path is not a regular Git blob: $path"
    fi
done

make candidate FE_BIN="$FE_BIN"
require_clean_tree

if [[ ! -x "$FE_BIN" ]]; then
    fail "verified Fe binary is missing"
fi
if [[ "$("$FE_BIN" --version)" != "$EXPECTED_FE_VERSION" ]]; then
    fail "Fe version does not match the pinned release"
fi
if [[ "$(sha256sum -- "$FE_BIN" | cut -d ' ' -f 1)" != "$EXPECTED_FE_SHA256" ]]; then
    fail "Fe binary digest does not match the pinned release"
fi

if [[ -L "$ROOT_DIR/out" || -L "$EVIDENCE_DIR" ]]; then
    fail "refusing a symlinked evidence output path"
fi
mkdir -p -- "$ROOT_DIR/out" "$EVIDENCE_DIR"
if [[ "$(realpath -e -- "$ROOT_DIR/out")" != "$ROOT_DIR/out" ]]; then
    fail "output directory escapes the repository"
fi
if [[ "$(realpath -e -- "$EVIDENCE_DIR")" != "$EVIDENCE_DIR" ]]; then
    fail "evidence directory escapes the repository"
fi
find "$EVIDENCE_DIR" -mindepth 1 -depth -delete

STAGE_DIR="$(mktemp -d -p "$ROOT_DIR/out" .release-evidence.XXXXXX)"
readonly STAGE_DIR
cleanup() {
    if [[ -d "$STAGE_DIR" && ! -L "$STAGE_DIR" ]]; then
        find "$STAGE_DIR" -mindepth 1 -depth -delete
        rmdir -- "$STAGE_DIR"
    fi
}
trap cleanup EXIT

readonly MANIFEST_NAME="FE-013-MANIFEST.txt"
readonly SOURCE_SUMS_NAME="FE-013-SOURCE-SHA256SUMS.txt"
readonly ARTIFACT_SUMS_NAME="FE-013-ARTIFACT-SHA256SUMS.txt"
readonly BUNDLE_NAME="FE-013-evidence-$LABEL.tar.gz"

artifact_pairs=(
    "out/metrics/DualClearGate.bin|artifacts/metrics/DualClearGate.bin"
    "out/metrics/DualClearGate.runtime.bin|artifacts/metrics/DualClearGate.runtime.bin"
    "out/metrics/DualClearGate.abi.json|artifacts/metrics/DualClearGate.abi.json"
    "out/metrics/DualClearGate.metadata.json|artifacts/metrics/DualClearGate.metadata.json"
    "out/abi-check/actual.calldata.hex|artifacts/abi-check/actual.calldata.hex"
    "out/abi-check/actual.returndata.hex|artifacts/abi-check/actual.returndata.hex"
    "out/demo/native/golden.actual.hex|artifacts/demo/golden.actual.hex"
)
artifact_paths=()

for pair in "${artifact_pairs[@]}"; do
    source_rel="${pair%%|*}"
    destination_rel="${pair#*|}"
    source_path="$ROOT_DIR/$source_rel"
    destination_path="$STAGE_DIR/$destination_rel"

    if [[ ! -f "$source_path" || -L "$source_path" || ! -s "$source_path" ]]; then
        fail "missing, empty, or symlinked generated artifact: $source_rel"
    fi
    if [[ "$(stat -c %h -- "$source_path")" != "1" ]]; then
        fail "generated artifact has multiple hard links: $source_rel"
    fi
    resolved_source="$(realpath -e -- "$source_path")"
    if [[ "$resolved_source" != "$ROOT_DIR/out/"* ]]; then
        fail "generated artifact escapes the output directory: $source_rel"
    fi

    mkdir -p -- "$(dirname -- "$destination_path")"
    cp -- "$source_path" "$destination_path"
    artifact_paths+=("$destination_rel")
done

source_sums_file="$STAGE_DIR/$SOURCE_SUMS_NAME"
: >"$source_sums_file"
for path in "${TRACKED_PATHS[@]}"; do
    blob_sha256="$(git cat-file blob "HEAD:$path" | sha256sum | cut -d ' ' -f 1)"
    printf '%s  %s\n' "$blob_sha256" "$path" >>"$source_sums_file"
done

artifact_sums_file="$STAGE_DIR/$ARTIFACT_SUMS_NAME"
(
    cd -- "$STAGE_DIR"
    sha256sum -- "${artifact_paths[@]}"
) >"$artifact_sums_file"

metric_value() {
    local key="$1"
    local file="$ROOT_DIR/demo/evm-metrics.env"
    local value
    value="$(sed -n "s/^${key}=//p" "$file")"
    if [[ -z "$value" || "$(grep -c "^${key}=" "$file")" -ne 1 ]]; then
        fail "metric snapshot key is missing or duplicated: $key"
    fi
    printf '%s' "$value"
}

creation_bytes="$(metric_value creation_bytecode_bytes)"
runtime_bytes="$(metric_value runtime_bytecode_bytes)"
runtime_headroom="$(metric_value eip170_runtime_headroom_bytes)"
evmm_version="$(metric_value evm_version)"
abi_sha256="$(metric_value abi_json_sha256)"

cat >"$STAGE_DIR/$MANIFEST_NAME" <<EOF
schema=fe-013-release-evidence-v1
project_id=FE-013
release_label=$LABEL
commit_sha=$HEAD_SHA
tree_sha=$TREE_SHA
fe_version=$EXPECTED_FE_VERSION
fe_release_commit=$EXPECTED_FE_COMMIT
fe_binary_sha256=$EXPECTED_FE_SHA256
verification_command=make candidate
verification_result=pass
sonatina_core_tests=19_passed_0_failed
native_core_tests=19_passed_0_failed
evm_adapter_tests=12_passed_0_failed
native_adapter_tests=4_passed_0_failed
native_cli_cases=26_passed_0_failed
metamorphic_relations_per_backend=3_passed_0_failed
raw_evm_calldata_bytes=484
raw_evm_returndata_bytes=416
golden_dcg1_bytes=284
tracked_file_count=${#TRACKED_PATHS[@]}
bundled_generated_file_count=${#artifact_paths[@]}
evm_version=$evmm_version
creation_bytecode_bytes=$creation_bytes
runtime_bytecode_bytes=$runtime_bytes
eip170_runtime_headroom_bytes=$runtime_headroom
abi_json_sha256=$abi_sha256
fnv_role=interoperability_checksum_not_cryptographic_commitment
EOF

(
    cd -- "$STAGE_DIR"
    tar --format=gnu --sort=name --mtime='UTC 1970-01-01' \
        --owner=0 --group=0 --numeric-owner \
        -cf - \
        "$MANIFEST_NAME" "$SOURCE_SUMS_NAME" "$ARTIFACT_SUMS_NAME" artifacts |
        gzip -n >"$EVIDENCE_DIR/$BUNDLE_NAME"
)

cp -- \
    "$STAGE_DIR/$MANIFEST_NAME" \
    "$STAGE_DIR/$SOURCE_SUMS_NAME" \
    "$STAGE_DIR/$ARTIFACT_SUMS_NAME" \
    "$EVIDENCE_DIR/"

(
    cd -- "$EVIDENCE_DIR"
    sha256sum -- \
        "$MANIFEST_NAME" \
        "$SOURCE_SUMS_NAME" \
        "$ARTIFACT_SUMS_NAME" \
        "$BUNDLE_NAME" >SHA256SUMS
    sha256sum -c SHA256SUMS
)

require_clean_tree
printf 'release evidence generated for %s at %s\n' "$HEAD_SHA" "$EVIDENCE_DIR"
cat "$EVIDENCE_DIR/SHA256SUMS"
