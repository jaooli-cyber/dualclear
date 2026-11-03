# EVM integration

DualClearGate v1 is the EVM adapter for project **FE-013**. It is a pure,
stateless interface over the shared clearing kernel. This repository does not
publish an official deployment address; integrators build and deploy the
pinned source themselves.

## Versioned interface

- compiler: Fe 26.5.0 (`3dab95f`);
- release optimizer: `O1`;
- emitted EVM target: `osaka`; deployment requires destination-chain
  compatibility;
- constructor: no arguments;
- function signature: `clear(uint64,(uint64,uint256,uint64)[])`;
- selector: `0x74ad3a54`;
- mutability: `pure`;
- ABI: [`abi/DualClearGate.v1.json`](../abi/DualClearGate.v1.json);
- decoded golden:
  [`abi/DualClearGate.v1.golden.json`](../abi/DualClearGate.v1.golden.json);
- raw golden:
  [calldata](../abi/DualClearGate.v1.calldata.hex) and
  [returndata](../abi/DualClearGate.v1.returndata.hex).

The selector is fixed by a Fe `sol(...)` test and exercised as a literal by a
raw-calldata test. `make abi-check` executes that call, compares the complete
returndata, rebuilds the ABI, and compares every generated ABI byte with the v1
fixture.

The trace parser deliberately accepts only the call-line format emitted by the
exact pinned Fe 26.5.0 binary; its version and SHA-256 are checked before use.

The committed DualClearGate v1 fixture is frozen as a repository versioning
policy, not as a claim that a deployment cannot be replaced. Any intentional
change to the function name or signature, constructor, mutability, component
names, output names, or input/output types or positions requires review and a
new interface version. The v1 fixtures are never updated automatically.

A four-byte selector provides routing; it is not an authentication mechanism,
and selector collisions are possible.

## Inputs

| Field | ABI type | Contract |
| --- | --- | --- |
| `supply` | `uint64` | Positive quantity to allocate |
| `bids` | `(uint64,uint256,uint64)[]` | Between 1 and 16 bid tuples |
| `bids[i].id` | `uint64` | Unique, venue-assigned identifier |
| `bids[i].price_raw` | `uint256` | Raw six-decimal fixed-point price |
| `bids[i].quantity` | `uint64` | Positive requested quantity |

A raw price of `2000000` represents `2.000000`. Price zero and ID zero are
technically accepted. Integrations may impose a stricter policy, but IDs must
remain unique and must be assigned by the trusted venue under a deterministic
policy. Bidders must not choose IDs, because lower IDs resolve exact remainder
ties.

Aggregate demand must be at least `supply`. Input order has no effect on an
accepted outcome when the same uniquely identified bids are supplied.

## Positional outputs

The generated v1 ABI does not name return values. Clients must decode the
tuple by position:

| Position | Documentation name | ABI type | Meaning |
| ---: | --- | --- | --- |
| 0 | `clearing_price_raw` | `uint256` | Raw six-decimal clearing price |
| 1 | `filled` | `uint64` | Allocated quantity; equals supply on success |
| 2 | `fingerprint` | `uint64` | FNV-1a64 interoperability checksum |
| 3 | `fills` | `(uint64,uint64)[]` | Ranked `(id, quantity)` allocations |

`fills` is ordered by price descending and then ID ascending, not by calldata
order. The adapter returns every fill, including zero quantities.

The shared kernel constructs the complete canonical DCG1 bytes internally.
The EVM ABI returns the scalar fields, all ranked fills, and the checksum; it
does **not** return the DCG1 byte string. Tests compare every returned field
with the shared `Outcome`, while independent core tests compare the complete
DCG1 bytes on both backends.

The FNV value is not collision-resistant. It must not be used as a commitment,
signature, proof, or authorization decision.

## Golden call

The versioned decoded fixture stores all input and output numeric fields as
strings to avoid JSON number precision loss. Its human-readable equivalent is:

```text
clear(
  7,
  [
    (2, 2000000, 5),
    (3, 1000000, 7),
    (9, 3000000, 2),
    (1, 2000000, 5)
  ]
)

returns (
  2000000,
  7,
  0xf85927c169cff4f1,
  [(9, 2), (1, 3), (2, 2), (3, 0)]
)
```

The raw calldata is 484 bytes and begins with the literal selector
`0x74ad3a54`; the exact returndata is 416 bytes. `make abi-check` compares
both complete byte strings with the checked-in fixtures.

The algorithm reference is [`demo/golden.json`](../demo/golden.json). The
corresponding 284-byte canonical representation is
[`demo/golden.dcg1.hex`](../demo/golden.dcg1.hex).

## Revert behavior

V1 uses an enforcing EVM boundary. It reverts for:

- an empty bid list;
- more than 16 bids;
- zero supply;
- a zero bid quantity;
- duplicate IDs;
- aggregate demand below supply.

Malformed calldata may fail during ABI decoding. The dynamic bid array is
decoded before the adapter checks its cardinality, so this interface is not a
predecode calldata firewall.

V1 exposes neither typed custom errors nor a stable, distinguishable revert
payload for these validation classes. Clients should prevalidate and treat any
revert as a rejected batch. Native consumers that need typed errors should use
`clear_native` or `clear_checked`, which return
`Result<InputError, Outcome>`.

## Scope

DualClearGate calculates a deterministic allocation. It does not authenticate
orders, custody or transfer assets, provide MEV protection, enforce an auction
schedule, or implement settlement. Test call gas values are execution caps,
not gas measurements.

## Reproduce

```sh
make verify
make abi-check
make demo
```

`make verify` runs the selector test, complete raw golden, full-field adapter
comparison, invalid-input matrix, and the shared core under both Sonatina and
native backends. `make abi-check` also runs the reproducible EVM metrics gate.
