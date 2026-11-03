# Limitations

DualClear is deliberately narrow. These limitations are part of the supported
claim, not hidden implementation details.

1. **Maximum 16 bids.** The current fixed bound keeps execution and test vectors
   reviewable.
2. **Trusted ID assignment.** Lower IDs resolve exact remainder ties. IDs must
   be assigned by the venue, not strategically selected by bidders.
3. **Post-decode EVM bound.** The typed `DynArray` is materialized by ABI
   decoding before the adapter checks its length.
4. **Two error surfaces.** Native callers receive typed `InputError` values
   through `clear_native`/`clear_checked`. The assertion-based `clear`
   entrypoint remains for the enforcing EVM path and traps/reverts on invalid
   input.
5. **Non-cryptographic fingerprint.** FNV-1a64 detects ordinary integration
   drift; it is not collision-resistant.
6. **No settlement layer.** The kernel calculates allocations but does not move
   assets, authenticate orders, or enforce an auction schedule.
7. **Six-decimal price scale.** Prices use `UFixed<6>`; integrations must
   normalize external price units explicitly.
8. **Prototype status.** Fe 26.x and its native backend are evolving. Pin the
   exact compiler, rerun both target suites, and assess the final deployment
   environment.
