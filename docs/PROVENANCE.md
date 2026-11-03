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

## Verified baseline

The technical viability baseline is source commit
`41707de0d43d3e5bdbb412cba839af8724042d12`, tree
`7826e05fb6733c546854008e800380f3ea36f206`.

The sealed evidence manifest has SHA-256
`433baeef5d6083fab32ef301d44a62fa6ea0b0aa79ad994654b17e87c5134a6a`.
Its verification log has SHA-256
`6e24cced230aff331747edd9ac44cd2a9bd2b54df13152baec64590691614781`.

Large local toolchain and evidence artifacts are intentionally excluded from
Git. The public repository provides pinned installation and reproducible
commands so the accepted results can be regenerated.

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
