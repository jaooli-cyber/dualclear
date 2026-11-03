# Native CLI

The native executable is a bounded command-line adapter over the same
`dualclear_core::clear_checked` function used by the native library. It does
not reimplement clearing.

## Usage

```text
dualclear_native
dualclear_native SUPPLY ID PRICE_RAW QUANTITY [ID PRICE_RAW QUANTITY]...
```

All values are unsigned decimal integers. The explicit form accepts 1 to 16
bids. Each price is the raw six-decimal fixed-point value, so `2000000`
represents `2.000000`.

With no arguments, the executable retains the contest golden mode. With
arguments, it clears the supplied batch and writes exactly one line:

```text
DCG1:<lowercase canonical hex>
```

Example:

```sh
./dualclear_native 7 \
  3 1000000 7 \
  1 2000000 5 \
  2 2000000 5 \
  9 3000000 2
```

The order above intentionally differs from the EVM golden input. Both produce
the same ranked outcome and exact DCG1 bytes.

## Exit contract

| Code | Meaning | Output |
|---:|---|---|
| 0 | Valid batch; DCG1 emitted | One canonical line |
| 64 | Invalid argument shape or bid count | Empty |
| 65 | Invalid decimal or numeric overflow | Empty |
| 66 | `InputError` returned by the kernel | Empty |

Error paths do not echo untrusted input. Code 66 deliberately preserves the
typed `Result` boundary without duplicating the kernel's validation policy in
the CLI.

## Parsing and bounds

- exactly 1 to 16 bids are accepted;
- `u64` fields accept at most 20 decimal digits;
- `u256` price fields accept at most 78 decimal digits;
- overflow is checked before multiplication;
- signs, whitespace inside an argument, prefixes, letters, empty strings, and
  non-ASCII bytes are rejected;
- leading zeroes are accepted and do not change the canonical numeric outcome;
- cardinality is checked before allocating the bid vector;
- semantic checks always pass through `clear_checked`.

The only unsafe operation is construction of Fe's `Args` view from the
`argc/argv` pair supplied by the native runtime.

## Trust boundary

Bid IDs remain venue-assigned. The CLI does not authenticate a venue or enforce
its ID-allocation policy. Allowing bidders to choose IDs would make exact
remainder ties strategically selectable.

The operating system finds the NUL terminator of each argument before the
20/78-digit parser limit can be applied. This is bounded by the host's argument
limit, but the CLI is not presented as an unbounded or remotely exposed
service.

Fe 26.5's buffered native output API does not expose a fallible final flush.
A late host write failure can therefore occur after `main` has returned zero.
Consumers must check their own pipe or file operation and validate the complete
DCG1 line. DualClear does not claim a reliable process exit code for this
runtime boundary.

## Verification

```sh
make test-cli
```

The suite covers golden/no-argument compatibility, a permuted explicit golden,
leading zeroes, maximum `u64`/`u256`, 16 and 17 bids, malformed shapes,
non-decimal input, explicit 20/78-digit caps, overflow in every numeric field,
and invalid auction semantics. It requires empty stdout and stderr for every
error case. `make verify` runs the same suite in CI.
