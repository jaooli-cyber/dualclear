# DualClear

Fe Builders Challenge 2026 contest repository. Work in this repository began after 2026-11-03 00:00:00 UTC. Precontest research and AI assistance will be disclosed; no precontest implementation or pseudocode is copied here.

## Viability-gate architecture

The gate is a Fe workspace with one target-neutral implementation:

- `gate/core`: deterministic clearing, canonical serialization, and fingerprinting.
- `gate/evm`: Solidity-compatible ABI input/output adapter with a pre-allocation bound.
- `gate/native`: native entry point and a reusable `MemVec<Bid>` adapter.

The typed EVM ABI has already materialized the dynamic bid array before the
handler runs. Its precheck therefore prevents only the adapter's second
`MemVec` allocation and copy; it is not a decode-time calldata bound.

Both adapters call the same `dualclear_core::clear`; neither reimplements the
allocation algorithm. Inputs contain 1 to 16 positive-quantity bids with unique
caller-assigned IDs, positive supply, and aggregate demand at least equal to
supply. Ranking is price descending then ID ascending. The marginal price group
is prorated with the largest-remainder method; equal remainders go to the lower
ID.

Prices use `UFixed<6>`. A raw value of `2_000_000` means the logical price
`2.000000`.

## DCG1 canonical bytes

The fingerprint payload is the following concatenation. All integers are
unsigned and big-endian; widths are fixed.

1. ASCII domain tag `DCG1` (4 bytes).
2. Supply, `u64` (8 bytes).
3. Clearing price raw value, `u256` (32 bytes, `UFixed<6>` scale).
4. Filled quantity, `u64` (8 bytes).
5. Ranked bid count, `u64` (8 bytes).
6. For every ranked bid: ID `u64`, raw price `u256`, requested quantity
   `u64`, and filled quantity `u64` (56 bytes per bid).

The agreed four-bid golden is 284 bytes and has FNV-1a64
`0xf85927c169cff4f1`. This is a deterministic cross-backend fingerprint only.
FNV-1a64 is not collision-resistant and must not be treated as a security
commitment, signature, or proof.

IDs are part of the allocation policy: lower IDs win an exact equal-remainder
tie. A deployment must have the trusted venue or batch builder assign unique
IDs under a documented deterministic policy. Letting bidders choose IDs would
make that tie-break strategically selectable. Native integrations should call
`valid_input` before `clear`; invalid direct native calls currently trap
rather than return a typed result.
