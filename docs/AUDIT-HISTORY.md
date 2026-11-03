# Audit history

This page separates the historical scheduling decision from the technical
viability result.

## Original fixed-window result

DualClear's original 2026-11-03 03:15-07:15 UTC gate closed as `KILL` because
the then-active shared-host resource rule prevented backend builds and runtime
tests inside that fixed window. Static format and semantic checks had passed,
but they were correctly not treated as empirical proof.

That result is retained as an audit fact. It was not a demonstrated failure of
the algorithm or either backend.

## User-authorized technical reassessment

After the resource policy was explicitly changed, a low-priority serial run
tested the project completely. It found two real issues:

1. `core::assert` produced an invalid-opcode failure on EVM negative cases.
   Product assertions were changed to `assert!`.
2. Fe 26.5.0's native runner does not support EVM-only `should_revert`.
   Invalid boundaries were moved to the portable `valid_input` predicate and
   exercised on both targets.

The original final baseline produced:

- EVM/Sonatina build: RC 0;
- core tests on Sonatina: 15/15;
- EVM adapter tests: 3/3;
- native build and standalone executable: RC 0;
- the identical core tests on native: 15/15;
- native wrapper test: 1/1.

Subsequent contest-window hardening added typed errors and reran the public
workflows successfully:

- core tests on Sonatina and native: 16/16 on each backend;
- EVM adapter tests: 3/3;
- native wrapper tests: 2/2;
- `make verify` and `make demo`: pass.

Conformance Pack v1 then made the canonical encoding inspectable and expanded
the adapter matrix:

- exact comparison of all 284 golden DCG1 bytes on both core backends;
- core tests: 17/17 on Sonatina and 17/17 on native;
- EVM adapter tests: 10/10;
- native adapter tests: 4/4.

The bounded native CLI then added strict decimal parsing, stable silent error
codes, explicit-input DCG1 emission, maximum-value and 16-bid fixtures, and a
26-case parser/boundary matrix. It continues to call `clear_checked`; it does
not duplicate the clearing algorithm.

Red Team also reproduced a late buffered-output failure with `/dev/full`.
Fe 26.5 does not expose the final flush as a fallible operation, so a proposed
exit-code guarantee was removed before commit. The accepted host-I/O limitation
is documented explicitly instead.

The metrics review then closed two provenance gaps: direct script execution now
verifies the official compiler binary hash, and CI compares EVM measurements
against a source-bound versioned snapshot. Artifact-size claims remain separate
from gas claims.

The post-gate technical verdict is `GO`. This is the verdict relevant to
the project's feasibility. The historical scheduling verdict remains visible
here and in the underlying Git history.

## Residual findings

No blocking S0 or S1 finding remains. The post-baseline hardening added
`InputError`, `validate_input`, `clear_checked`, and a native
`Result<InputError, Outcome>` API. Accepted limitations include trusted venue
ID assignment, post-decode EVM cardinality, the assertion-based enforcing EVM
entrypoint, buffered native-output finalization, and a non-cryptographic FNV
interoperability checksum.

The detailed gate records remain recoverable in the post-H0 Git history. They
are not part of the current public-facing tree because they contain superseded
states and host-specific runbook paths; this page is the authoritative summary.
