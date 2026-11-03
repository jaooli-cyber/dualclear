# Security model

## Scope

DualClear is a deterministic allocation kernel and two thin adapters. It does
not authenticate orders, custody assets, transfer funds, settle trades, or
provide a complete auction lifecycle.

## Trust boundaries

- The venue or batch builder is responsible for authenticating bids.
- The venue assigns unique IDs using a deterministic policy.
- If fairness is defined per participant, the venue authenticates participants
  and aggregates or limits equivalent orders by identity and price.
- Integrators choose the supply and submit the complete bounded batch.
- Consumers must not treat the FNV checksum as a cryptographic proof.
- EVM calldata is ABI-decoded before the adapter's bid-count check.
- The four-byte selector routes the ABI call; it is not authentication and is
  not assumed collision-resistant.

If bidders can select their own IDs, they can influence an exact
equal-remainder tie. Such IDs are outside the supported trust model.

Deterministic venue assignment controls tie priority; it does not by itself
prevent a participant from splitting demand across multiple bids.

## Defended properties

The test corpus covers:

- input cardinality 0, 16, and 17;
- zero supply and zero quantity;
- duplicate IDs and demand below supply;
- input permutation with complete Outcome and DCG1 equality;
- one bid and same-price marginal groups;
- both remainder ordering and exact tie-break behavior;
- maximum `u64` quantity and `u256` price;
- conservation and no overfill;
- every `InputError` variant through the typed checked API;
- affine-price and strictly-below-clearing metamorphic relations;
- the same 19-case core corpus, including all three metamorphic relations, on
  Sonatina and native;
- twelve EVM adapter cases, including all six invalid-input classes and 16 bids;
- the canonical selector plus literal raw v1 calldata/returndata equality;
- every successful EVM outcome field compared directly with the shared-core
  result, independently of the FNV checksum;
- four native adapter cases, including typed rejection and extreme values;
- materialized native DCG1 output compared byte-for-byte with fixed fixtures;
- 26 CLI cases covering shape, ASCII parsing, overflow, bounds, and semantics.

Native integrations should use `clear_native` or `clear_checked`, both of
which return a typed `Result` for invalid input.

## Model boundaries

Largest remainder is not individually monotone when supply changes, and its
fairness unit is a bid rather than an authenticated participant. A participant
can change aggregate allocation by splitting one economic order across several
IDs even when the venue assigns those IDs deterministically.

The exact numerical counterexamples and required venue mitigation are recorded
in [Metamorphic conformance and model boundaries](METAMORPHIC.md).

## Non-goals

- resistance to malicious venue input beyond declared validation;
- cryptographic commitment or proof of an outcome;
- MEV protection, order privacy, or front-running resistance;
- settlement, escrow, authorization, signatures, or replay protection;
- unbounded order books;
- individual supply monotonicity or resistance to order splitting and Sybils;
- participant-level fairness without venue authentication and aggregation;
- production readiness or a completed third-party audit.

## Reporting

For security issues, open a private GitHub security advisory after the
repository is public. Do not publish an exploit against an active integration
before maintainers have had an opportunity to assess it.
