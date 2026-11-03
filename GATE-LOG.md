# DualClear viability gate

- Gate window: 2026-11-03 03:15:00-07:15:00 UTC.
- Server guard opened at 2026-11-03T03:15:03Z; no repository access occurred before opening.
- Initial repository snapshot at 2026-11-03T03:15:11Z: clean `main`, starter Counter ingot only.
- Toolchain: Fe 26.5.0 (3dab95f), project-local official Linux amd64 release.
- Resource guard at opening: two unrelated `python3` processes and one unrelated `fe` process were each consuming approximately one CPU. Per gate coordination, heavy build and test execution is reserved for the root runner after contention clears.
- Architecture authored after opening: isolated workspace with a target-neutral core and separate EVM/native adapters.

## Evidence ledger

- Source authoring completed at 2026-11-03T03:31:14Z: one pure core,
  Solidity-compatible EVM adapter, native wrapper/entry point, and shared golden.
- Two independent post-H0 byte oracles produced the same canonical length (284)
  and FNV-1a64 value (`0xf85927c169cff4f1`). The local oracle was an ephemeral
  one-shot calculation; no script or fixture was created.
- Primary Fe 26.5.0 source references were read at commit `3dab95f`:
  `crates/fe/tests/fixtures/fe_test/tuple_return_abi_params.fe`,
  `crates/fe/tests/fixtures/fe_test/abi_struct.fe`, and
  `crates/fe/tests/fixtures/fe_test/msg_array_arg.fe`.
- Red Team hardening: EVM validates `1..=MAX_BIDS` before allocation/copy;
  core covers exact demand, a single bid, all-same-price allocation, input
  permutation, and explicit remainder/ID ties. README fixes the DCG1 schema and
  states that FNV-1a64 is non-cryptographic.
- `fe fmt --check gate`: RC 0 at 2026-11-03T03:31:14Z.
- `fe check --ingot dualclear_core gate`: RC 0.
- `fe check --ingot dualclear_evm gate`: RC 0.
- `fe check --ingot dualclear_native gate`: RC 0.
- No build or test command was run by this authoring agent.
- EVM build/test: pending root resource guard.
- Native build/test: pending root resource guard.
- Gate decision: pending.
