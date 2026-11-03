# Metamorphic conformance and model boundaries

DualClear runs the same deterministic relations from the shared Fe core under
both Sonatina and native. These tests complement fixed golden vectors: they
change a valid input and assert only the economic or byte-level relation that
must follow.

Run the judge demo:

```sh
make demo
```

Its first and third stages execute the three `metamorphic_*` tests from
`gate/core/src/lib.fe` under Sonatina and native respectively. The relations
are not duplicated in backend-specific adapters.

## Supported relations

| Transformation | Required relation | Intentionally not required | Preconditions |
| --- | --- | --- | --- |
| Permute the golden bids | Complete `Outcome`, ranked fills, fingerprint, and every DCG1 byte are identical | Nothing | Same uniquely identified bids |
| Apply `price_raw' = 3 * price_raw + 17` | Filled quantity, ranked IDs/fills, and DCG1 length are preserved; clearing price follows the same transform | Equal DCG1 bytes or fingerprint | Positive slope; no `u256` overflow |
| Add a bid at `500000`, below every golden price, with maximum `u64` quantity | Clearing price, filled quantity, and all existing allocations are preserved; the new bid is the final zero-fill; DCG1 grows by 56 bytes | A different fingerprint | Fixed supply; unique ID; room below `MAX_BIDS`; new price below every existing price |

This finite vector's `500000` price is below the golden minimum of `1000000`,
so the new zero-fill ranks last. A bid that is merely below the clearing price
is still economically inert at fixed supply, but it need not be the final
ranked record.

The permutation relation compares the complete canonical representation, not
only its FNV checksum. The other two relations compare economic fields because
their transformed records legitimately change DCG1. They never use fingerprint
inequality as an oracle: FNV-1a64 is not collision-resistant.

This is a compact deterministic corpus, not fuzzing or a formal proof. The
fixed golden, maximum-value, maximum-cardinality, invalid-input, and CLI corpora
remain independent parts of `make verify`. Separately, `make abi-check`
protects the EVM metrics, compiler-emitted ABI, and complete raw-wire golden.

## Explicit non-properties

### Increasing supply is not individually monotone

Largest remainder is not house-monotone. For six same-price bids with IDs
`1..6` and quantities

```text
[1500, 1500, 900, 500, 500, 200]
```

the deterministic allocations are:

```text
supply 25 -> [7, 7, 4, 3, 3, 1]
supply 26 -> [8, 8, 5, 2, 2, 1]
```

Bids 4 and 5 lose one unit when supply increases. Integrators must not assume
individual fill monotonicity across independently cleared batches.

### Allocation is per bid, not split-resistant per participant

At one price and supply 2:

```text
before: [(id 1, quantity 2), (id 9, quantity 1)] -> fills [1, 1]
after participant A splits:
        [(id 1, quantity 1), (id 2, quantity 1),
         (id 9, quantity 1)]                    -> fills [1, 1, 0]
```

Participant A's aggregate fill rises from 1 to 2. Venue-assigned deterministic
IDs prevent bidders from choosing tie priority, but do not by themselves
prevent order splitting or Sybil behavior.

If fairness is required per participant, the trusted venue must authenticate
participants and aggregate or limit equivalent orders by stable,
Sybil-resistant economic identity and price before invoking DualClear. The
kernel has no identity or authentication layer.
