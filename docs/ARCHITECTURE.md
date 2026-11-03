# Architecture

## Objective

DualClear provides a deterministic clearing kernel that can run in an EVM
contract and a native process without maintaining two implementations of the
allocation algorithm.

The shared source is `gate/core/src/lib.fe`. The adapters in
`gate/evm` and `gate/native` translate target-specific inputs and outputs
and reuse the same validation and clearing implementation. The enforcing EVM
path calls `dualclear_core::clear`; the native path calls the typed
`dualclear_core::clear_checked` entrypoint.

## Data model

A bid contains:

- a unique venue-assigned `u64` ID;
- a `UFixed<6>` price;
- a positive `u64` quantity.

An outcome contains the raw clearing price, total filled supply, ranked fills,
and an interoperability fingerprint. The current prototype accepts 1 to 16
bids and positive supply no greater than aggregate demand.

## Clearing algorithm

1. Validate cardinality, supply, quantities, unique IDs, and aggregate demand.
2. Sort bids by price descending, then ID ascending.
3. Find the first price at which cumulative demand reaches supply.
4. Fill every bid above that clearing price completely.
5. Prorate the remaining supply across the marginal price group.
6. Allocate integral base quantities with floor division.
7. Award leftover units by remainder descending, then ID ascending.
8. Assert that no bid is overfilled and total fills equal supply.
9. Serialize the ranked result in DCG1 form and compute its FNV-1a64 checksum.

The algorithm uses integer and fixed-point arithmetic only. It has no
wall-clock, randomness, storage-order, or floating-point dependency.

## Invariants

For every accepted input:

- `sum(fills) == supply`;
- `fill[i] <= bid[i].quantity`;
- bids above the clearing price fill completely;
- bids below the clearing price receive zero;
- marginal allocations follow largest remainder;
- exact remainder ties go to lower IDs;
- input permutations with the same uniquely identified bids produce the same
  ranked outcome.

## DCG1 canonical representation

All integers are unsigned, fixed-width, and big-endian:

1. ASCII `DCG1` (4 bytes);
2. supply (`u64`, 8 bytes);
3. raw clearing price (`u256`, 32 bytes);
4. filled quantity (`u64`, 8 bytes);
5. ranked bid count (`u64`, 8 bytes);
6. for each ranked bid: ID (`u64`), raw price (`u256`), requested quantity
   (`u64`), and filled quantity (`u64`).

The four-bid golden vector occupies 284 bytes and has checksum
`0xf85927c169cff4f1`. DCG1 is an interoperability format; its current checksum
is not a security commitment.

## Adapters

### EVM

The EVM adapter exposes
`clear(uint64,(uint64,uint256,uint64)[])` and returns the raw clearing price,
filled quantity, checksum, and ranked fills. Its `DynArray` cardinality check
occurs after ABI decoding; it is a product bound, not a predecode calldata
firewall.

### Native

The native ingot exposes
`clear_native(MemVec<Bid>, u64) -> Result<InputError, Outcome>` and builds a
standalone executable whose golden canary returns zero on success. The shared
`validate_input` and `clear_checked` functions report six explicit error
variants, so native callers can handle invalid input without a process-level
trap. The assertion-based `clear` function remains the thin EVM adapter's
enforcing entrypoint.
