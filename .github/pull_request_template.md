## Summary

Describe the change and why it belongs in DualClear.

## Verification

- [ ] `make metrics`
- [ ] EVM metric snapshot updated if EVM artifacts intentionally changed
- [ ] `make verify`
- [ ] `make demo`
- [ ] EVM and native adapters still call the shared core
- [ ] Cross-backend outcomes remain identical

## Security and semantics

- [ ] The trusted venue ID-assignment policy is preserved
- [ ] FNV-1a64 is described only as an interoperability fingerprint
- [ ] New limitations or assumptions are documented
- [ ] No precontest implementation or pseudocode was copied

## Assistance disclosure

Describe any AI assistance, reused code, or external material involved in this
change, including how the result was independently verified.
