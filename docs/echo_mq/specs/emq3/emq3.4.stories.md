# EMQ3.4 — stories (S2 the readers, part 2 — RETENTION AS POLICY: `EchoMQ.Stream.trim/4` + a declared per-stream window + the named/opt-in trim driver)

> The acceptance face of [`emq3.4.md`](emq3.4.md) (the body is authoritative — if a story disagrees with the body, the body wins). Every Deliverable becomes a Connextra user story with concrete Given/When/Then acceptance (Gherkin/BDD); each names the invariant(s) it exercises; the Coverage map at the foot proves every Deliverable traces to a story. **The forks are RULED (the Operator ruled the two open emq3.4 forks via AskUserQuestion): D-1 the TRIO formation · D-2 the trim cadence = NAMED/OPT-IN (the `StreamConsumer` loop FROZEN) · D-3 the policy storage = BEAM-side declared config (no keyspace subkey).** The stories are authored to the ruling, NOT re-opened.
>
> **The standing liveness law (the gate-must-exercise-its-outcome rule).** Each retention story is a POSITIVE proof: a present precondition (entries inside AND below the window / a declared policy / a driver tick) MUST run the trim and assert the OBSERVABLE outcome — the window is honored by the IN-WINDOW entries actually surviving a read-back AND the below-window entries actually being gone (not "a non-error reply"); the blast radius is bounded by the IN-WINDOW entry surviving (over-deletion is a LOUD failure); the `MINID` floor is asserted by an entry minted at `dt − 1ms` being trimmed while an entry minted at `dt` survives. **A vacuous pass is a LOUD failure, never a silent green (the TRD.9.1 false-green class):** a `stream_retention` scenario that trims a non-existent window and deletes nothing, an INV4 check that asserts "nothing inside the window was removed" without ever removing anything below it, a `MINID`-floor check that never compares the floor to `min_for/1` — each proves nothing. **The destructive op (US1/US5) is proven by a real deletion AND a real survival in the SAME assertion** (the below-window entries gone, the in-window entries present), precisely because deleting nothing proves nothing about retention and deleting everything proves nothing about the bound.
>
> **The determinism posture (the load-bearing difference from emq3.3).** emq3.4 mints **NO branded ids** (the trim consumes already-minted ids; the `MINID` floor derives from a caller `DateTime`) and opens **NO lease** (`XTRIM` is a one-shot destructive op; the driver's tick clock gates WHEN to call, never a lease deadline). The same-millisecond mint hazard that mandated emq3.3's ≥100 loop is ABSENT — so the posture is **a multi-seed sweep + an honest determinism-posture statement, NOT the ≥100 loop** (running it would forge a load this rung does not introduce). The driver's tick DECISION is a pure function of the injected clock, tested directly (the `Pump.Core`/`BatchShaper.Core` precedent). Stated in EMQ3.4-US-GATE. **Risk is HIGH (a DESTRUCTIVE at-rest `XTRIM`); Apollo is MANDATORY** (the destructive op — the post-build reconcile + the §11.2 adversarial verification + the Director's blast-radius mutation battery before the ship).

---

## US1 — A trim honors the declared window and can never delete inside it (retention as policy + the bounded blast radius)

**As an** operator of an event stream with a compliance/memory window, **I want** a `trim/4` to remove ONLY the entries outside the declared window (older than the newest-N, or minted before the mint-instant floor) and to NEVER remove an entry inside the window — **so that** bounded retention is enforced (memory truth + the compliance window) WITHOUT the silent data loss of an over-eager trim (the destructive-op safety the rung exists to prove, INV4).

- **Exercises:** EMQ3.4-INV1 (trim honors the window), EMQ3.4-INV4 (the blast radius bounded — over-deletion is a LOUD failure), EMQ3.4-INV2 (a read inside the window never misses).

```gherkin
Given a RESP3 connection to Valkey on 6390 and a stream emq:{q}:stream:s with K EVT records appended via EchoMQ.Stream.append/4
  And a declared window that should retain the M newest entries (M < K) and remove the older K − M
When EchoMQ.Stream.trim/4 is called with that window (MAXLEN N or MINID floor)
Then the entries OUTSIDE the window (older than the newest-M / below the floor) are GONE
  And the entries INSIDE the window (the newest-M / at-or-above the floor) SURVIVE — a read/3..6 over the retained span returns EXACTLY them, none missing (INV1, INV2)
  And NO in-window entry was removed (INV4 — over-deletion is a LOUD test failure, asserted by the in-window branded receipts still reading back)
  And trim/4 returns {:ok, removed_count} with removed_count == the number actually removed (exact under =, ≥ the macro-node boundary under ~)
```

- **Liveness (no vacuous pass):** US1 MUST append entries BOTH inside and below the window and assert, in the SAME scenario, that the below-window entries are GONE **and** the in-window entries SURVIVE — a trim that deletes nothing (an empty/non-existent window) proves nothing about retention, and a trim that deletes everything proves nothing about the bound. The Director's **blast-radius mutation battery** mutates the trim bound / the approx-exact flag / the `MINID` floor and asserts each mutant is caught (a mutant that deletes inside the window FAILS US1; a mutant that fails to delete below it FAILS US1).
- **The approx-vs-exact safety note (INV4):** `~` (the default) may keep MORE than the window (it trims in whole macro-nodes — under-trim possible, over-trim impossible); `=` (the opt-in) removes exactly to the edge. EITHER way, no entry inside the window is removed — the destructive op's error direction is toward KEEPING data.

## US2 — A read outside the trimmed range answers truthfully (a trimmed range returns what survives, never a lie)

**As an** event-stream reader, **I want** a `read/3..6` of a range the trim has emptied to return what GENUINELY survives (possibly nothing) — never a phantom entry and never an error masking a deletion — **so that** a reader downstream of a trim sees the honest truth of the stream's current contents (INV3).

- **Exercises:** EMQ3.4-INV3 (outside the window the read answers truthfully).

```gherkin
Given a stream trimmed by MINID <floor> (every entry below the floor removed)
When read/3..6 is called over the trimmed (below-floor) range
Then it returns ONLY the surviving (at-or-above-floor) entries that fall in the requested range
  And a read of a FULLY-trimmed below-floor range returns [] (an honest empty list) — NOT an error, NOT stale phantom entries
When read/3..6 is called over a range that SPANS the floor
Then it returns exactly the at-or-above-floor entries in that span, in mint order (the surviving truth)
```

- **Liveness (no vacuous pass):** US2 MUST read a range that the trim genuinely emptied and assert an honest `[]` (or exactly the survivors), not merely "the call did not error" — a read that happens to return entries because the trim never ran proves nothing about truthful-after-deletion.

## US3 — The MINID floor is derived from the real `Snowflake.min_for/1` (the mint-instant mapping, exact)

**As a** retention-policy author, **I want** the mint-instant window's floor to be DERIVED from the shipped `EchoData.Snowflake.min_for/1` (the floor `"<ms>-0"`, `ms = unix_ms(min_for(dt))` == `DateTime.to_unix(dt, :ms)`) — never re-derived epoch arithmetic and never `min_for/1`'s raw integer handed to the wire — **so that** "keep entries minted at/after this instant" maps to `XTRIM MINID` with the EXACT half-open `[dt, ∞)` edge the writer's A1 ids define (INV6).

- **Exercises:** EMQ3.4-INV6 (the MINID floor == `Snowflake.min_for(dt)` exactly).

```gherkin
Given a retention horizon DateTime dt
When the MINID floor is computed for dt
Then the floor id is "<ms>-0" where ms == EchoData.Snowflake.unix_ms(EchoData.Snowflake.min_for(dt)) == DateTime.to_unix(dt, :millisecond)
  And the floor is DERIVED from min_for/1 (its ms component), NOT raw epoch arithmetic and NOT min_for/1's snowflake integer passed to XTRIM
When an entry minted at dt − 1ms and an entry minted at dt are both present, and trim/4 runs MINID(dt)
Then the dt − 1ms entry is TRIMMED (its ms is strictly below the floor ms) — gone
  And the dt entry SURVIVES (its ms == the floor ms, tail ≥ 0 ≥ the floor's −0) — present (the exact mint-instant edge, half-open [dt, ∞))
```

- **Liveness (no vacuous pass):** US3 MUST assert the floor's ms component equals `unix_ms(min_for(dt))` (the unit check) AND exercise the edge — a `dt − 1ms` entry trimmed, a `dt` entry surviving (the integration check). A check that only formats a string proves nothing about the floor being at the right instant.

## US4 — Retention is a property of the stream, driven by a named opt-in cadence — not coupled to consumer liveness (D-2)

**As an** operator, **I want** retention driven by a NAMED, opt-in cadence (a `Pump`-style child that re-applies each declared stream's policy via `trim/4`, OR a manual `trim/4` call) that is DECOUPLED from whether any consumer is running — **so that** a stream nobody drains still trims (its window enforced), and a stream I want UNBOUNDED is never silently trimmed (no default-on background sweep); the safety property "bounded memory" is never coupled to the liveness fact "a consumer is up" (D-2, the steward's catch).

- **Exercises:** the D-2 cadence ruling (the named/opt-in driver), EMQ3.4-INV5 (the `StreamConsumer` loop byte-frozen — the trim is NOT coupled to it).

```gherkin
Given a declared per-stream retention policy held BEAM-side (an ETS map or the driver's config) — NO keyspace subkey (D-3)
  And a named, opt-in, owner-started trim driver (the EchoMQ.Pump shape — a pure tick/decision core + a thin process router)
When the driver ticks (and NO StreamConsumer is running for that stream)
Then the driver's pure decision core answers WHICH trim/4 call to make for the declared policy (or :noop if nothing to trim)
  And the trim/4 is applied — the stream is trimmed to its window EVEN with no consumer draining it (retention is a property of the STREAM)
When an operator calls trim/4 manually (no driver)
Then the trim applies the same way (the driver is sugar over the verb, never the only path)
And git diff stream_consumer.ex is EMPTY (D-2 — the frozen emq3.3 reader loop is NOT touched; the trim is NOT folded into its beat)
```

- **Liveness (no vacuous pass):** US4 MUST exercise a trim with NO consumer present (retention decoupled from liveness — the whole point of D-2) and assert the `StreamConsumer` source is byte-frozen (`git diff stream_consumer.ex` EMPTY). The driver's decision core MUST be tested as a PURE function of the injected clock + the declared policy (the `Pump.Core`/`BatchShaper.Core` precedent — exhaustive + disjoint over the policy forms, `:noop` when nothing is due), NOT only through a live process — a buried IO `defp` is the un-testable, un-spoofable-verdict anti-pattern the architect rule forbids.

## US5 — The retention capability is a conformance scenario that positively proves the window + the bound (additive-minor, 76→77)

**As the** conformance harness, **I want** a `+1 stream_retention` scenario that POSITIVELY proves the window is honored AND the blast radius is bounded (in-window entries survive, below-window entries gone, removed-count correct) — added by the additive-minor law (the prior 76 byte-unchanged, probe-registered, both pinning tests re-pinned 76→77) — **so that** a port of the client conforms when it drives the same server to the same 77 verdicts, and a vacuous trim can never pass.

- **Exercises:** EMQ3.4-INV9 (the additive-minor conformance law), EMQ3.4-INV4 (the scenario's positive blast-radius proof), EMQ3.4-INV5/INV7/INV8/INV10 (the byte-freeze / no-new-script / no-subkey / label re-pins the run exercises).

```gherkin
Given EchoMQ.Conformance.scenarios/0 with the prior 76 scenarios byte-unchanged (ending at :stream_group)
When the +1 stream_retention scenario is registered WITH its apply_scenario(:stream_retention, …) probe in the same change
Then scenarios/0 answers exactly 77 names in run order (:stream_retention appended after :stream_group)
  And conformance_run_test.exs asserts run/2 → {:ok, 77} on the truth row (Valkey on 6390)
  And conformance_scenarios_test.exs @run_order ends at :stream_retention; the moduledoc reads "seventy-seven runnable scenarios"
  And the stream_retention scenario appends entries inside AND below a window, trims, and asserts below-window GONE + in-window SURVIVE + removed_count correct (a POSITIVE deletion+survival proof)
  And a vacuous pass (trim a non-existent window, delete nothing, assert nothing removed) is a LOUD failure
```

- **Liveness (no vacuous pass):** US5's scenario MUST exercise a real deletion (below-window entries removed) AND a real survival (in-window entries kept) in the same verdict — an ack-everything-style no-op (here: a trim-nothing no-op) is the TRD.9.1 false-green this rung guards against. The prior 76 MUST be git-verified byte-unchanged (no pair re-ordered or re-worded) and both pins updated.

## EMQ3.4-US-GATE — the standing Valkey + byte-freeze + determinism gate (the rung's liveness floor)

**As the** Director, **I want** the rung's gate to run on the live engine, prove the byte-freeze, and run the determinism posture appropriate to a no-mint/no-lease destructive rung — **so that** "done" is a closure over checks, not prose.

```gherkin
Given the echo_mq app dir and Valkey on 6390 (valkey-cli -p 6390 ping → PONG; asdf current re-probed, never hardcoded)
When the gate runs
Then TMPDIR=/tmp mix compile --warnings-as-errors is clean (per-app, never umbrella-wide)
  And TMPDIR=/tmp mix test --include valkey is green (the :valkey retention suite + the prior suites)
  And EchoMQ.Conformance.run/2 prints 77 lines and returns {:ok, 77} (the additive-minor law; both pinning tests re-pinned 76→77)
  And the byte-freeze holds: git diff echo/apps/echo_wire/ EMPTY; grep -c redis.call on the lib/ diff == 0; append/4 + every @-script byte-identical to HEAD; git diff stream_consumer.ex EMPTY; git diff keyspace.ex EMPTY; no emq:{q}:stream:<name>:policy subkey
  And the determinism posture is a MULTI-SEED SWEEP (mix test --seed 0 --include valkey + 2–3 more seeds) + an honest statement that the rung introduces no mint/lease nondeterminism — NOT the ≥100 loop (the rung mints no ids, opens no lease; running it would forge load it doesn't introduce)
  And the label reads mix.exs version: "2.6.3"; {emq}:version reads echomq:2.4.2 (the wire frozen)
  And honest-row reporting (the truth row is Valkey on 6390)
And Apollo is MANDATORY (post-build) — the destructive-op reconcile + the §11.2 adversarial verification (the blast-radius/over-deletion probe, the MINID-floor-exactness probe, the byte-freeze probe) before the Director ships
```

- **Liveness (no vacuous pass):** the gate is the rung's own liveness law — the conformance run MUST be the live 77 (not a registry-only count), the byte-freeze greps MUST be 0 / EMPTY (not asserted in prose), and the determinism posture MUST be the multi-seed sweep with the honest statement (the ≥100 loop is explicitly NOT run — its absence is correct, stated, not skipped-silently).

---

## Coverage (every Deliverable → its story → its invariant — completion provable from the text)

| Deliverable (emq3.4.md Goal) | Story | Invariant(s) |
|---|---|---|
| 1 · `EchoMQ.Stream.trim/4` over `XTRIM` (the two window forms, `~`/`=`, `{:ok, removed_count}`) | US1, US2 | INV1, INV2, INV3, INV4 |
| 2 · the `MINID` floor derived from `Snowflake.min_for/1` | US3 | INV6 |
| 3 · the declared per-stream policy, BEAM-side (no keyspace subkey) | US4 | INV8 (no subkey), D-3 |
| 4 · the named/opt-in trim driver (the `Pump` shape, decoupled from consumer liveness, the pure decision core) | US4 | INV5 (the `StreamConsumer` frozen), D-2 |
| 5 · the `+1 stream_retention` conformance scenario (76→77, the positive blast-radius proof) | US5 | INV9, INV4 |
| the destructive blast-radius bounded (load-bearing) | US1, US5 | INV4 |
| byte-freeze: `echo_wire` untouched + no new/edited Lua + `@wire_version` frozen | US5, US-GATE | INV5, INV7 |
| declared-keys VACUOUS + no grammar edit | US5, US-GATE | INV8 |
| the within-family label `2.6.3` | US5, US-GATE | INV10 |
| the gate: `:valkey` suite + the multi-seed sweep + the honest determinism posture (NO ≥100 loop) + honest-row | US-GATE | all |

**The deep-proof manifest (rides property/integration tests beside the registry):** (a) INV1/INV2/INV4 — append-inside-and-below + trim + assert-survive-and-gone over a `MAXLEN` window AND a `MINID` window (the positive blast-radius proof, both forms); (b) INV6 — the `dt − 1ms` trimmed / `dt` survives edge proof + the floor-ms unit check; (c) INV4 — the Director's blast-radius mutation battery (mutate bound / approx-exact / floor → each caught); (d) US4 — the trim driver's pure decision core tested as a function of the injected clock + the declared policy (exhaustive + disjoint, `:noop` when nothing is due), AND a trim applied with NO consumer present; (e) the multi-seed sweep + the honest determinism-posture statement (NO ≥100 loop). The polyglot seam (the stored `id` field is the canonical receipt) is emq3.3's proven property, inherited — a trimmed stream's surviving entries still carry the branded `id` field (INV2's read-back asserts it).
