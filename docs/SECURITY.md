# Security model

## Scope

DualClear is a deterministic allocation kernel and two thin adapters. It does
not authenticate orders, custody assets, transfer funds, settle trades, or
provide a complete auction lifecycle.

## Trust boundaries

- The venue or batch builder is responsible for authenticating bids.
- The venue assigns unique IDs using a deterministic policy.
- Integrators choose the supply and submit the complete bounded batch.
- Consumers must not treat the FNV checksum as a cryptographic proof.
- EVM calldata is ABI-decoded before the adapter's bid-count check.

If bidders can select their own IDs, they can influence an exact
equal-remainder tie. Such IDs are outside the supported trust model.

## Defended properties

The test corpus covers:

- input cardinality 0, 16, and 17;
- zero supply and zero quantity;
- duplicate IDs and demand below supply;
- input permutation;
- one bid and same-price marginal groups;
- both remainder ordering and exact tie-break behavior;
- maximum `u64` quantity and `u256` price;
- conservation and no overfill;
- every `InputError` variant through the typed checked API;
- the same 17-case core corpus on Sonatina and native;
- ten EVM adapter cases, including all six invalid-input classes and 16 bids;
- four native adapter cases, including typed rejection and extreme values;
- materialized native DCG1 output compared byte-for-byte with fixed fixtures;
- 26 CLI cases covering shape, ASCII parsing, overflow, bounds, and semantics.

Native integrations should use `clear_native` or `clear_checked`, both of
which return a typed `Result` for invalid input.

## Non-goals

- resistance to malicious venue input beyond declared validation;
- cryptographic commitment or proof of an outcome;
- MEV protection, order privacy, or front-running resistance;
- settlement, escrow, authorization, signatures, or replay protection;
- unbounded order books;
- production readiness or a completed third-party audit.

## Reporting

For security issues, open a private GitHub security advisory after the
repository is public. Do not publish an exploit against an active integration
before maintainers have had an opportunity to assess it.
