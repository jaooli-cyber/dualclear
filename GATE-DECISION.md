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
- Nothing from this project may be shared with OutcomeBatch or Calldata Firewall.
- Final status: frozen and abandoned after the fixed gate; no further development.

## Later user-authorized technical reassessment

At 2026-11-03T09:04Z the user required complete empirical checks of all three
candidates. This does not rewrite the original fixed-window result. DualClear
is reopened solely to determine technical viability through serial Sonatina
and native build, execution, and test evidence, clearly labelled post-window.

+
+## Post-window technical verdict
+
+**GO** on the later user-authorized technical reassessment.
+
+The final evaluated baseline is commit
+`41707de0d43d3e5bdbb412cba839af8724042d12`, tree
+`7826e05fb6733c546854008e800380f3ea36f206`, with a clean worktree and
+Fe 26.5.0 (`3dab95f`). The fresh run produced:
+
+- EVM/Sonatina release build: RC 0.
+- Shared core under Sonatina: 15 passed, 0 failed.
+- EVM adapter under Sonatina: 3 passed, 0 failed.
+- Native release build: RC 0, exactly one executable.
+- Native executable golden canary: RC 0.
+- The same shared core under native: 15 passed, 0 failed.
+- Native wrapper under native: 1 passed, 0 failed.
+
+The first late run found a genuine `core::assert`/invalid-opcode issue. A
+second run exposed that Fe's native test runner does not support the EVM-only
+`should_revert` annotation. Both were corrected in the product/test design:
+`assert!` provides proper EVM reverts, and the shared `valid_input`
+predicate makes all six invalid boundaries directly testable on both
+backends. The final verdict uses only the fresh post-fix run.
+
+Evidence is under
+`.gate-artifacts/late-final-20261103T091500Z`. Its manifest SHA-256 is
+`433baeef5d6083fab32ef301d44a62fa6ea0b0aa79ad994654b17e87c5134a6a`;
+the verification-log SHA-256 is
+`6e24cced230aff331747edd9ac44cd2a9bd2b54df13152baec64590691614781`.
+
+Residual limitations are non-blocking but must remain explicit: FNV-1a64 is
+only an interoperability fingerprint; EVM `DynArray` cardinality is checked
+after ABI decoding; and native callers should call `valid_input` before
+`clear` because invalid direct calls trap. A future typed `Result` API would
+improve native error ergonomics. No open S0 remains.
+
+The original fixed-window verdict above remains **KILL** as an audit fact.
+The later technical result is **GO** and is the result relevant to choosing a
+candidate now.
