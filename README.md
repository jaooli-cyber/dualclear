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
                    shared Outcome + DCG1 checksum
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
- `curl`, `sha256sum`, `make`, and a C toolchain required by Fe native builds

Install the pinned compiler and verify its SHA-256:

```sh
make setup
```

Run the complete cross-backend verification:

```sh
make verify
```

Run the focused golden-vector demonstration:

```sh
make demo
```

The demo uses one order book for both targets and checks:

- clearing price: `2.000000` (raw `2000000`);
- filled supply: `7`;
- ranked fills: `[(9,2), (1,3), (2,2), (3,0)]`;
- interoperability fingerprint: `0xf85927c169cff4f1`;
- successful execution through the EVM adapter and native executable.

`demo/golden.json` is a human-readable mirror of the tested vector; the
authoritative assertions are the Fe tests executed by the demo.

Build and test commands remain available separately through `make help`.

## Repository layout

```text
gate/
  core/       target-neutral clearing and cross-backend tests
  evm/        typed EVM ABI adapter and adapter tests
  native/     native wrapper and executable canary
demo/         portable golden vector
scripts/      pinned toolchain, verification, and demo entrypoints
docs/         architecture, security, limitations, provenance, and AI disclosure
```

## Current verified status

The current repository was built with Fe 26.5.0:

- EVM/Sonatina release build: pass;
- shared core under Sonatina: 16/16;
- EVM adapter under Sonatina: 3/3;
- native release build and executable: pass;
- the same shared core under native: 16/16;
- native wrapper under native: 2/2;
- invalid inputs return typed `InputError` values through `clear_checked`
  and the native `clear_native` API.

The project is a working prototype, not a production exchange or audited
settlement system.

## Security and trust model

The venue or batch builder must assign unique IDs under a documented,
deterministic policy. Allowing bidders to choose IDs would make the
equal-remainder tie-break strategically selectable.

The DCG1 FNV-1a64 value is only an interoperability checksum. It is **not**
collision-resistant and must never be used as a cryptographic commitment,
signature, or proof.

Read [Security](docs/SECURITY.md) and
[Limitations](docs/LIMITATIONS.md) before integrating the kernel.

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
