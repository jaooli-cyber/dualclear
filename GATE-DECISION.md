# DualClear gate decision

## Verdict

`KILL` — empirical gate not completed within the fixed timebox under `RG-STOP`.

The gate closed at 2026-11-03T07:15:00Z without any permitted backend build or runtime test. Under the predeclared no-extension rule, DualClear must be abandoned and cannot advance as a contest candidate from this gate.

This is not a demonstrated technical failure of the shared algorithm, EVM adapter, or native adapter. It is enforcement of the empirical viability rule after sustained external resource contention.

## In-window evidence obtained

- Fixed gate window: 2026-11-03T03:15:00Z–07:15:00Z.
- Baseline immediately before closure: commit `0ba94ee3f8f22c51fcb5c7d74308e26cf5d39fbf`, tree `7095d733a9af3d492b9bdf7c19bf4bfaa2830f85`, clean worktree.
- Fe 26.5.0, compiler commit `3dab95f`, project-local binary.
- `fe fmt --check gate`: RC 0.
- `fe check` for `dualclear_core`, `dualclear_evm`, and `dualclear_native`: RC 0.
- One shared nontrivial clearing core, separate thin EVM/native adapters, and no duplicated allocation algorithm.
- Nineteen authored tests: 15 core, 3 EVM, and 1 native.
- The same complete core suite was planned for Sonatina and native.
- Two independent post-H0 oracles agree on 284 canonical DCG1 bytes and FNV-1a64 `0xf85927c169cff4f1`.
- Static Red Team found no open S0 and no static reason to reject the algorithm.

## Missing mandatory evidence

- No Sonatina/EVM backend build.
- No Sonatina execution of the shared core or EVM adapter tests.
- No native executable build or run.
- No native execution of the shared core or wrapper tests.
- No executed cross-backend equality proof for clearing price, fills, ordering, canonical bytes, or fingerprint.
- No artifact inventory or runtime evidence manifest.

Static checks, authored tests, and independent oracle calculations do not substitute for this missing backend/runtime evidence.

## Resource record

At 2026-11-03T07:15:30Z, the same two external `python3` processes and one external `fe` process remained active at approximately one CPU each. Only PID, elapsed time, CPU, memory, state, and command name were observed. No arguments, paths, working directories, environments, files, or routing were inspected. No external process was modified, reprioritized, signalled, or stopped.

## Why PLAN B does not apply

PLAN B requires a complete green core and EVM path with the failure isolated to native. Neither backend path obtained empirical build/runtime evidence. Therefore there is no evidence-supported EVM-only fallback to adopt automatically.

## Isolation and disposition

- No GitHub remote is configured.
- DualClear remains isolated in its own directory, Git history, toolchain, sources, tests, logs, and documentation.
- Nothing from this project may be shared with any other candidate.
- Final status: frozen and abandoned after the fixed gate; no further development.
