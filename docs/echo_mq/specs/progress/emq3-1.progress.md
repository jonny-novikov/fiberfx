# emq3.1 — S1 · the writer (part 1): the stream verbs on the connector — RUNG LEDGER

The **FOUNDING rung of EchoMQ 3.0** (the Stream Tier), re-sequenced ACTIVE 2026-06-22.
Risk **NORMAL** (Fork A ruled ride-generic — the frozen wire untouched). Triad: `../emq3/emq3.1.{md,llms.md,stories.md}`.

## T-1 — the §0 derivation (Director)

emq3.1 lands the stream verbs (`XADD`/`XRANGE`/`XREADGROUP`/`XACK`/`XAUTOCLAIM`) reachable on the connector —
S1 the writer, part 1 (emq3.2 = `EchoMQ.Stream`, the writer law, NEXT). **The load-bearing reconcile
question:** can the as-built connector send an arbitrary RESP command (`XADD`) WITHOUT a frozen-line edit?

VERIFIED on disk (Director, independent of Venus-emq31's reconcile):
- `EchoMQ.Connector.command/3` (`connector.ex:47-54`) — generic: `[binary()|integer()|atom()]` parts,
  a pipeline of one; moduledoc "pipelining as the primitive."
- `EchoMQ.RESP.encode/1` (`resp.ex:20-28`) — verb-agnostic, NO command whitelist; `XADD` encodes exactly as `SET`.
- RESP3 push frames (`>`) parse to `{:push,…}`, routed out of band (`resp.ex` moduledoc) — push-safety shipped.
- `@wire_version "echomq:2.4.2"` FROZEN (`connector.ex:35`).
→ The connector is ALREADY a generic RESP client. emq3.1 rides it with ZERO `echo_wire` edit → **NORMAL**.

## D-1 — Fork A (the verb-landing mechanism) = RIDE THE GENERIC PATH (Operator-ruled)

emq3.1 rides the shipped `Connector.command/3` + the verb-agnostic codec. NO new connector method, NO
`echo_wire` edit, NO new `Script.new/2`. Typed verb ergonomics belong in emq3.2's `EchoMQ.Stream`, above the
wire. NORMAL, Apollo optional. (Rejected: the typed-connector-seam arm — a frozen-line touch, HIGH, for
ergonomics emq3.2 supplies above the wire.)

## D-2 — Fork B (the stream keyspace + conformance grain) = BRACED PER-QUEUE + ONE SCENARIO (Operator-ruled)

The stream key is `emq:{q}:stream:<name>` — a new §6 type riding the TOTAL `Keyspace.queue_key/2`, slot-sound
under `{q}`, NO grammar edit. ONE verb-floor conformance scenario (`stream_verbs`): the five verbs round-trip
+ a pipelined `XADD` batch + push-safe under RESP3, as one capability. Conformance 73→74. (Rejected: per-verb
+5 — would freeze conformance surface for verbs whose semantics aren't built until emq3.3/3.4.)

## D-3 — Fork C (the version label) = echomq:2.6.0 (Director's discretion)

Opening the Stream Tier family takes a MINOR bump with the patch reset (the emq.5.1 `2.5.0` precedent) —
`mix.exs` 2.5.2 → 2.6.0. The wire `@wire_version` stays FROZEN `echomq:2.4.2` (the deferred cutover),
consistent with the additive-minor plane (Operator-ruled 2026-06-22). The implementor skill carves
label-derivation as the Director's discretion when unambiguous; the tier-opening was surfaced and not overridden.

## D-4 — Fork D (push-safety / blocking reads) = NON-BLOCKING ONLY (Director's discretion, ladder-following)

emq3.1 delivers the verbs as non-blocking round-trips (push-safe via the connector's `{:push,…}` out-of-band
routing). Blocking `XREADGROUP BLOCK` + the consumer-group lifecycle + crash re-delivery DEFER to emq3.3 (S2
the readers), where the ladder already places them. A `BLOCK` on the single-owner socket would stall every
caller behind it. Surfaced and not overridden.

## Forward — emq3.2 (Operator-directed 2026-06-22)

After emq3.1 ships, a **2-Venus design consensus** on emq3.2 (the writer law — `EchoMQ.Stream`: hash-tagged
keys, branded record ids, append == mint order), then ship.

---

## Y-1 — Director verify: BUILD-GRADE, zero defects

Independent pass on Valkey 6390 (re-probed elixir 1.18.4 / erlang 28.5.0.1):
- **Scope** — only echo_mq (`conformance.ex` + `mix.exs` + the 2 conformance pinning tests + the NEW
  `stream_verbs_test.exs`); the Operator's `echo_graft` eg.4 work excluded.
- **Fork A (ride-generic)** — `git diff echo/apps/echo_wire` = 0 lines (the frozen wire UNTOUCHED); no new
  `Script.new/2`; `redis.call` +/- = 0 (a no-Lua rung).
- **Additive-minor** — the 73 prior scenario contracts byte-unchanged (the only touch: `batch_delay_stale`
  gaining a trailing comma — contract byte-identical); `:stream_verbs` probe-registered; both pins re-pinned 73→74.
- **Gate** — `mix test --include valkey` → 466 tests + 11 doctests, 0 failures; `Conformance.run/2` → `{:ok, 74}`.
  (The lone `--warnings-as-errors` warning is pre-existing in the sibling `echo_data`/Graft, not this rung.)
- **Teeth** — the probe + the `:valkey` proof assert POSITIVELY (`^id`-pinned XRANGE, `read_ids == ids` order,
  the XAUTOCLAIM re-claim, the load-bearing `assert_receive {:emq_push,…}`). Director net-zero mutation
  (`read_ids == Enum.reverse(ids)`) → `CONF stream_verbs FAIL {:fail,{:pipeline_batch,false}}`, 73/74,
  `conformance_run_test` red → reverted by inverse Edit (0 `reverse` residue, 74/74 restored). Three independent
  catches total (Mars's XRANGE-field + push-body, this ordering).
- **Determinism** — a multi-seed sweep (NORMAL): the verb path mints NO branded id (server `*` id; the branded
  record id is emq3.2's writer law) and starts NO process; the ≥100 loop's same-ms hazard is ABSENT. Honest posture.

Verdict: **BUILD-GRADE, zero defects.** Mars-2 collapsed (no remediate items).

## Z-1 — SHIPPED

emq3.1 SHIPPED — the **stream-verb floor** on the certified connector: the five verbs
(`XADD`/`XRANGE`/`XREADGROUP`/`XACK`/`XAUTOCLAIM`) ride the shipped generic command path verb-agnostically
(ZERO `echo_wire` edit), on the braced `emq:{q}:stream:<name>` key. Conformance 73→74 (`+stream_verbs`), label
`echomq:2.6.0` (opens the Stream Tier family; wire `@wire_version` frozen `echomq:2.4.2`). The **FOUNDING rung
of EchoMQ 3.0 — the Stream Tier.** Committed by the Director (LAW-4 pathspec). **NEXT: emq3.2** — the writer law
(`EchoMQ.Stream`) via the 2-Venus design consensus (Operator-directed 2026-06-22).
