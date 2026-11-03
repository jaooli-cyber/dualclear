#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
readonly ROOT_DIR
readonly WORKSPACE="$ROOT_DIR/gate"
readonly FE_BIN="${FE_BIN:-$ROOT_DIR/.contest-tools/fe_linux_amd64}"
readonly OUT_DIR="$ROOT_DIR/out/metrics"
readonly SNAPSHOT_FILE="$ROOT_DIR/demo/evm-metrics.env"
readonly EXPECTED_FE_SHA256="3732fbe8a6e9d2ea3925d02d0e3a1478bc1e01d742c2be75d3ea7300c46c45f0"
readonly EXPECTED_VERSION="fe 26.5.0 (3dab95f)"
readonly EIP170_RUNTIME_LIMIT=24576

if [[ ! -x "$FE_BIN" ]]; then
    printf 'Fe binary not found at %s; run make setup first.\n' "$FE_BIN" >&2
    exit 1
fi

fe_sha256="$(sha256sum "$FE_BIN" | cut -d ' ' -f 1)"
if [[ "$fe_sha256" != "$EXPECTED_FE_SHA256" ]]; then
    printf 'Unexpected Fe binary SHA-256: %s (expected %s)\n' \
        "$fe_sha256" "$EXPECTED_FE_SHA256" >&2
    exit 1
fi

version_output="$("$FE_BIN" --version)"
if [[ "$version_output" != "$EXPECTED_VERSION" ]]; then
    printf 'Unexpected Fe version: %s (expected %s)\n' \
        "$version_output" "$EXPECTED_VERSION" >&2
    exit 1
fi

evm_source_bundle_sha256="$(
    cd -- "$ROOT_DIR"
    sha256sum -- \
        gate/fe.toml \
        gate/core/fe.toml gate/core/src/lib.fe \
        gate/evm/fe.toml gate/evm/src/lib.fe |
        sha256sum | cut -d ' ' -f 1
)"

if [[ -L "$ROOT_DIR/out" || -L "$OUT_DIR" ]]; then
    printf 'Refusing symlinked metrics output path: %s\n' "$OUT_DIR" >&2
    exit 1
fi

mkdir -p -- "$OUT_DIR"
find "$OUT_DIR" -mindepth 1 -depth -delete

"$FE_BIN" build \
    --backend sonatina --profile release -O1 \
    --emit bytecode,runtime-bytecode,abi,metadata \
    --out-dir "$OUT_DIR" \
    -i dualclear_evm "$WORKSPACE" >&2

readonly CREATION_FILE="$OUT_DIR/DualClearGate.bin"
readonly RUNTIME_FILE="$OUT_DIR/DualClearGate.runtime.bin"
readonly ABI_FILE="$OUT_DIR/DualClearGate.abi.json"

hex_character_count() {
    local file="$1"
    local character_count
    local hex_digit_count

    if [[ ! -s "$file" ]]; then
        printf 'Missing or empty bytecode artifact: %s\n' "$file" >&2
        return 1
    fi

    character_count="$(wc -c <"$file")"
    hex_digit_count="$(LC_ALL=C tr -cd '0-9a-fA-F' <"$file" | wc -c)"
    if ((character_count != hex_digit_count)); then
        printf 'Non-hexadecimal content in bytecode artifact: %s\n' "$file" >&2
        return 1
    fi
    if ((character_count % 2 != 0)); then
        printf 'Odd hexadecimal length in bytecode artifact: %s\n' "$file" >&2
        return 1
    fi

    printf '%s' "$character_count"
}

creation_characters="$(hex_character_count "$CREATION_FILE")"
runtime_characters="$(hex_character_count "$RUNTIME_FILE")"
if [[ ! -s "$ABI_FILE" ]]; then
    printf 'Missing or empty ABI artifact: %s\n' "$ABI_FILE" >&2
    exit 1
fi

creation_bytes=$((creation_characters / 2))
runtime_bytes=$((runtime_characters / 2))
abi_bytes="$(wc -c <"$ABI_FILE")"
runtime_headroom=$((EIP170_RUNTIME_LIMIT - runtime_bytes))

creation_sha256="$(sha256sum "$CREATION_FILE" | cut -d ' ' -f 1)"
runtime_sha256="$(sha256sum "$RUNTIME_FILE" | cut -d ' ' -f 1)"
abi_sha256="$(sha256sum "$ABI_FILE" | cut -d ' ' -f 1)"

emit_metrics() {
    printf 'fe_version=26.5.0\n'
    printf 'fe_commit=3dab95f\n'
    printf 'fe_binary_sha256=%s\n' "$fe_sha256"
    printf 'evm_source_bundle_sha256=%s\n' "$evm_source_bundle_sha256"
    printf 'backend=sonatina\n'
    printf 'profile=release\n'
    printf 'optimizer=O1\n'
    printf 'creation_bytecode_bytes=%s\n' "$creation_bytes"
    printf 'runtime_bytecode_bytes=%s\n' "$runtime_bytes"
    printf 'abi_json_bytes=%s\n' "$abi_bytes"
    printf 'eip170_runtime_limit_bytes=%s\n' "$EIP170_RUNTIME_LIMIT"
    printf 'eip170_runtime_headroom_bytes=%s\n' "$runtime_headroom"
    printf 'creation_bytecode_sha256=%s\n' "$creation_sha256"
    printf 'runtime_bytecode_sha256=%s\n' "$runtime_sha256"
    printf 'abi_json_sha256=%s\n' "$abi_sha256"
}

metrics_output="$(emit_metrics)"
printf '%s\n' "$metrics_output"

if ((runtime_bytes > EIP170_RUNTIME_LIMIT)); then
    printf 'status=FAIL_runtime_exceeds_eip170\n'
    exit 1
fi

if [[ ! -f "$SNAPSHOT_FILE" ]]; then
    printf 'Metric snapshot missing: %s\n' "$SNAPSHOT_FILE" >&2
    printf 'status=FAIL_snapshot_missing\n'
    exit 1
fi

if ! cmp -s -- "$SNAPSHOT_FILE" <(printf '%s\n' "$metrics_output"); then
    printf 'EVM metric snapshot drift: %s\n' "$SNAPSHOT_FILE" >&2
    diff -u -- "$SNAPSHOT_FILE" <(printf '%s\n' "$metrics_output") >&2 || true
    printf 'status=FAIL_snapshot_drift\n'
    exit 1
fi

printf 'status=PASS\n'
