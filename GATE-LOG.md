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
- Gate decision: **HOLD (RG-STOP)**.

## Current snapshot

- Documentation cutoff: 2026-11-03T04:15:38Z.
- Clean pre-log snapshot: HEAD
  `5711ef7f0bcfae0e6dd489e4695e14e7fbf1aa50`, tree
  `d71922167f96c2390fed925935ee8f4331e73c15`.
- The latest source-bearing commit is `5d27a5d`; the commits after it are
  documentation-only, so the current gate source/manifests are the same ones
  covered by the final light checks.
- `fe fmt --check gate`: RC 0.
- `fe check --ingot dualclear_core gate`: RC 0.
- `fe check --ingot dualclear_evm gate`: RC 0.
- `fe check --ingot dualclear_native gate`: RC 0.

## Commit and documentation ledger

- `706e690`: initial pure shared core, EVM/native adapters, DCG1 golden and
  gate evidence.
- `caaea26`: unequal-remainder precedence, exact-demand 16-bid boundary, and
  accurate EVM typed-ABI allocation caveat.
- `846b73d`: core rejection corpus and maximum-width integer case.
- `5d27a5d`: EVM handler tests for 0 and 17 bids through typed ABI.
- `2ba11c2`: added `GATE-RUNBOOK.md` for serial, provenance-preserving EVM
  and native execution.
- `ecf8b9e`: tightened the runbook's resource guard and RG-STOP rules.
- `5711ef7`: added `TEST-MATRIX.md`, including explicit cross-backend gaps
  and evidence requirements.
- `README.md` documents architecture, DCG1 byte widths/endianness,
  `UFixed<6>` scale, FNV's non-cryptographic role, and the handler-only scope
  of the EVM precheck.

## Authored test inventory

- 19 source tests total: 15 in `dualclear_core`, 3 in `dualclear_evm`, and
  1 in `dualclear_native`.
- The matrix classifies all 19 as
  **AUTHORED / STATIC-CHECKED / NOT EXECUTED**.
- The negative core corpus is shared and is intended to run unchanged under
  Sonatina and native; EVM has two additional handler/ABI boundary tests.
- No authored test is recorded as passed or failed without runner evidence.

## Resource guard status

- Repeated observations from gate opening through approximately
  2026-11-03T04:14Z continued to show two external `python3` processes and
  one external `fe` process, each using approximately one CPU.
- No process arguments, command lines, paths, working directories,
  executables, environments, open files, or routing were inspected.
- No external process was signalled, reprioritized, stopped, or otherwise
  modified.
- The sustained external load and external Fe activity satisfy RG-STOP.
  This is a resource/infrastructure stop, not a DualClear product result.

## Pending execution

- EVM build and Sonatina core/adapter tests: pending.
- Native build, executable run, and native core/wrapper tests: pending.
- Heavy commands remain prohibited while RG-STOP holds.
- 2026-11-03T07:15:30Z: the fixed gate window was closed while the same two
  external `python3` processes and one external `fe` process remained
  CPU-heavy. Only permitted process metadata was observed; no external work
  was inspected or modified.
- No backend build or runtime test was permitted or completed in-window.
- Gate state: **KILL — empirical gate not completed under RG-STOP**.
- This is timebox enforcement, not a demonstrated product or algorithm failure.
- PLAN B is unavailable because no complete empirical EVM path exists.
- DualClear is frozen and abandoned after this decision.

## Post-window technical verification

- 2026-11-03T09:04Z: the user explicitly required complete empirical
  verification of all three isolated candidates and authorized low-priority
  work on the shared host whenever aggregate capacity is sufficient.
- The original fixed-window result remains part of the audit trail.
- DualClear is reopened only for a late technical viability assessment;
  evidence obtained now is labelled post-window.
- The two long-running external `python3` processes ended before this run.
- Runner limits remain one serial Fe command, CPUs 6-7, one worker, nice
  level 15, and idle I/O priority.
