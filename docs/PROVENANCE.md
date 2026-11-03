# Provenance

## Contest boundary

The Fe Builders Challenge 2026 build window opened on
**2026-11-03 00:00:00 UTC**. This repository was initialized and all Fe source,
tests, scripts, documentation, and build evidence were authored after that
boundary.
The official contest registration identifier is **FE-013**.

Precontest activity consisted of research, specification, threat modelling,
non-compilable pseudocode, and test planning. That material remains separate.
No precontest implementation or pseudocode was copied into this repository.

## Toolchain

- Fe release: 26.5.0
- Fe commit: `3dab95f8eebdccf9a2382bb59a33f7bbd03540ca`
- Linux release binary SHA-256:
  `3732fbe8a6e9d2ea3925d02d0e3a1478bc1e01d742c2be75d3ea7300c46c45f0`

The installation helper and CI verify this digest before execution.

## Historical viability baseline (local archive)

The initial technical viability checkpoint is source commit
`68339193c2a708672dbba91ad7e70736efadd9c2`, tree
`da56f13b1ca352e3530e674459f102a135d84339`. It is an audit milestone, not the
commit selected for judging.

A sealed local evidence manifest has SHA-256
`433baeef5d6083fab32ef301d44a62fa6ea0b0aa79ad994654b17e87c5134a6a`;
its verification log has SHA-256
`6e24cced230aff331747edd9ac44cd2a9bd2b54df13152baec64590691614781`.
Those archive files and large toolchain artifacts are intentionally excluded
from Git. They preserve local audit continuity but are not required to verify
the submission.

## Private history normalization

Before publication, documentation-only historical references were normalized:
machine-local absolute paths became repository-root expressions, and named
preselection alternatives became generic isolation wording. No Fe source,
tests, fixtures, ABI data, authorship, commit timestamps, or commit topology
were changed. The pre-normalization and post-normalization tip trees were
byte-identical.

A recoverable pre-normalization snapshot is retained in a sealed local Git
bundle whose SHA-256 is
`3c5ca274e885052027a4bb8be9281d26a69df85d3009745d1c36bb358d58caf5`.
The bundle is excluded from the submission repository.

## Submission-state evidence

Judging evidence is regenerated from the exact submitted checkout:

- `make candidate` executes every submission gate serially;
- `make demo` runs the short cross-backend handoff;
- `make abi-check` rebuilds and verifies artifacts, ABI, and raw EVM wire data;
- `make verify` runs the complete build and test matrix; and
- `make release-evidence EVIDENCE_TAG=fe-013-submission-v1` packages source
  hashes and deterministic generated artifacts after rerunning all gates.

GitHub Actions runs the complete candidate gate for pull requests and every
push to `main`. A candidate-tag run restores and verifies the annotated tag,
reruns the same gates, and uploads the evidence package. The contest form
receives the exact full commit SHA selected for judging; this document does not
hard-code that candidate SHA. Annotated tag `fe-013-submission-v1` points to
the same commit, and its release retains the evidence manifests and bundle.
See [the judge handoff](../JUDGING.md).

## Versioned EVM fixture provenance

`abi/DualClearGate.v1.json` is the exact ABI emitted by the pinned Fe compiler
for the release/O1 EVM build. Its SHA-256 is
`c2a85bd931e18118d85f4fd2a9046bc52ad028945485ed6328cecab0fc54d714`.

The raw v1 calldata and returndata fixtures were captured from the successful
literal-selector EVM test trace and are reproduced by `make abi-check`. Their
SHA-256 values are:

- calldata:
  `33cee4f3da8f6713a2b44248aa068ac7cf81bdfa2fe4ec0408bc2200a47c743d`;
- returndata:
  `fa8e437f79deab94526435e3d3e605993f37c283b946628b494d6ba1deb53b42`.

The check rebuilds and compares these artifacts; it does not regenerate or
rewrite the committed v1 fixtures.

## Reused material

No third-party application code was copied into the project. DualClear depends
only on the Fe core and standard libraries supplied by the pinned compiler.
The repository license applies to DualClear source and documentation, not to
the Fe toolchain.
