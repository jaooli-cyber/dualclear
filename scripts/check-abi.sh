#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
readonly ROOT_DIR
readonly WORKSPACE="$ROOT_DIR/gate"
readonly FE_BIN="${FE_BIN:-$ROOT_DIR/.contest-tools/fe_linux_amd64}"
readonly OUT_DIR="$ROOT_DIR/out/abi-check"
readonly TRACE_FILE="$OUT_DIR/raw-v1.trace.log"
readonly ABI_FIXTURE="$ROOT_DIR/abi/DualClearGate.v1.json"
readonly GENERATED_ABI="$ROOT_DIR/out/metrics/DualClearGate.abi.json"
readonly CALLDATA_FIXTURE="$ROOT_DIR/abi/DualClearGate.v1.calldata.hex"
readonly RETURNDATA_FIXTURE="$ROOT_DIR/abi/DualClearGate.v1.returndata.hex"
readonly EXPECTED_FE_SHA256="3732fbe8a6e9d2ea3925d02d0e3a1478bc1e01d742c2be75d3ea7300c46c45f0"
readonly EXPECTED_VERSION="fe 26.5.0 (3dab95f)"

if [[ ! -x "$FE_BIN" ]]; then
    printf 'Fe binary not found at %s; run make setup first.\n' "$FE_BIN" >&2
    exit 1
fi

fe_sha256="$(sha256sum "$FE_BIN" | cut -d ' ' -f 1)"
version_output="$("$FE_BIN" --version)"
if [[ "$fe_sha256" != "$EXPECTED_FE_SHA256" || "$version_output" != "$EXPECTED_VERSION" ]]; then
    printf 'The Fe compiler does not match the pinned v26.5.0 binary.\n' >&2
    exit 1
fi

for fixture in "$ABI_FIXTURE" "$CALLDATA_FIXTURE" "$RETURNDATA_FIXTURE"; do
    if [[ ! -f "$fixture" || -L "$fixture" || ! -s "$fixture" ]]; then
        printf 'Missing, empty, or symlinked v1 fixture: %s\n' "$fixture" >&2
        exit 1
    fi
done

if [[ ! -f "$GENERATED_ABI" || ! -s "$GENERATED_ABI" ]]; then
    printf 'Generated ABI missing; run make metrics first.\n' >&2
    exit 1
fi
if ! cmp -s -- "$ABI_FIXTURE" "$GENERATED_ABI"; then
    printf 'Generated ABI differs from the frozen v1 fixture.\n' >&2
    diff -u -- "$ABI_FIXTURE" "$GENERATED_ABI" >&2 || true
    exit 1
fi

read -r expected_calldata <"$CALLDATA_FIXTURE"
read -r expected_returndata <"$RETURNDATA_FIXTURE"
if [[ "$(wc -l <"$CALLDATA_FIXTURE")" -ne 1 ||
      "$(wc -l <"$RETURNDATA_FIXTURE")" -ne 1 ||
      ! "$expected_calldata" =~ ^[0-9a-f]+$ ||
      ! "$expected_returndata" =~ ^[0-9a-f]+$ ||
      $(("${#expected_calldata}" % 2)) -ne 0 ||
      $(("${#expected_returndata}" % 2)) -ne 0 ]]; then
    printf 'Raw v1 fixtures must be one line of even-length lowercase hex.\n' >&2
    exit 1
fi

if [[ -L "$ROOT_DIR/out" || -L "$OUT_DIR" ]]; then
    printf 'Refusing symlinked ABI-check output path: %s\n' "$OUT_DIR" >&2
    exit 1
fi
mkdir -p -- "$OUT_DIR"
find "$OUT_DIR" -mindepth 1 -depth -delete

"$FE_BIN" test \
    --backend sonatina --profile test -O1 \
    --jobs 1 --grouped --call-trace \
    --filter evm_raw_v1_golden_matches_exact_returndata \
    -i dualclear_evm "$WORKSPACE" >"$TRACE_FILE" 2>&1

mapfile -t raw_calls < <(
    grep -E '^CALL [$]1 data=[0-9a-f]+ -> ok ret=[0-9a-f]+$' "$TRACE_FILE" || true
)
if [[ "${#raw_calls[@]}" -ne 1 ]]; then
    printf 'Expected exactly one successful raw call in %s.\n' "$TRACE_FILE" >&2
    exit 1
fi

payload="${raw_calls[0]#* data=}"
actual_calldata="${payload%% -> ok ret=*}"
actual_returndata="${payload#* -> ok ret=}"

printf '%s\n' "$actual_calldata" >"$OUT_DIR/actual.calldata.hex"
printf '%s\n' "$actual_returndata" >"$OUT_DIR/actual.returndata.hex"

if ! cmp -s -- "$CALLDATA_FIXTURE" "$OUT_DIR/actual.calldata.hex"; then
    printf 'Raw v1 calldata drift.\n' >&2
    diff -u -- "$CALLDATA_FIXTURE" "$OUT_DIR/actual.calldata.hex" >&2 || true
    exit 1
fi
if ! cmp -s -- "$RETURNDATA_FIXTURE" "$OUT_DIR/actual.returndata.hex"; then
    printf 'Raw v1 returndata drift.\n' >&2
    diff -u -- "$RETURNDATA_FIXTURE" "$OUT_DIR/actual.returndata.hex" >&2 || true
    exit 1
fi

abi_sha256="$(sha256sum "$ABI_FIXTURE" | cut -d ' ' -f 1)"
printf 'DualClear EVM v1: PASS (ABI sha256=%s, calldata=%s bytes, returndata=%s bytes)\n' \
    "$abi_sha256" \
    "$(("${#expected_calldata}" / 2))" \
    "$(("${#expected_returndata}" / 2))"
