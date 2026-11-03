# DualClear

[![CI](https://github.com/jaooli-cyber/dualclear/actions/workflows/ci.yml/badge.svg)](https://github.com/jaooli-cyber/dualclear/actions/workflows/ci.yml)

**One Fe clearing kernel. Two execution targets. Identical auction outcomes.**

DualClear is a deterministic auction-clearing kernel written once in Fe and
compiled for both EVM and native targets. It is designed to reduce divergence
between off-chain simulation and on-chain settlement: the same order book,
supply, algorithm, ordering rules, and arithmetic produce the same clearing
price and fills on both backends.

DualClear is registered as project **FE-013** in the
[Fe Builders Challenge 2026](https://fe-lang.org/contest/).

Judges: start with the [2–5 minute handoff](JUDGING.md).

## Why this matters

Auction systems often reimplement clearing logic in an off-chain service and a
smart contract. Even small differences in sorting, fixed-point arithmetic, or
rounding can produce conflicting allocations. DualClear keeps the
consensus-critical algorithm in one target-neutral Fe ingot and exposes only
thin target adapters.

## Why Fe

Fe is central to the design rather than an interchangeable implementation
language:

- one shared `dualclear_core` ingot is compiled and tested under Sonatina/EVM
  and the native backend;
- `UFixed<6>` makes the price scale explicit;
- `MemVec`, checked downcasts, explicit ownership, and deterministic sorting
  support bounded allocation logic;
- separate EVM and native adapters reuse the same core without reimplementing
  clearing.

## Architecture

```text
                    +----------------------+
order book + supply |  dualclear_core      |
------------------->|  validate / rank /   |
                    |  clear / canonicalize|
                    +----------+-----------+
                               |
                  shared Outcome + DCG1 bytes/checksum
                               |
                 +-------------+-------------+
                 |                           |
        +--------v--------+         +--------v--------+
        | EVM adapter     |         | native adapter  |
        | typed ABI       |         | wrapper + binary|
        +-----------------+         +-----------------+
```

The kernel validates at most 16 bids, ranks price descending and ID ascending,
finds the marginal price group, and allocates that group with largest
remainder. Equal remainders are resolved by lower venue-assigned ID.

See [Architecture](docs/ARCHITECTURE.md) for the complete algorithm and
invariants.

## Quickstart

### Prerequisites

- Linux x86-64
- Fe **26.5.0** (`3dab95f`)
- `curl`, `sha256sum`, `cmp`, `make`, and a C toolchain for native builds

Install the pinned compiler and verify its SHA-256:

```sh
make setup
```

Run the complete cross-backend verification:

```sh
make verify
```

### 60-second judge demo

```sh
make demo
```

The command runs five verification stages:

- three deterministic metamorphic relations from the same Fe source on
  Sonatina and native;
- golden, tie-break, maximum-value, and 16-bid vectors through the EVM
  adapter;
- golden, tie-break, and maximum-value vectors through the native adapter;
- a standalone native executable that emits the 568 canonical hex digits;
- byte-for-byte comparison of that output with `demo/golden.dcg1.hex`.

The golden outcome is price `2.000000`, filled supply `7`, ranked fills
`[(9,2), (1,3), (2,2), (3,0)]`, and fingerprint
`0xf85927c169cff4f1`.

`demo/golden.json` is the human-readable mirror. The complete Fe suite still
checks all 284 golden DCG1 bytes on both core backends, while the demo's native
executable consumes `demo/golden.dcg1.hex` directly. See
[Metamorphic conformance](docs/METAMORPHIC.md).

Build and test commands remain available separately through `make help`.

### Versioned EVM interface

```sh
make abi-check
```

The v1 integration pack contains the compiler-emitted ABI, a decoded golden,
and complete raw calldata/returndata fixtures. The check rebuilds the ABI with
the pinned compiler, executes the literal `0x74ad3a54` selector, and rejects
any byte-level drift. See [EVM integration](docs/EVM.md).

Success ends with `DualClear EVM v1: PASS`, including the ABI hash and exact
wire lengths.

### Native CLI

```sh
make test-cli
```

The executable accepts
`SUPPLY ID PRICE_RAW QUANTITY [ID PRICE_RAW QUANTITY]...` for 1 to 16 bids.
It emits canonical DCG1 on success and remains silent with a stable nonzero
exit code on malformed or invalid input. See [Native CLI](docs/CLI.md).

### Reproducible EVM metrics

```sh
make metrics
```

With the pinned release/O1 build, creation bytecode is 7,951 bytes and runtime
bytecode is 7,931 bytes, leaving 16,645 bytes below the EIP-170 runtime limit.
The command prints artifact hashes and fails on snapshot drift or if the runtime
limit is exceeded. These are size measurements, not gas claims. See
[EVM metrics](docs/METRICS.md).

`make abi-check` includes this metrics gate and the raw EVM v1 golden.

## Repository layout

```text
gate/
  core/       target-neutral clearing and cross-backend tests
  evm/        typed EVM ABI adapter and adapter tests
  native/     native Result API and bounded CLI
abi/          frozen EVM v1 ABI and decoded/raw golden fixtures
demo/         portable DCG1 vectors and the EVM metrics snapshot
scripts/      pinned toolchain, verification, CLI, demo, metrics, and ABI checks
docs/         architecture, EVM, CLI, metrics, metamorphic relations, security,
              limitations, provenance, and AI disclosure
```

## Current verified status

The current repository was built with Fe 26.5.0:

- EVM/Sonatina release build: pass;
- shared core under Sonatina: 19/19;
- EVM adapter under Sonatina: 12/12;
- native release build and executable: pass;
- the same shared core under native: 19/19;
- native wrapper under native: 4/4;
- invalid inputs return typed `InputError` values through `clear_checked`
  and the native `clear_native` API;
- native CLI parser and boundary matrix: 26/26;
- emitted EVM target: Osaka; destination-chain compatibility is not assumed;
- three metamorphic relations execute from the same source on both core
  backends;
- EVM runtime bytecode: 7,931 bytes with 16,645 bytes EIP-170 headroom;
- frozen ABI v1 and exact 484-byte calldata / 416-byte returndata golden:
  pass.

The project is a working prototype, not a production exchange or audited
settlement system.

## Security and trust model

The venue or batch builder must assign unique IDs under a documented,
deterministic policy. Allowing bidders to choose IDs would make the
equal-remainder tie-break strategically selectable.

Deterministic venue IDs do not prevent order splitting. If fairness is required
per participant, the venue must authenticate and aggregate or limit equivalent
orders by economic identity and price.

The DCG1 FNV-1a64 value is only an interoperability checksum. It is **not**
collision-resistant and must never be used as a cryptographic commitment,
signature, or proof.

Read [EVM integration](docs/EVM.md),
[Metamorphic conformance](docs/METAMORPHIC.md), [Native CLI](docs/CLI.md),
[EVM metrics](docs/METRICS.md), [Security](docs/SECURITY.md), and
[Limitations](docs/LIMITATIONS.md).

## Contest disclosure

Substantial implementation in this repository began after the contest build
window opened on **2026-11-03 00:00 UTC**. Precontest research and planning
existed, but no precontest implementation or pseudocode was copied into this
repository. AI assistance was used and is disclosed in
[AI-DISCLOSURE.md](docs/AI-DISCLOSURE.md). All accepted behavior is backed by
human-reviewed source, executed tests, and retained evidence.

See [Provenance](docs/PROVENANCE.md) and
[Audit history](docs/AUDIT-HISTORY.md).

## License

Apache-2.0. See [LICENSE](LICENSE).
