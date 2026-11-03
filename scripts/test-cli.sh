#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
readonly ROOT_DIR
readonly WORKSPACE="$ROOT_DIR/gate"
readonly FE_BIN="${FE_BIN:-$ROOT_DIR/.contest-tools/fe_linux_amd64}"
readonly OUT_DIR="$ROOT_DIR/out/cli-test"
readonly CAPTURE_DIR="$OUT_DIR/captures"

if [[ ! -x "$FE_BIN" ]]; then
    printf 'Fe binary not found at %s; run make setup first.\n' "$FE_BIN" >&2
    exit 1
fi

mkdir -p -- "$OUT_DIR"
find "$OUT_DIR" -mindepth 1 -depth -delete
mkdir -p -- "$CAPTURE_DIR"

if [[ -n "${NATIVE_BIN:-}" ]]; then
    CLI_BIN="$NATIVE_BIN"
else
    mkdir -p -- "$OUT_DIR/native"
    "$FE_BIN" build \
        --backend native --profile release -O1 \
        --emit executable \
        --out-dir "$OUT_DIR/native" \
        -i dualclear_native "$WORKSPACE"
    CLI_BIN="$OUT_DIR/native/dualclear_native"
fi
readonly CLI_BIN

if [[ ! -x "$CLI_BIN" ]]; then
    printf 'Native CLI not executable at %s.\n' "$CLI_BIN" >&2
    exit 1
fi

test_count=0

expect_success_fixture() {
    local label="$1"
    local fixture="$2"
    shift 2
    local stdout_file="$CAPTURE_DIR/${label}.stdout"
    local stderr_file="$CAPTURE_DIR/${label}.stderr"

    if ! "$CLI_BIN" "$@" >"$stdout_file" 2>"$stderr_file"; then
        printf '%s: expected exit 0.\n' "$label" >&2
        exit 1
    fi
    if [[ -s "$stderr_file" ]]; then
        printf '%s: expected empty stderr.\n' "$label" >&2
        exit 1
    fi
    if ! cmp -s -- "$fixture" "$stdout_file"; then
        printf '%s: DCG1 output mismatch.\n' "$label" >&2
        diff -u -- "$fixture" "$stdout_file" >&2 || true
        exit 1
    fi
    test_count=$((test_count + 1))
}

expect_error() {
    local expected_rc="$1"
    local label="$2"
    shift 2
    local stdout_file="$CAPTURE_DIR/${label}.stdout"
    local stderr_file="$CAPTURE_DIR/${label}.stderr"
    local rc

    set +e
    "$CLI_BIN" "$@" >"$stdout_file" 2>"$stderr_file"
    rc=$?
    set -e

    if [[ "$rc" -ne "$expected_rc" ]]; then
        printf '%s: expected exit %s, got %s.\n' \
            "$label" "$expected_rc" "$rc" >&2
        exit 1
    fi
    if [[ -s "$stdout_file" || -s "$stderr_file" ]]; then
        printf '%s: error paths must be silent.\n' "$label" >&2
        exit 1
    fi
    test_count=$((test_count + 1))
}

expect_success_fixture \
    no_args "$ROOT_DIR/demo/golden.dcg1.hex"

expect_success_fixture \
    golden_permuted "$ROOT_DIR/demo/golden.dcg1.hex" \
    7 \
    3 1000000 7 \
    1 2000000 5 \
    2 2000000 5 \
    9 3000000 2

expect_success_fixture \
    leading_zeroes "$ROOT_DIR/demo/golden.dcg1.hex" \
    0007 \
    0003 001000000 0007 \
    0001 002000000 0005 \
    0002 002000000 0005 \
    0009 003000000 0002
expect_success_fixture \
    maximum_values "$ROOT_DIR/demo/max-values.dcg1.hex" \
    18446744073709551615 \
    1 \
    115792089237316195423570985008687907853269984665640564039457584007913129639935 \
    18446744073709551615

sixteen_bids=(16)
for ((id = 16; id >= 1; id--)); do
    sixteen_bids+=("$id" 1000000 1)
done
expect_success_fixture \
    sixteen_bids "$ROOT_DIR/demo/max-bids.dcg1.hex" "${sixteen_bids[@]}"

seventeen_bids=(17)
for ((id = 1; id <= 17; id++)); do
    seventeen_bids+=("$id" 1000000 1)
done
expect_error 64 seventeen_bids "${seventeen_bids[@]}"

expect_error 64 supply_without_bids 7
expect_error 64 incomplete_bid 7 1 1000000
expect_error 64 surplus_field 1 1 1000000 1 extra

expect_error 65 empty_decimal "" 1 1000000 1
expect_error 65 plus_sign +1 1 1000000 1
expect_error 65 minus_sign -1 1 1000000 1
expect_error 65 hex_prefix 0x10 1 1000000 1
expect_error 65 alphabetic nope 1 1000000 1
expect_error 65 non_ascii $'\xC3\xA9' 1 1000000 1
expect_error 65 u64_overflow 18446744073709551616 1 1000000 1
expect_error 65 u256_overflow \
    1 1 \
    115792089237316195423570985008687907853269984665640564039457584007913129639936 \
    1
printf -v u64_too_long '%021d' 0
printf -v u256_too_long '%079d' 0
expect_error 65 u64_digit_limit "$u64_too_long" 1 1000000 1
expect_error 65 u256_digit_limit 1 1 "$u256_too_long" 1
expect_error 65 id_overflow \
    1 18446744073709551616 1000000 1
expect_error 65 quantity_overflow \
    1 1 1000000 18446744073709551616
expect_error 65 embedded_space "1 " 1 1000000 1


expect_error 66 zero_supply 0 1 1000000 1
expect_error 66 zero_quantity 1 1 1000000 0
expect_error 66 duplicate_id 1 7 2000000 1 7 1000000 1
expect_error 66 demand_below_supply 2 1 1000000 1

printf 'DualClear native CLI: PASS (%s cases)\n' "$test_count"
