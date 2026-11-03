#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
readonly ROOT_DIR
readonly WORKSPACE="$ROOT_DIR/gate"
readonly FE_BIN="${FE_BIN:-$ROOT_DIR/.contest-tools/fe_linux_amd64}"
readonly OUT_DIR="$ROOT_DIR/out/verify"

if [[ ! -x "$FE_BIN" ]]; then
    printf 'Fe binary not found at %s; run make setup first.\n' "$FE_BIN" >&2
    exit 1
fi


mkdir -p -- "$OUT_DIR"
find "$OUT_DIR" -mindepth 1 -depth -delete
mkdir -p -- "$OUT_DIR/evm" "$OUT_DIR/native"

printf '\n[1/9] Format check\n'
"$FE_BIN" fmt --check "$WORKSPACE"

printf '\n[2/9] Semantic checks\n'
"$FE_BIN" check -i dualclear_core "$WORKSPACE"
"$FE_BIN" check -i dualclear_evm "$WORKSPACE"
"$FE_BIN" check -i dualclear_native "$WORKSPACE"

printf '\n[3/9] EVM/Sonatina release build\n'
"$FE_BIN" build \
    --backend sonatina --profile release -O1 \
    --emit bytecode,runtime-bytecode,abi,metadata \
    --out-dir "$OUT_DIR/evm" \
    -i dualclear_evm "$WORKSPACE"

printf '\n[4/9] Shared core tests on Sonatina\n'
"$FE_BIN" test \
    --backend sonatina --profile test -O1 \
    --jobs 1 --grouped \
    -i dualclear_core "$WORKSPACE"

printf '\n[5/9] EVM adapter tests on Sonatina\n'
"$FE_BIN" test \
    --backend sonatina --profile test -O1 \
    --jobs 1 --grouped \
    -i dualclear_evm "$WORKSPACE"

printf '\n[6/9] Native release build\n'
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

printf '\n[7/9] Native executable canary\n'
"${native_executables[0]}" >/dev/null

printf '\n[8/9] Shared core tests on native\n'
"$FE_BIN" test \
    --backend native --profile test -O1 \
    --jobs 1 --grouped --native-timeout-secs 120 \
    -i dualclear_core "$WORKSPACE"

printf '\n[9/9] Native adapter tests\n'
"$FE_BIN" test \
    --backend native --profile test -O1 \
    --jobs 1 --grouped --native-timeout-secs 120 \
    -i dualclear_native "$WORKSPACE"

printf '\nDualClear verification: PASS\n'
printf 'Artifacts: %s\n' "$OUT_DIR"
