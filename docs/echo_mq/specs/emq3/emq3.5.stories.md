# EMQ3.5 — stories (S3 the memory, part 1 — THE ARCHIVE: a store-side fold consumer, a merge-read over `W`, box-loss restore)

> The acceptance face of [`emq3.5.md`](emq3.5.md) (the body is authoritative — if a story disagrees with the body, the body wins). Every Deliverable becomes a Connextra user story with concrete Given/When/Then acceptance (Gherkin/BDD); each names the invariant(s) it exercises; the Coverage map at the foot proves every Deliverable traces to a story. **This is a TWO-APP rung (`echo_mq` + `echo_store`, Operator-ruled D-1, HIGH risk).** The DESIGN is RULED by the echo-bus-v3 consolidation (the six convergences + EBV3-9/10 — [`../../kb/echo-bus-v3/echo-bus-v3.consolidated.md`](../../kb/echo-bus-v3/echo-bus-v3.consolidated.md) §2/§8), NOT re-opened; the five **Arms** are RULED (D-3, [`../progress/emq3-5.progress.md`](../progress/emq3-5.progress.md): Arm 1 → a SUPERVISED store-side GenServer `EchoStore.StreamArchive.Driver` · Arm 2 → a TICK cadence over the pure `.Core` · Arm 3 → the suite `EchoStore.StreamArchiveTest` · Arm 4 → BUILD the `:archived` cache key, conf 77 → **78** · Arm 5 → OFFLINE local-restore in-suite + live-Tigris `:tigris`-tagged) and the increment is BUILT. The stories are CALIBRATED to the as-built; where an Arm shaped the acceptance it is named inline (the ruling sharpened the story, never re-opened the invariant).
>
> **The standing liveness law (the gate-must-exercise-its-outcome rule).** Each archive story is a POSITIVE proof: a present precondition (records appended / a fold-then-trim cycle run / a box dropped) MUST run the operation and assert the OBSERVABLE outcome — the no-loss invariant is proven by every trimmed record actually READING BACK from the archive (not "the fold returned `:ok`"); the merge-read is proven by the union being EXACTLY the original records, none missing (no gap) and none doubled (no overlap); box-loss restore is proven by the archive reading IDENTICALLY after the local CubDB is genuinely dropped and re-opened. **A vacuous pass is a LOUD failure, never a silent green (the TRD.9.1 false-green class):** a fold scenario that trims nothing and asserts "nothing was lost," a merge-read check that never folds-then-trims so `W` is never mid-stream, a box-loss check that never drops the dir — each proves nothing. **The no-loss invariant (US1) is proven by a real trim AND a real archive read-back in the SAME assertion** (the record gone from the live stream AND present in the engine), precisely because folding nothing proves nothing about durability and trimming nothing proves nothing about the ordering.
>
> **The determinism posture (the load-bearing difference from emq3.4).** emq3.5 is a PROCESS + an at-rest engine write + (in test setup) id-minting — the HIGH-risk trigger set. The fold itself mints NO ids (it folds the writer's already-minted `EVT` ids), but the suite SETUP mints `EVT` ids to build a slice — so the same-millisecond mint hazard IS live in setup. The posture is therefore the **≥100 determinism loop over the store-side fold suite** (the program law's process/engine/at-rest-write + id-minting default), NOT a multi-seed sweep. Box-loss restore (US4) is unit-testable OFFLINE (the `durability_test.exs` precedent); the live-Tigris path is `:tigris`-tagged (Arm 5). Stated in EMQ3.5-US-GATE. **Risk is HIGH (a new cross-app surface + a new supervised process + a durable at-rest write); Apollo is MANDATORY** — the post-build reconcile across BOTH apps + the §11.2 adversarial verification + the Director's fold-then-trim mutation battery before the ship.

---

## US1 — Fold-before-trim: a record is archived durably BEFORE it is trimmed, so no record is ever lost (the no-loss invariant)

**As an** operator of a deep-history event stream (a recorded game log, an audit trail) bounded in RAM but whole in history, **I want** every record committed durably into the engine BEFORE the live stream trims it — and NEVER the reverse — **so that** bounded memory (the trim) and deep history (the archive) coexist with ZERO data loss, the one ordering `XTRIM`'s removed-count-only reply makes the sole defense (F-2, the invariant the rung exists to prove, INV1).

- **Exercises:** EMQ3.5-INV1 (fold-before-trim, the load-bearing no-loss invariant), EMQ3.5-INV2 (segment fold == stream slice).

```gherkin
Given a RESP3 connection to Valkey on 6390 and a stream emq:{q}:stream:s with K EVT records appended via EchoMQ.Stream.append/4
  And a started native EchoStore.Graft Volume (under EchoStore.Graft.VolumeSup) bound to that archived stream
When the store-side fold consumer runs ONE fold-then-trim cycle for a prefix of the stream
Then the prefix records are FIRST committed into the engine at the @archive_base page range (VolumeServer.commit/3 → {:ok, lsn})
  And W (the archive frontier) is advanced to the branded EVT id of the highest-folded record
  And ONLY THEN are the prefix records trimmed from the live stream (EchoMQ.Stream.trim/4 → {:ok, removed_count})
  And every trimmed record READS BACK from the archive (the @archive_base range, in mint order) — none lost (INV1)
  And the folded page payload's branded ids EQUAL the trimmed slice's branded ids in mint order (segment fold == slice, INV2)
```

- **Liveness (no vacuous pass):** US1 MUST append K records, fold-then-trim a REAL prefix, and assert in the SAME scenario that the trimmed records are GONE from the live stream **and** present in the engine — folding nothing proves nothing about durability, trimming nothing proves nothing about the ordering. The Director's **fold-then-trim mutation battery** REORDERS the steps (trim-before-fold) and asserts the suite CATCHES the loss (a record trimmed before it is folded is irrecoverable, F-2 — the mutant FAILS US1).
- **The ordering note (F-2):** `XTRIM` returns only a removed-count — it cannot hand back what it deleted. So the fold MUST precede the trim; the consumer OWNS both calls (read-slice → commit → advance-W → trim) in ONE process precisely so the ordering is enforceable, never split across a bus event the store cannot observe (EBV3-3 — no injected bus callback).

## US2 — The merge-read returns archived ∪ live-tail, no gap / no overlap, split on `W`

**As a** reader of a deep stream, **I want** a read spanning the trim boundary to return the UNION of the archived records (in the engine) and the live tail (on the wire) — every record present exactly once, none missing (no gap), none doubled (no overlap) — split on `W` (the branded `EVT` id of the highest-folded record) — **so that** deep history reads seamlessly beside the live tail as ONE logical stream (the order theorem extended to the log, INV3).

- **Exercises:** EMQ3.5-INV3 (the merge-read property — no gap / no overlap), EMQ3.5-INV6 (`W` is a branded `EVT` id, never the integer `head_lsn`).

```gherkin
Given a stream with K EVT records, of which a prefix has been fold-then-trimmed (so W is mid-stream — records ≤ W in the engine, records > W on the wire)
When a merge-read is issued over the full range
Then it returns EXACTLY the K records in mint order
  And every record appears ONCE — none missing (no gap below or at W) and none doubled (no overlap at the W seam)
  And records with branded id ≤ W are read from the engine's @archive_base range
  And records with branded id > W are read from the live stream (XRANGE, the live tail; W's xadd_id maps to the lower bound via Stream.Id.xadd_id/1)
When a merge-read is issued over a range fully BELOW W
Then it hits ONLY the engine (the archive) and returns the in-range archived records
When a merge-read is issued over a range fully ABOVE W
Then it hits ONLY the wire (the live tail) and returns the in-range live records
```

- **Liveness (no vacuous pass):** US2 MUST fold-then-trim a prefix so `W` is genuinely MID-STREAM (not at the start, where the merge-read degenerates to a pure live read, and not at the end, where it degenerates to a pure archive read) — the no-gap/no-overlap property is only exercised when the read STRADDLES `W`. A merge-read over an empty archive (`W` = `:empty`) proves nothing about the seam.
- **`W` is a branded id, not an LSN (INV6, F-1):** US2 MUST assert `W` is a 14-byte branded `EVT` id (`EchoData.BrandedId.valid?/1` true, `Stream.Id.evt?/1` true), NOT the integer `head_lsn`. The Director's mutation battery substitutes the integer `head_lsn` for `W` and asserts the merge-read no-gap/no-overlap assertion CATCHES the type error (an LSN compared against a branded id splits at the wrong seam).

## US3 — The archive lands at a reserved high page range `@archive_base`, disjoint from every business page (no page collision)

**As the** native-engine page store, **I want** the archive's pages at a per-stream `@archive_base = :erlang.bsl(1, 49)` reserved high range on the engine's flat page axis, DISJOINT from any business page a workload writes through `commit/3` — **so that** an archive page can NEVER overwrite a data page (the page axis is multiplexed, GC indifferent to which range), the page payload carrying the branded `EVT` id, branded-id-monotone by the order theorem (INV4, F-LS-A). *(D-5: the original reserved-range exemplar — the dropped outbox adapter's `@obx_base = :erlang.bsl(1, 48)` — is gone this window (no backward compat); the archive owns the reserved-range discipline natively against the engine's own page axis, so disjointness is stated against a business page, not the vanished outbox range.)*

- **Exercises:** EMQ3.5-INV4 (`@archive_base` disjoint from every business page), EMQ3.5-INV2 (the page index is branded-id-monotone — contiguous by the order theorem).

```gherkin
Given the native engine's flat page axis (Store keys {:page, page_idx, lsn}; commit/3 stages %{page_idx => binary}; a business page is a low index a workload writes)
When the archive folds records into a Volume at @archive_base = :erlang.bsl(1, 49)
Then @archive_base is a high range DISJOINT from every business page (no archive index equals a low business page index)
  And a Volume carrying BOTH low-index business pages (staged via the PUBLIC commit/3) AND archive pages reads each range back correctly (idx >= @archive_base filters the archive; low indices select the business pages)
  And the n-th folded record lands at a contiguous @archive_base-relative index, branded-id-monotone (the order theorem)
  And each archive page payload carries the record's branded EVT id + its claims-only fields
```

- **Liveness (no vacuous pass):** US3 MUST fold archive pages INTO a Volume that ALSO carries low-index business pages (via the public `commit/3`) and assert each range reads back UN-corrupted — a disjointness check on an empty Volume proves nothing. The Director's mutation battery sets `@archive_base` DOWN into the business page range and asserts the collision is CAUGHT (an archive page overwrites a business page, or vice versa — the mutant FAILS US3).

## US4 — Box-loss restore: drop the local CubDB, restore, the archive reads identically

**As a** durability operator, **I want** the archive to survive total box loss — drop the local CubDB, re-open the Volume (lazily re-fetching `segments/{SEG}` from Tigris where `remote_cfg` is set), and read the archive back IDENTICALLY — **so that** deep history is durable beyond a single node, the engine's existing Tigris-streaming property carrying the archive for nearly free (the fold being a property of the engine already in place, INV5, EBV3-9).

- **Exercises:** EMQ3.5-INV5 (box-loss restore — drop → restore → identical reads).

```gherkin
Given a Volume with K records folded into its @archive_base range (and, with remote_cfg, streamed to Tigris as segments/{SEG})
When the local CubDB data dir is DROPPED (total box loss simulated)
  And the Volume is re-opened from the same data dir (offline path) OR re-fetched from Tigris (live path, :tigris-tagged)
Then the archive reads back IDENTICALLY — the same K branded EVT ids, the same payloads, in mint order
  And a merge-read after restore returns the same archived ∪ live-tail union as before the loss
```

- **Liveness (no vacuous pass):** US4 MUST genuinely DROP the local CubDB dir (not merely re-read a live handle) and re-open/re-fetch before asserting identical reads — a "restore" check that never drops the dir proves nothing about box loss. The OFFLINE local-restore path follows the `durability_test.exs` precedent (the engine's pure restore logic, no live S3); the LIVE-Tigris path is `:tigris`-tagged and run only when a bucket is configured (the determinism posture, Arm 5, states the cut).

## US5 — The bus-side surface stays byte-frozen and the native engine stays UNTOUCHED (the archive is additive + store-side)

**As the** keeper of the certified wire and the COEXIST engine boundary, **I want** the archive to keep the shipped stream verbs / `echo_wire` byte-frozen and to edit NO engine internal — adding ONLY the three additive `:archived` cache fns bus-side (Arm 4), folding via the engine's PUBLIC `commit/3` and reading/trimming via the shipped stream verbs, the net-new fold/landing/merge code landing as NEW store-side modules — **so that** the v2 master invariant binds the bus unchanged, the certified wire stays frozen, and the native engine (the production-default durability, EBV3-9) carries the archive as a new CONSUMER, never an engine edit (INV7, INV8, EBV3-2).

- **Exercises:** EMQ3.5-INV7 (the bus-side surface byte-frozen), EMQ3.5-INV8 (the engine COEXIST-canonical + untouched), EMQ3.5-INV10 (the label steps within-family, the wire frozen).

```gherkin
Given the SHIPPED bus surface (EchoMQ.Stream append/4, append_id/5, append_batch/4, read/3..6, trim/4, stream_key/2; EchoMQ.StreamRetention; every @-script) and the SHIPPED engine internals (volume_server.ex, store.ex, reader.ex, streamer.ex, segment.ex)
When emq3.5 builds the archive
Then the shipped bus-side stream verbs (append/4, append_id/5, append_batch/4, read/3..6, trim/4, stream_key/2) are byte-identical to HEAD (the archive READS/TRIMS via them) — the ONLY bus-side change is ADDITIVE: the three new EchoMQ.Stream fns put_archived/4, get_archived/3, clear_archived/3 + the stream_archived conformance scenario + the label (Arm 4)
  And echo_wire is UNTOUCHED (git diff EMPTY); @wire_version reads echomq:2.4.2; keyspace.ex is unedited
  And grep -c redis.call on the bus-side lib/ diff = 0 (NO new Lua — the cache is a stock SET/GET/DEL)
  And the engine internals are byte-identical to HEAD (the fold targets the PUBLIC commit/3 — the archive is NEW store-side modules + the @archive_base landing, not an engine edit)
  And the Rust echo_graft_backend is untouched; mix.lock is unchanged (cubdb already a declared echo_store dep — no new dependency)
  And the bus label echo_mq/mix.exs steps 2.6.3 → 2.6.4 (the changed app); the store echo_store/mix.exs is UNCHANGED 2.0.0; {emq}:version reads echomq:2.4.2
```

- **Liveness (no vacuous pass):** US5 is proven by the actual `git diff` (EMPTY where claimed, additive-only where a change lands), `grep -c redis.call` on the bus-side diff = 0, and the `@wire_version` / `mix.lock` constants byte-unchanged — not by assertion. The Director's net-zero spot-check git-verifies the prior 77 conformance scenarios byte-unchanged (IFF the `:archived` key lands, the prior 77 stay byte-frozen and ONLY the new scenario is added — Arm 4) and the engine internals EMPTY-diff.

## EMQ3.5-US-GATE — the standing two-app gate + the determinism posture (HIGH risk, Apollo mandatory)

**As the** Director, **I want** BOTH app gate ladders green (the bus's `mix test --include valkey` + `Conformance.run/2 → {:ok, 78}` on Valkey 6390; the store's `mix test` + the NEW archive suite `EchoStore.StreamArchiveTest`), the **≥100 determinism loop** over the store-side fold suite (a process + an at-rest write + id-minting setup — the HIGH-risk default), box-loss restore proven (offline + `:tigris`-tagged live per Arm 5), and Apollo's mandatory post-build reconcile + adversarial verification across BOTH apps — **so that** the archive ships proven, the no-loss invariant adversarially confirmed, and the two-app boundary honored (the dependency law respected, not bent — code where it must live).

- **Exercises:** EMQ3.5-INV9 (the two-app conformance/test posture), and the standing two-app gate over INV1–INV10.

```gherkin
Given the as-built archive across echo_mq + echo_store
When the Director re-runs BOTH app gate ladders independently on Valkey 6390
Then the bus's TMPDIR=/tmp mix test --include valkey is green AND Conformance.run/2 returns {:ok, 78} (the Arm-4 :archived cache scenario landed — the prior 77 byte-unchanged + both pins re-pinned)
  And the store's TMPDIR=/tmp mix test is green AND the NEW archive suite EchoStore.StreamArchiveTest proves INV1–INV6 POSITIVELY
  And the ≥100 determinism loop over the store-side fold suite is green (for i in $(seq 1 150); do TMPDIR=/tmp mix test || break; done — the loop OWNS the machine, no concurrent liveness server)
  And box-loss restore is proven (the offline local-restore path green; the :tigris-tagged live path green where a bucket is configured — Arm 5)
  And the Director's fold-then-trim mutation battery catches every loss mutant (trim-before-fold; @archive_base dropped DOWN into the business page range; W = the integer head_lsn)
  And Apollo's post-build reconcile (does the as-built satisfy every promise across BOTH apps?) + the §11.2 adversarial verification (the no-loss probe, the @archive_base disjointness probe, the merge-read no-gap/no-overlap probe, the W-is-a-branded-id probe, the box-loss probe, the byte-freeze probe) PASS before the Director ships
```

- **Determinism posture (stated honestly):** emq3.5 is a PROCESS + an at-rest engine write; the suite SETUP mints `EVT` ids (to build a slice), so the same-millisecond mint hazard IS live — the **≥100 loop is RUN** over the store-side fold suite (NOT a multi-seed sweep — running only a sweep would UNDER-test a rung that mints ids in setup and writes at rest). The fold itself mints no ids (it folds the writer's); box-loss restore is unit-testable offline (the engine's pure restore logic, the `durability_test.exs` precedent). The HIGH risk is absorbed by Apollo-mandatory + the Director's DEEPENED verify (the ≥100 loop + the fold-then-trim mutation battery + the two-app boundary grep + a box-loss adversarial probe).
- **Risk: HIGH** (a new cross-app surface + a new supervised fold-consumer process + a durable at-rest engine write + the FIRST stream rung to reach store-side). **Apollo is a SHIP PRECONDITION** on this rung.

---

## Coverage map (every Deliverable → its story → its invariant(s); completion provable from the text alone)

| Deliverable (body Goal) | Story | Invariant(s) |
|---|---|---|
| **1 · The store-side fold consumer** (the fold-then-trim cycle) | US1 | EMQ3.5-INV1 (fold-before-trim), EMQ3.5-INV2 (fold == slice) |
| **2 · The archive landing** (`@archive_base` disjoint from every business page) | US3 | EMQ3.5-INV4 (disjointness), EMQ3.5-INV2 (branded-id-monotone) |
| **3 · The merge-read over `W`** (archived ∪ live-tail, no gap/overlap) | US2 | EMQ3.5-INV3 (merge-read property), EMQ3.5-INV6 (`W` a branded id, not `head_lsn`) |
| **4 · Box-loss restore** (drop → restore → identical) | US4 | EMQ3.5-INV5 (box-loss restore) |
| **5 · The two-app conformance/test posture** | EMQ3.5-US-GATE | EMQ3.5-INV9 (two-app posture), EMQ3.5-INV7/INV8/INV10 (byte-freeze, engine untouched, the label) |
| **The bus-side byte-freeze + the engine COEXIST boundary** | US5 | EMQ3.5-INV7 (bus byte-frozen), EMQ3.5-INV8 (engine untouched), EMQ3.5-INV10 (the label) |
| **The standing two-app gate + the determinism posture** | EMQ3.5-US-GATE | INV1–INV10 (the runnable checks across both apps) |

**The Arms shaped the acceptance (RULED D-3 — the invariants are fixed, the realization sharpened):** Arm 1 (placement) ruled the US1 consumer a SUPERVISED `EchoStore.StreamArchive.Driver`; Arm 2 (trigger) ruled a TICK cadence over the pure `.Core`; Arm 3 (posture) ruled the US-GATE store-side suite `EchoStore.StreamArchiveTest`; Arm 4 (the `:archived` cache) ruled BUILD — US2/US-GATE carry the bus-side `stream_archived` conformance scenario (77 → **78**); Arm 5 (the box-loss cut) ruled US4's live-Tigris path `:tigris`-tagged + the offline local-restore in-suite. None re-opened an invariant — each made "done" concrete.
