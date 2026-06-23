# EMQ3.6 · stories — TIME-TRAVEL + HYDRATION (the acceptance face)

> The acceptance face of [`emq3.6.md`](emq3.6.md) (the body is authoritative — if a story disagrees with the body, the body wins). Every Deliverable becomes a Connextra user story with concrete Given/When/Then acceptance (Gherkin/BDD); each names the invariant(s) it exercises; the Coverage map at the foot proves every Deliverable traces to a story. **This is a TWO-APP rung (`echo_mq` + `echo_store`) — the emq3.5 D-1 precedent (the `echo_store → echo_mq` arrow forces the time-travel READ bus-side and the hydration WRITE-from-the-stream store-side).** The DoD is fixed ([`../../emq.streams.md`](../../emq.streams.md):73 — *"a mint-time window read equals the id-filtered truth; hydrate-then-fence equals loader truth"*); the FIVE **Arms** are carved for the Director (Arm 1 scope · Arm 2 the read surface · Arm 3 the hydration mechanism [TIER-SETTING] · Arm 4 the hydration source · Arm 5 the conformance posture — [`../progress/emq3-6.progress.md`](../progress/emq3-6.progress.md)). The stories are FORWARD-TENSE (this rung is NOT built — Stage 1); where an Arm will shape an acceptance it is named inline.
>
> **Framing law (propagated).** Third person for any agent; no gendered pronouns for agents; no perceptual or interior-state verbs for agents or software; no first-person narration. Bind this same clause in any sub-brief.
>
> **The standing liveness law (the gate-must-exercise-its-outcome rule — TRD.9.1 false-green class).** Each story is a POSITIVE proof: a present precondition (records appended across known instants / a tail hydrated / a fence admission) MUST run the operation and assert the OBSERVABLE outcome — the time-travel property is proven only by a window that ACTUALLY EXCLUDES entries (a window read EQUAL to the id-filtered truth, the filter actually firing); the hydration property is proven only by ≥2 records per key (so newer-wins ACTUALLY fires) and the newest value reading back; the fence composition is proven only by a REAL post-hydrate admission winning over a stale value. **A vacuous pass is a LOUD failure, never a silent green:** a window read over a window that excludes nothing (degenerate to `"-"`/`"+"`) proves nothing about the bounds; a hydrate of one record per key proves nothing about newer-wins; a fence check that never admits a newer value proves nothing about the staleness fence. Each story names its no-vacuous-pass condition explicitly.

## US1 — Time-travel: a mint-time window read returns exactly the in-window entries, equal to the id-filtered truth

**As** a bus stream reader running a backtest / audit / debug over a recorded event stream,
**I want** to read the stream entries whose branded mint-instant falls in a `DateTime` window,
**so that** I can replay exactly the window of history I care about without reading and filtering the whole stream by hand.

- **Given** a stream `emq:{q}:stream:<name>` with N `EVT` records appended across KNOWN, distinct mint instants (some before the window, some inside it, some after),
- **When** a mint-time window read over `[t0, t1]` (Arm 2's surface — `read_window/5` closed, or `read_since/4` half-open) is issued,
- **Then** it returns EXACTLY the entries whose branded `EVT` mint-instant (`Snowflake.to_datetime/1` of the id's snowflake) falls in the window, in mint order;
- **And** the returned set EQUALS `Enum.filter(full_read, &(mint_instant(&1) in window))` (the id-filtered truth — the window read is just a server-side filter via `XRANGE` bounds);
- **And** the bounds derive from `Snowflake.min_for/1` (the shipped `minid_floor/1` lower floor) + the new upper-bound inverse — never a raw `min_for/1` integer handed to the wire (INV-BOUND, the F-1-class discipline);
- **And** the read adds NO Lua (`XRANGE` host-issued — `grep -c redis.call` on the bus diff = 0).
- **Invariants:** EMQ3.6-INV-TT (window == id-filter), EMQ3.6-INV-BOUND (the shipped floor + the new inverse; the half-open edge exact), EMQ3.6-INV-ADDITIVE (no Lua).
- **Liveness (no vacuous pass):** US1 MUST read a window that STRADDLES the data so the bounds ACTUALLY EXCLUDE entries (a record before `t0` and a record after `t1` both absent from the result), and assert the result EQUALS the id-filter over the full read. A window containing ALL records (degenerate to `"-"`/`"+"`) and a window containing NONE (empty) are asserted as edges, but the load-bearing case is the straddle — a window that never excludes anything proves nothing about the bounds. The exact-`ms` edge is asserted: a record minted at `t0` is IN a `[t0, …)` window, a record minted at `t0 - 1ms` is OUT.

## US2 — The bound math: the lower floor reused, the upper bound the new inverse, the edge exact

**As** the implementor of the time-travel read,
**I want** the window bounds derived from the shipped `Snowflake.min_for/1` floor (lower) + a new inverse (upper),
**so that** the window edge is exact at the millisecond and no raw snowflake integer ever reaches the wire.

- **Given** the shipped `EchoMQ.Stream.minid_floor/1` (`stream.ex:239` — `DateTime` → `"<ms>-0"` via `Snowflake.unix_ms(min_for(dt))`, the half-open `[dt, …)` floor `trim/4` MINID already proves),
- **When** the time-travel read computes its `XRANGE` `from` (the lower bound) and `to` (the upper bound),
- **Then** the `from` reuses the SHIPPED `minid_floor/1` (byte-frozen — the lower floor is already proven on the trim path);
- **And** the `to` is the NEW inverse this rung adds — the LARGEST entry id at-or-before `t1`, `"<ms>-<maxseq>"` (the upper bound `trim/4` never needed — it uses only `MINID`/the lower floor);
- **And** the inclusive/exclusive edge at the exact `ms` is per Arm 2's ruling (a closed `[t0, t1]` inclusive `to`, or a half-open `[t0, t1)` exclusive, or a `[t0, ∞)` open upper);
- **And** NO raw `min_for/1` integer (a snowflake) is handed to the wire — the bound is always `ms-seq` (INV-BOUND).
- **Invariants:** EMQ3.6-INV-BOUND (the shipped floor + the new inverse; never a raw integer to the wire; the edge exact).
- **Liveness (no vacuous pass):** US2 MUST assert the EXACT-`ms` edge on BOTH bounds — a `t0` record IN the lower edge, a `t0 - 1ms` record OUT (the floor); the upper edge per Arm 2 (a `t1` record IN for an inclusive `to`, a `t1 + 1ms` record OUT). A bound check that never tests the exact-`ms` boundary proves nothing about the floor/inverse precision.

## US3 — Hydration: a stream tail folds into an `EchoStore.Table` holding per key the newest-mint-id value (newer-wins, no compactor)

**As** a store Table loader warming config / positions / a hydration table from a recorded event stream,
**I want** to fold a stream tail into the Table so each key holds the value of its newest record,
**so that** the Table is a changelog snapshot of the stream tail — latest-value-per-key — without a background compactor.

- **Given** a stream with K `EVT` records across D distinct keys, each key receiving ≥2 records at distinct, KNOWN mint instants (the tail mint-ordered),
- **When** the hydration folds the tail into an `EchoStore.Table` (Arm 3's surface — a one-shot `hydrate_from_stream/_` or a supervised hydrator; Arm 4's source — the live tail or the merge-read deep source),
- **Then** the Table holds, for each key, the value of the record with the MAXIMUM branded `EVT` mint id (newer-wins by mint order — the LAST write per key in the mint-ordered fold wins, versioned by the branded `EVT` id via `Table.put/4`);
- **And** there is NO background compaction — the fold is a one-pass tail read + per-key versioned write;
- **And** the source stream is READ-ONLY to the hydrator (no `XADD`/`XTRIM` of the source); the payloads stay claims-only.
- **Invariants:** EMQ3.6-INV-HYDRATE (per-key newest-mint-id), EMQ3.6-INV-NOCOMPACTOR (no compaction; source read-only; claims-only).
- **Liveness (no vacuous pass):** US3 MUST fold ≥2 records per key (so newer-wins ACTUALLY fires — a key receiving a second, NEWER write) and assert `Table.fetch(name, key)` returns the NEWEST record's value — NOT an earlier one, NOT a later phantom. A hydrate of one record per key proves nothing about newer-wins. The tail is mint-ordered but the KEYS interleave, so the fold must resolve each key to its own newest record across the interleave.

## US4 — The fence composition: hydrate-then-fence equals loader truth

**As** the operator of a hydrated Table,
**I want** a post-hydrate admission through the staleness fence to win over a stale hydrated value,
**so that** the hydrate is a warm-start and the steady-state truth is the fence's — hydrate-then-fence equals loader truth.

- **Given** a Table hydrated to value V1 (mint id m1) for a key (US3),
- **When** a newer value V2 (mint id m2 > m1) is admitted through the fence path — a fresh `Table.put/4` with the newer branded version, OR a `:tracking` invalidation push (from a Valkey write to the matching `ecc:{table}:` key) that drops the stale L1 row so the next `fetch` reloads,
- **Then** the Table holds V2, never the stale hydrated V1 (newer-wins / the L1 drop);
- **And** a STALE admission V0 (mint id m0 < m1) LOSES — `fetch` still returns V1 (newer-wins refuses the older);
- **And** the Table after hydrate + the fence holds the SAME per-key latest value a fresh loader would compute (loader truth).
- **Invariants:** EMQ3.6-INV-FENCE (a post-hydrate admission through the fence wins over a stale hydrated value).
- **Liveness (no vacuous pass):** US4 MUST run a REAL fence admission (a newer `put/4` or a `:tracking` invalidation + reload) and assert the NEWER value reads back AND a stale admission LOSES (both directions) — a fence check that never admits a newer value, or never refuses an older one, proves nothing about the staleness fence. The `:tracking` lane is the SHIPPED fence (`arm_tracking/2` `table.ex:564`); hydration seeds the table the fence guards, it adds no new fence.

## US5 (conditional — Arm 3 supervised only) — A supervised hydrator advances its cursor only after the write; a crash re-hydrates harmlessly

**As** the operator of a continuous hydrator,
**I want** the cursor to advance only after the Table write succeeds, and a crash to re-hydrate harmlessly,
**so that** no record is lost, double-counted, or phantomed across a crash — the two-phase-write atomicity holds.

- **Given** a SUPERVISED hydrator (Arm 3 Arm-B — a standing tailer with a "hydrated up to record X" cursor) folding a tail into a Table,
- **When** the hydrator crashes BETWEEN a Table write and the cursor advance, then restarts,
- **Then** it re-hydrates the un-acknowledged record and the Table holds the SAME per-key latest value (no loss, no double-count, no phantom — newer-wins makes the re-write a no-op-by-comparison, the equal mint id losing);
- **And** the cursor advances ONLY after the Table write for that record succeeds (the write precedes the advance — the emq3.5 R-1 ordering, mirrored).
- **Invariants:** EMQ3.6-INV-CURSOR (cursor-after-write, idempotent-on-replay).
- **Liveness (no vacuous pass):** US5 MUST genuinely interrupt the hydrator between the write and the advance (not merely re-run a clean fold) and assert identical per-key latest values after restart — a "crash" check that never interrupts mid-cycle proves nothing about the two-phase-write atomicity. **IFF Arm 3 rules the ONE-SHOT shape, US5 is VACUOUS and DROPPED** (no cursor exists — the caller folds a bounded tail once, the two-phase-write hazard does not arise).

## US6 — The bus surface stays additive, the engine untouched, the boundary two-app

**As** the maintainer of the wire and the engine,
**I want** the time-travel read additive over the shipped stream surface and the hydration through the public Table API,
**so that** the wire stays frozen, the engine stays untouched, and the diff stays reviewable inside `{echo_mq, echo_store}`.

- **Given** the rung adds the time-travel read (bus-side) + the hydration (store-side),
- **When** the diff is inspected,
- **Then** the bus-side `EchoMQ.Stream` append/trim/archive-cache surface is BYTE-FROZEN (only the additive time-travel read + the upper-bound math added); `echo_wire` is EMPTY-diff; `@wire_version` is `echomq:2.4.2`; `grep -c redis.call` on the bus diff = 0; `keyspace.ex` (both apps) EMPTY-diff;
- **And** the hydration reads through the PUBLIC `EchoStore.Table` API (`put/4`, `fetch/3`) + (iff Arm 4) `StreamArchive.merge_read/5` — the native engine internals (`volume_server.ex`/`store.ex`/`reader.ex`/`streamer.ex`/`segment.ex`) EMPTY-diff; the Rust `echo_graft` untouched; `mix.lock` unchanged (INV8);
- **And** no third app (`codemojex`/`echo_bot`) is touched; the diff is purely `{echo_mq, echo_store}`;
- **And** the label climbs additively per touched app (`echo_mq` 2.6.4 → 2.6.5; `echo_store` 2.0.0 → 2.0.1 IFF a new public surface).
- **Invariants:** EMQ3.6-INV-BOUNDARY (two-app; engine untouched), EMQ3.6-INV-ADDITIVE (additive minor; the label).
- **Liveness (no vacuous pass):** US6 is proven by the actual `git diff` (EMPTY where claimed, additive-only where a change lands), `grep -c redis.call` = 0, and the `@wire_version`/`mix.lock` constants byte-unchanged — not by assertion. The net-zero spot-check git-verifies the prior 78 conformance scenarios byte-unchanged (IFF Arm 5 lands a scenario, the prior 78 stay byte-frozen and ONLY the new one is added).

## EMQ3.6-US-GATE — the standing two-app gate + the determinism posture

**As** the Director accepting emq3.6 at the boundary,
**I want** both app gate ladders green on Valkey 6390, the determinism posture matched to the Arm-3 risk tier, and honest-row reporting,
**so that** the rung is shippable by the text alone, not by re-reading the diff.

- **Given** the two-app rung (`echo_mq` time-travel + `echo_store` hydration),
- **When** the gate runs,
- **Then** the BUS ladder is green — `valkey-cli -p 6390 ping` → `PONG`; `TMPDIR=/tmp mix compile --warnings-as-errors`; `TMPDIR=/tmp mix test --include valkey` (the stream suites + the additive time-travel read); `EchoMQ.Conformance.run/2` → `{:ok, 78}` (FROZEN) or `{:ok, 79}` (IFF Arm 5 landed a time-travel scenario, the prior 78 byte-unchanged, both pins re-pinned);
- **And** the STORE ladder is green — `valkey-cli -p 6390 ping` → `PONG`; `TMPDIR=/tmp mix compile --warnings-as-errors`; `TMPDIR=/tmp mix test --include valkey` (the NEW hydration suite — INV-HYDRATE/NOCOMPACTOR/FENCE positive, + INV-CURSOR iff supervised);
- **And** the determinism posture matches Arm 3 — IFF Arm 3 rules a SUPERVISED hydrator (a process + id-minting in setup), the ≥100 determinism loop runs over the store-side hydration suite (the same-ms branded-id mint hazard live; the loop OWNS the machine); ELSE (one-shot) a multi-seed sweep + an honest determinism-posture statement;
- **And** the claims are against Valkey on 6390 (honest-row reporting — a host without Valkey runs the probes elsewhere and reports them as that row, never the truth row).
- **Invariants:** INV-TT / INV-BOUND / INV-HYDRATE / INV-NOCOMPACTOR / INV-FENCE / (INV-CURSOR iff supervised) / INV-BOUNDARY / INV-ADDITIVE (the runnable checks across both apps).
- **Liveness (no vacuous pass):** the gate must actually RUN both ladders on Valkey 6390 and (iff supervised) the ≥100 loop owning the machine; the conformance run prints its line count and returns `{:ok, n}` on the truth row. **Apollo is MANDATORY IFF Arm 3 rules a SUPERVISED hydrator** (a new process + a durable cursor — the post-build reconcile across both apps + the §11.2 adversarial verification before the ship); on a one-shot NORMAL outcome Apollo is an optional fast-finisher.

## Coverage map (every Deliverable → its story → its invariant(s); completion provable from the text alone)

| Deliverable | Story | Invariant(s) |
|---|---|---|
| **1 · The time-travel window read** (bus-side, `EchoMQ.Stream`) | US1 | EMQ3.6-INV-TT (window == id-filter), EMQ3.6-INV-ADDITIVE (no Lua) |
| **2 · The window bound math** (the shipped floor + the new upper inverse) | US2 | EMQ3.6-INV-BOUND (the floor + the inverse; never a raw integer; the edge exact) |
| **3 · The stream-tail hydration into a Table** (store-side, newer-wins) | US3 | EMQ3.6-INV-HYDRATE (per-key newest-mint-id), EMQ3.6-INV-NOCOMPACTOR (no compaction; source read-only) |
| **4 · The fence composition** (hydrate-then-fence == loader truth) | US4 | EMQ3.6-INV-FENCE (a post-hydrate admission wins over a stale value) |
| **5 · The supervised hydrator's two-phase write** (conditional — Arm 3 supervised) | US5 | EMQ3.6-INV-CURSOR (cursor-after-write, idempotent-on-replay) — VACUOUS if one-shot |
| **6 · The two-app boundary + the engine byte-freeze** | US6 | EMQ3.6-INV-BOUNDARY (two-app; engine untouched), EMQ3.6-INV-ADDITIVE (the label) |
| **The standing two-app gate + the determinism posture** | EMQ3.6-US-GATE | INV-TT / INV-BOUND / INV-HYDRATE / INV-NOCOMPACTOR / INV-FENCE / (INV-CURSOR iff supervised) / INV-BOUNDARY / INV-ADDITIVE |

**The Arms shape the acceptance (the Director rules — the invariants are fixed, the realization is the Arm):** Arm 1 (scope) rules whether US1–US6 ship as ONE rung or SPLIT (US1/US2 emq3.6a, US3–US6 emq3.6b); Arm 2 (the read surface) rules US1/US2's surface name + the window semantics (closed `[t0,t1]` vs half-open `[t0,∞)` vs `nil`-open upper); Arm 3 (the hydration mechanism — TIER-SETTING) rules US3's surface (a one-shot `hydrate_from_stream/_` vs a supervised hydrator) and whether US5/INV-CURSOR binds + Apollo is mandatory + the ≥100 loop runs; Arm 4 (the source) rules US3's source (the live tail vs the merge-read deep source); Arm 5 (the conformance posture) rules whether US1 carries a bus-side conformance scenario (78 → **79**) or the bus conformance stays FROZEN at 78 + the new store-side hydration suite (forced). None re-opens an invariant — each makes "done" concrete.
