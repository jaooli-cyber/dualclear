#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
readonly ROOT_DIR
readonly WORKSPACE="$ROOT_DIR/gate"
readonly FE_BIN="${FE_BIN:-$ROOT_DIR/.contest-tools/fe_linux_amd64}"
readonly OUT_DIR="$ROOT_DIR/out/demo"
readonly VECTOR="$ROOT_DIR/demo/golden.json"
readonly VECTOR_HEX="$ROOT_DIR/demo/golden.dcg1.hex"

if [[ ! -x "$FE_BIN" ]]; then
    printf 'Fe binary not found at %s; run make setup first.\n' "$FE_BIN" >&2
    exit 1
fi

mkdir -p -- "$OUT_DIR"
find "$OUT_DIR" -mindepth 1 -depth -delete
mkdir -p -- "$OUT_DIR/native"

printf '\n[1/5] Exact DCG1 bytes on Sonatina\n'
"$FE_BIN" test \
    --backend sonatina --profile test -O1 \
    --jobs 1 --grouped \
    --filter golden_dcg1_bytes_are_exact \
    -i dualclear_core "$WORKSPACE"

printf '\n[2/5] EVM adapter positive conformance vectors\n'
"$FE_BIN" test \
    --backend sonatina --profile test -O1 \
    --jobs 1 --grouped \
    --filter evm_adapter_matches \
    -i dualclear_evm "$WORKSPACE"

printf '\n[3/5] Exact DCG1 bytes on native\n'
"$FE_BIN" test \
    --backend native --profile test -O1 \
    --jobs 1 --grouped --native-timeout-secs 120 \
    --filter golden_dcg1_bytes_are_exact \
    -i dualclear_core "$WORKSPACE"

printf '\n[4/5] Native adapter positive conformance vectors\n'
"$FE_BIN" test \
    --backend native --profile test -O1 \
    --jobs 1 --grouped --native-timeout-secs 120 \
    --filter native_adapter_matches \
    -i dualclear_native "$WORKSPACE"

printf '\n[5/5] Native CLI input to materialized DCG1\n'
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
actual_hex="$OUT_DIR/native/golden.actual.hex"
"${native_executables[0]}" \
    7 \
    3 1000000 7 \
    1 2000000 5 \
    2 2000000 5 \
    9 3000000 2 >"$actual_hex"
if ! cmp -s -- "$VECTOR_HEX" "$actual_hex"; then
    printf 'Native DCG1 output mismatch.\n' >&2
    diff -u -- "$VECTOR_HEX" "$actual_hex" >&2 || true
    exit 1
fi

printf '\nConformance summary:\n'
printf '  DCG1 exact bytes (Sonatina/native): PASS\n'
printf '  EVM adapter positive vectors:       PASS\n'
printf '  Native adapter positive vectors:    PASS\n'
printf '  Native CLI output vs hex fixture:   PASS (284 bytes)\n'
printf '\nHuman-readable golden reference:\n\n'
cat "$VECTOR"
printf '\n\nDualClear cross-backend golden demo: PASS\n'
