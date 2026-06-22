# emq3.2 — S1 · the writer LAW: `EchoMQ.Stream` — RUNG LEDGER

The writer law of EchoMQ 3.0 (the Stream Tier), designed via the **DUAL-ARCHITECT** formation
(Operator-directed 2026-06-22). Risk **NORMAL+** (a branded-id MINT surface — the ≥100 determinism loop is its gate).

## T-1 — the dual-architect design phase (Director)

emq3.2 founds the `EchoMQ.Stream` writer law (per-key hash-tagged streams, branded record ids, append ==
mint order, wrong-kind refused at the door) above the emq3.1 verb floor. Two architects designed it
INDEPENDENTLY (neither saw the other):
- **Venus-A** (order-theorem lens) — `emq3.2.design.venusA.md` — reasoned ADR-1 to the ground with a live order probe.
- **Venus-B** (API lens) — the surface + the single-writer-per-stream bound.

**CONVERGENCE:** both independently reached mapping **A1** (the explicit `<ms>-<seq>` XADD id decoded from
the snowflake). Director-verified the order-preservation on disk: `Base62` lexicographic == numeric
(`base62.ex:3`); the snowflake layout `ts(41) <<< 22 ||| node(10) <<< 12 ||| seq(12)` + `unix_ms` =
`(snow >>> 22) + @epoch_ms` (`snowflake.ex:3/107`). The synthesis folds Venus-A's `unix_ms` refinement (the
REAL Unix-ms, for emq3.6 time-travel) + the `{:error, :nonmonotonic}` liveness check + Venus-B's
single-writer bound.

## D-1 — ADR-1 (the id mapping) = A1, RATIFIED (Operator)

`xadd_id = "#{Snowflake.unix_ms(snow)}-#{snow &&& 0x3FFFFF}"` (real Unix-ms · the 22-bit `node|seq` tail); the
14-byte branded string stored as the `id` field. stream order == id sort == mint order BY CONSTRUCTION (both
from the one snowflake; Director-verified order-preserving). Single-writer-per-stream → holds every time (the
`:atomics` CAS strictly monotone); multi-writer → `{:error, :nonmonotonic}` on XADD's `id<=top` rejection,
NEVER swallowed (the F-A liveness check). Multi-writer-per-stream = the parked log-tier-exit seam. (Rejected:
server `*` — append order ≠ mint order, forfeits the theorem + breaks emq3.6; `<ms>-*` — loses sub-ms order;
whole-int-in-ms — breaks XRANGE-by-time.)

## D-2 — ADR-2 (the kind door) = host-side RAISE, brand `EVT` (Operator + Director)

Wrong-kind refused HOST-SIDE by a RAISE before any wire (Operator-ruled), symmetric with the shipped
`Keyspace.job_key/2` wellformedness gate — the principled split: programming errors raise, runtime conditions
(`:nonmonotonic`) return typed. Brand `EVT` (Director, matching the tier's "event streams"). ONE brand per
stream (REQUIRED — base62 byte order == int order holds only within one NS prefix). NO new script (`append`
mints the brand → nothing to spoof; byte-freeze trivially held, the `EMQKIND`/`EMQSTALE` registry unextended).
(Rejected: server-side Lua — theater for a minted id + flips Apollo mandatory; typed `{:error, :kind}` —
chosen-against, the raise matches `job_key/2`.)

## D-3 — ADR-5 (conformance grain) = +1 `stream_append`, 74→75 (Director)

ONE verb-floor scenario (`stream_append`: mint + the kind door + the append-order theorem as one capability),
74→75. The DEEP order-theorem proof rides the property test + the ≥100 loop, not extra example scenarios.
(Rejected: +3 decomposition — over-counts reach as behavior.)

## D-4 — ADR-6 (label + risk) = `echomq:2.6.1`, NORMAL+ (Director)

Label `echomq:2.6.1` (within-family PATCH — emq3.1 opened the family at `2.6.0`). `@wire_version` FROZEN
`echomq:2.4.2` (the deferred cutover). Risk NORMAL+ (a MINT surface — the ≥100 loop is its gate): no
frozen-line touch (zero `echo_wire` edit, no new script), no destructive op, no new wire class. Apollo OPTIONAL
(no process/lease/destructive/frozen trigger), upgradeable at the Operator's discretion.

## Forward — the build

The triad derives from this ruled consensus (Venus-A authoring); then Mars builds (the pure `Stream.Id` core +
`Stream.append`/`read` + the `stream_append` scenario + the StreamData property test + the ≥100 loop), the
Director verifies, ship.

---

## Y-1 — Director verify: BUILD-GRADE, zero defects

Independent pass on Valkey 6390 (re-probed elixir 1.18.4 / erlang 28.5.0.1):
- **Scope** — exactly 8 echo_mq files (the pure `Stream.Id` core + the `Stream` writer + 2 test files;
  `conformance.ex` + `mix.exs` + the 2 pins). `echo_graft`/`echo_store` excluded (Operator's out-of-band).
- **Byte-freeze** — `echo_wire` diff = 0, `keyspace.ex` diff = 0; `redis.call` +/- = 0 (no new Lua);
  `@wire_version` frozen `echomq:2.4.2`. No dep change (umbrella `mix.lock` = 0; `mix.exs` diff = only the
  `2.6.1` label; `stream_data` NOT added — the property test is a deterministic enumeration).
- **Additive-minor** — prior 74 scenario contracts byte-unchanged (the only `conformance.ex` removals are
  moduledoc narrative + 2 trailing commas); `stream_append` probe-registered; both pins re-pinned 74→75.
- **Code (read)** — `Stream.Id` pure (A1 `xadd_id = unix_ms-tail22`, the order theorem by construction,
  doctested); `Stream.append_id` the kind door FIRST (wrong-kind/malformed RAISE before any wire), the
  `id<=top` rejection mapped to `{:error, :nonmonotonic}` ONLY on the verbatim error string (precise, not a
  catch-all). The `append/4`-mints + `append_id/5`-door realization gives INV2 a real witness while keeping
  the public API spoof-proof.
- **Gate** — `mix test --include valkey` → 480 tests + 16 doctests, 0 failures; `Conformance.run/2` →
  `{:ok, 75}`. The Director's INDEPENDENT ≥100 determinism loop on the mint suite → **100/100** (the
  load-bearing gate — emq3.2 mints branded ids).
- **Teeth** — the order theorem proven 3 ways (in-scenario read-back + the deterministic same-ms enumeration
  + the ≥100 loop). Director net-zero mutation on the `:nonmonotonic` liveness (broke `@id_too_small` →
  EMQ3.2-INV3 caught it → reverted, 0 residue, 8/8 restored). 3 independent catches (Mars's A1-node-drop +
  reversed-order; the Director's `:nonmonotonic`).

Verdict: **BUILD-GRADE, zero defects.** Mars-2 collapsed (no remediate items).

## Z-1 — SHIPPED

emq3.2 SHIPPED — the **WRITER LAW**: `EchoMQ.Stream` (`append` mints an `EVT`-branded record id, derives the
A1 XADD id, appends in mint order; wrong-kind RAISES; `id<=top` → `{:error, :nonmonotonic}` never swallowed)
over the pure `EchoMQ.Stream.Id` core (the order theorem `stream order == id sort == mint order`, by
construction). `emq:{q}:stream:<name>` via the shipped `queue_key/2` (no grammar edit, no new Lua). Conformance
74→75 (`+stream_append`), label `echomq:2.6.1` (wire `@wire_version` frozen `echomq:2.4.2`). Designed via the
dual-architect formation (convergent on A1). Committed by the Director (LAW-4 pathspec). **NEXT: emq3.3** — S2
the readers (the consumer group + the polyglot seam + crash re-delivery).
