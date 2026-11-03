#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
readonly ROOT_DIR
readonly WORKSPACE="$ROOT_DIR/gate"
readonly FE_BIN="${FE_BIN:-$ROOT_DIR/.contest-tools/fe_linux_amd64}"
readonly OUT_DIR="$ROOT_DIR/out/demo"
readonly VECTOR="$ROOT_DIR/demo/golden.json"

if [[ ! -x "$FE_BIN" ]]; then
    printf 'Fe binary not found at %s; run make setup first.\n' "$FE_BIN" >&2
    exit 1
fi


mkdir -p -- "$OUT_DIR"
find "$OUT_DIR" -mindepth 1 -depth -delete
mkdir -p -- "$OUT_DIR/native"

printf '\n[1/5] Shared golden vector on Sonatina\n'
"$FE_BIN" test \
    --backend sonatina --profile test -O1 \
    --jobs 1 --grouped \
    --filter golden_clearing_uses_largest_remainder_and_id_tie_break \
    -i dualclear_core "$WORKSPACE"

printf '\n[2/5] EVM adapter golden vector\n'
"$FE_BIN" test \
    --backend sonatina --profile test -O1 \
    --jobs 1 --grouped \
    --filter evm_adapter_matches_the_shared_golden \
    -i dualclear_evm "$WORKSPACE"

printf '\n[3/5] Shared golden vector on native\n'
"$FE_BIN" test \
    --backend native --profile test -O1 \
    --jobs 1 --grouped --native-timeout-secs 120 \
    --filter golden_clearing_uses_largest_remainder_and_id_tie_break \
    -i dualclear_core "$WORKSPACE"

printf '\n[4/5] Native adapter golden vector\n'
"$FE_BIN" test \
    --backend native --profile test -O1 \
    --jobs 1 --grouped --native-timeout-secs 120 \
    --filter native_adapter_matches_the_shared_golden \
    -i dualclear_native "$WORKSPACE"

printf '\n[5/5] Standalone native canary\n'
"$FE_BIN" build \
    --backend native --profile release -O1 \
    --emit executable \
    --out-dir "$OUT_DIR/native" \
    -i dualclear_native "$WORKSPACE"

mapfile -t native_executables < <(
    find "$OUT_DIR/native" -maxdepth 1 -type f -perm -u+x -print | sort
)
if [[ "${#native_executables[@]}" -ne 1 ]]; then
    printf 'Expected one native executable, found %s.\n' \
        "${#native_executables[@]}" >&2
    exit 1
fi
"${native_executables[0]}"

printf '\nAll five execution checks passed. Human-readable reference vector:\n\n'
cat "$VECTOR"
printf '\n\nDualClear cross-backend golden demo: PASS\n'
