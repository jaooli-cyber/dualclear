# Judge handoff — FE-013

DualClear is one deterministic auction-clearing kernel written once in Fe and
compiled for Sonatina/EVM and native execution. Its purpose is to remove a
common integration risk: an off-chain simulator and an on-chain executor
silently disagreeing because they use separate implementations.

The project is deliberately a focused kernel, two thin adapters, a native CLI,
and reproducible evidence. It is not a DEX or settlement system.

## Fast path: the judge demo

Prerequisites:

- Linux x86-64;
- `curl`, `sha256sum`, `cmp`, and `make`;
- a C toolchain for native builds; and
- outbound HTTPS for the initial compiler download.

For a cold checkout, run `make setup` first. Timing labels below assume the
pinned compiler is already cached and exclude network download time.

Then run:

```sh
make demo
```

The target installs and verifies the pinned Fe 26.5.0 binary when necessary,
then runs five stages:

1. the same three metamorphic relations from the shared core on Sonatina;
2. positive EVM adapter vectors;
3. those same three core relations on native;
4. positive native adapter vectors; and
5. native CLI input to the exact hex representation of a 284-byte DCG1 vector.

Success ends with:

```text
DualClear cross-backend golden demo: PASS
```

No chain, wallet, deployment, frontend, or external test framework is required.

## Deeper path after setup: 2–5 minute verification

Run these independently:

```sh
make abi-check
make verify
```

Or execute the complete submission gate in order:

```sh
make candidate
```

Expected success markers:

```text
DualClear EVM v1: PASS (ABI sha256=..., calldata=484 bytes, returndata=416 bytes)
DualClear verification: PASS
```

`make abi-check` rebuilds with the pinned compiler, rejects ABI and artifact
snapshot drift, executes literal raw calldata for selector `0x74ad3a54`, and
compares the complete returndata. `make verify` runs format and semantic
checks, release builds, 19 shared-core cases on each backend, 12 EVM adapter
cases, four native adapter cases, and 26 CLI cases.

## Claim-to-evidence map

| Claim | Primary evidence | Reproduce |
| --- | --- | --- |
| One Fe kernel produces the same canonical outcome on two targets | [Shared core](gate/core/src/lib.fe), [relations](docs/METAMORPHIC.md) | `make verify` |
| EVM v1 has a frozen ABI and exact wire golden | [ABI fixtures](abi/), [EVM interface](docs/EVM.md) | `make abi-check` |
| Native invalid input has a typed `Result` surface | [Native adapter](gate/native/src/lib.fe), [CLI](docs/CLI.md) | `make verify` |
| The native CLI materializes canonical DCG1 as hex | [Golden hex](demo/golden.dcg1.hex) | `make test-cli` |
| Artifact sizes and hashes are source-bound and reproducible | [Snapshot](demo/evm-metrics.env), [metrics](docs/METRICS.md) | `make metrics` |
| Security and algorithmic non-properties are explicit | [Security](docs/SECURITY.md), [limitations](docs/LIMITATIONS.md) | Review plus `make verify` |

## What is Fe-specific

- The target-neutral `dualclear_core` ingot is compiled from the same source
  under Sonatina and native; this is not a pair of ports.
- `UFixed<6>` makes the price scale part of the type, while bounded `MemVec`
  values, checked conversions, explicit ownership, and deterministic sorting
  express the allocation kernel.
- Native callers receive `Result<InputError, Outcome>`; the enforcing EVM
  boundary uses Fe's message/ABI generation, while raw tests exercise the
  explicit EVM simulator and call surface.
- Fe's integrated build and test tooling runs the shared corpus on both
  backends and emits the versioned EVM ABI and metadata.

## Important limits

1. A batch contains at most 16 bids.
2. The venue assigns unique IDs deterministically. If fairness is required per
   participant, it must also authenticate and aggregate or limit equivalent
   orders; the kernel is not split- or Sybil-resistant.
3. EVM dynamic calldata is decoded before the adapter's bid-count check.
4. FNV-1a64 is an interoperability checksum, never a cryptographic commitment.
5. Largest remainder is not individually supply-monotone across separate
   clears.
6. DualClear does not authenticate orders, custody assets, settle trades, claim
   measured gas, or publish an official deployment. Compiler metadata targets
   `evmVersion=osaka`; integrators must check destination-chain compatibility.

The exact counterexamples and mitigations are in
[Metamorphic conformance](docs/METAMORPHIC.md) and
[Security](docs/SECURITY.md).

## Repository and disclosures

- workspace manifest: [`gate/fe.toml`](gate/fe.toml);
- architecture: [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md);
- full limitations: [`docs/LIMITATIONS.md`](docs/LIMITATIONS.md);
- provenance and precontest boundary:
  [`docs/PROVENANCE.md`](docs/PROVENANCE.md);
- AI assistance: [`docs/AI-DISCLOSURE.md`](docs/AI-DISCLOSURE.md);
- license: [Apache-2.0](LICENSE).

The exact full commit SHA selected for judging is supplied separately in the
contest submission. Annotated tag `fe-013-submission-v1` and its release
evidence point to that same commit. Review and reproduce the immutable checkout
rather than a moving branch tip.
