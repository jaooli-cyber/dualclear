# FE-013 submission copy

This file contains the public, non-secret text prepared for the official Fe
Builders Challenge submission form. The registered contact email and private
submission code are intentionally excluded and must never be committed.

## Final project name

DualClear

## One-sentence pitch

DualClear compiles one deterministic Fe auction-clearing kernel for both EVM
and native execution, eliminating logic drift between off-chain simulation and
on-chain settlement while producing complete, byte-verifiable outcomes.

## Repository and candidate identity

- Repository: `https://github.com/jaooli-cyber/dualclear`
- Project ID: `FE-013`
- Navigation tag: `fe-013-submission-v1`
- Authoritative identity: the full 40-character commit SHA entered in the
  official submission form. The tag must point to that same commit.

## Exact Fe toolchain version

`fe 26.5.0 (3dab95f)`, release commit
`3dab95f8eebdccf9a2382bb59a33f7bbd03540ca`. Official Linux binary SHA-256:
`3732fbe8a6e9d2ea3925d02d0e3a1478bc1e01d742c2be75d3ea7300c46c45f0`.

## Fe-specific technical highlight

DualClear compiles the same target-neutral `dualclear_core` Fe ingot under
Sonatina/EVM and the native backend, using `UFixed<6>`, bounded `MemVec`
values, checked conversions, explicit ownership, and deterministic sorting.
Native callers receive `Result<InputError, Outcome>`, while the enforcing EVM
adapter exposes a frozen v1 ABI. Cross-backend conformance compares every
outcome field and all 284 canonical DCG1 bytes rather than relying on the
FNV-1a64 checksum, which is explicitly treated only as an interoperability
checksum. Venue-assigned deterministic IDs and largest-remainder allocation
with ID tie-breaking make accepted outcomes reproducible.

## Demo link or reproducible demo instructions

Clone the public repository, check out the full 40-character commit SHA
supplied in the submission, and run `make setup` followed by `make demo` on
Linux x86-64 with `curl`, `sha256sum`, `cmp`, `make`, and a C toolchain. The
demo executes the same three metamorphic relations on Sonatina and native,
runs positive EVM and native adapter vectors, builds the native executable,
and compares its complete 284-byte DCG1 output byte-for-byte with the committed
golden. Success ends with `DualClear cross-backend golden demo: PASS`. Run
`make abi-check` to verify the frozen EVM v1 ABI, exact 484-byte calldata,
416-byte returndata, artifact hashes, and EIP-170 bound; run `make verify` for
the complete cross-backend build, 19+19 shared-core tests, 12 EVM adapter
tests, 4 native adapter tests, and 26 CLI cases. `make candidate` runs all
three gates in submission order.

## Pre-existing work, reused code and AI assistance

Before the build window, work was limited to research, specification,
non-compilable pseudocode, test planning, threat modelling, and Red Team
analysis kept outside this repository. No precontest implementation or
pseudocode was copied into the entry. All Fe source, tests, scripts, fixtures,
documentation, and build evidence in this repository were created after
November 3, 2026 at 00:00 UTC. No third-party application code was copied;
DualClear depends only on the Fe core and standard libraries supplied by the
pinned compiler. AI assisted research, architecture, Fe API review,
implementation support, test design, failure diagnosis, documentation,
reproducibility work, and technical, algorithmic, security, and contest Red
Team review. AI output was not accepted as evidence by itself, and the human
entrant remains responsible for the submission.
