# Reproducible EVM metrics

DualClear measures its deployable EVM artifacts with the same pinned compiler
and build profile used by verification:

- Fe 26.5.0, commit `3dab95f`, binary SHA-256
  `3732fbe8a6e9d2ea3925d02d0e3a1478bc1e01d742c2be75d3ea7300c46c45f0`;
- Sonatina backend;
- release profile;
- optimizer level `O1`;
- emitted metadata `evmVersion`: `osaka`.

Run:

```sh
make metrics
```

CI uses the stricter superset:

```sh
make abi-check
```

The command verifies the compiler version and binary hash, rebuilds the EVM
adapter, validates non-empty even-length hexadecimal bytecode, and measures the
ABI JSON. It also requires exactly one emitted metadata `evmVersion` and pins
that value in the snapshot. Before accepting the metrics, it compares the
emitted ABI
byte-for-byte with `abi/DualClearGate.v1.json`. It then prints stable
`key=value` data and compares it byte-for-byte with the versioned
`demo/evm-metrics.env` snapshot. Compiler progress is sent to stderr.
Generated artifacts stay under `out/metrics/` and are not committed.

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

The snapshot records `abi_fixture_version=v1`, keeping the interface label
visible beside the artifact hashes. A change can pass only when compiler output,
the fixture, and the source-bound snapshot are deliberately updated together;
repository policy requires such an intentional interface change to introduce a
new version rather than rewriting v1.

The deployed runtime has 16,645 bytes of headroom below the
[EIP-170](https://eips.ethereum.org/EIPS/eip-170) limit of 24,576 bytes.
`scripts/metrics.sh` fails if that limit is exceeded, the emitted ABI differs
from v1, or the versioned snapshot drifts.

## Versioned interface gate

`make abi-check` first runs the metrics gate. It then:

1. validates the committed ABI, calldata, and returndata fixtures as regular,
   non-symlinked files;
2. executes the adapter through a literal raw `0x74ad3a54` calldata payload;
3. extracts the single external call from Fe's call trace; and
4. compares the complete calldata and returndata byte-for-byte with the v1
   fixtures.

CI runs this full check on every pull request and push to `main`. The ABI and
raw wire format are documented in [EVM integration](EVM.md). Any intentional
interface change requires a new version instead of rewriting v1.

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
