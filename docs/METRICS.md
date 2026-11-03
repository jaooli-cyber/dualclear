# Reproducible EVM metrics

DualClear measures its deployable EVM artifacts with the same pinned compiler
and build profile used by verification:

- Fe 26.5.0, commit `3dab95f`, binary SHA-256
  `3732fbe8a6e9d2ea3925d02d0e3a1478bc1e01d742c2be75d3ea7300c46c45f0`;
- Sonatina backend;
- release profile;
- optimizer level `O1`.

Run:

```sh
make metrics
```

The command verifies the compiler version and binary hash, rebuilds the EVM
adapter, validates non-empty even-length hexadecimal bytecode, and measures the
ABI JSON. It prints stable `key=value` data and compares it byte-for-byte with
the versioned `demo/evm-metrics.env` snapshot. Compiler progress is sent to
stderr. Generated artifacts stay under `out/metrics/` and are not committed.

## Current snapshot

| Artifact | Size | Emitted-file SHA-256 |
| --- | ---: | --- |
| Creation bytecode | 7,951 bytes | `595ce500dead0f457789a6f9ecdffbfd649c5a3dce126fc9f624d7ceaee3f55d` |
| Runtime bytecode | 7,931 bytes | `ca919ddaf861519bed4c33853bb944a18b2f1a98a3b6046e342854168bd22e1c` |
| ABI JSON | 1,094 bytes | `c2a85bd931e18118d85f4fd2a9046bc52ad028945485ed6328cecab0fc54d714` |

Bytecode sizes count decoded bytes; their hashes cover the exact ASCII-hex
files emitted by Fe. The ABI hash covers the emitted JSON file.

The snapshot also pins `evm_source_bundle_sha256`. It hashes, in a fixed
order, the workspace manifest plus the core and EVM ingot manifests and source
files. This binds the artifacts to all source inputs used by the EVM build
without requiring Git metadata.

The deployed runtime has 16,645 bytes of headroom below the
[EIP-170](https://eips.ethereum.org/EIPS/eip-170) limit of 24,576 bytes.
`scripts/metrics.sh` fails if that limit is exceeded or the versioned snapshot
drifts. CI runs both checks on every pull request and push to `main`.

## What these numbers do not claim

- They are artifact sizes, not deployment or call gas.
- The `2,000,000` gas values in EVM tests are execution caps, not measured
  consumption.
- The Fe test call trace proves successful calls and returned bytes but does not
  report gas used.
- ABI JSON size includes formatting and is recorded for reproducibility, not as
  an on-chain limit.
- Native executable size is intentionally excluded because it depends on the
  host linker and target environment.

DualClear will not publish a gas figure until it can be reproduced with an
appropriate official measurement path and documented inputs.
