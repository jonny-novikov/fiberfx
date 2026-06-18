# codemojex Broadcast System — BCS architecture + Valkey/data-layer design (v2)

> **Status:** DESIGN v2 (Venus). DESIGN/SPEC ONLY — no production code, no git. The rung ladder (§7) and
> the spec triads under `docs/codemojex/notifications/specs/` derive from this document. Mars builds to the
> per-rung brief.
> **v2 supersedes v1.** KEPT from v1: the reconcile (§1) and **D-1 = Valkey `EchoMQ.Throttle`** (Operator
> ruled the cluster-wide 27/s server-clock token bucket) + the aggregate-first principle. SUPERSEDED:
> v1's persistence model (Postgres row-per-delivery + counters) → the **BCS aggregate / compaction** model
> below (§2–§5).
> **Substrate facts** are reconciled at the cited `file:line`; **Telegram limits** grounded against the Bot
> API docs (§9). Unshipped surface is forward-tense ("the rethink adds…").

## 0. Scope and intent

Rethink the codemojex notification pipeline (scheduled Telegram sending) as a **production-grade Broadcast
system built to the BCS discipline** — branded-id entities, components-as-data, the system-as-process owning
gated private state (`docs/echo/mesh/mesh.8.1.md`; `echo/apps/echo_data/lib/echo_data/bcs/`). Two gaps drive
the original work; v2 reframes the whole pipeline around **broadcasts to large audiences**:

1. The global send cap is **30/s = 100%** of Telegram's broadcast limit, in-memory **per-node** — the
   "global" cap is not cluster-wide.
2. Deliveries are **classified but never persisted** — the `message_id` on success and the structured 403
   `reason` are discarded to a log; nothing to observe, count, or feed back to the audience.

The v2 rethink:
- **27/s cluster-wide cap** via a Valkey server-clock token bucket (`EchoMQ.Throttle`), composed with the
  per-chat 1/s fairness (D-1, ruled).
- A **`Broadcast` is an entity with a lifecycle** (a state machine) that **aggregates** each recipient's
  `(result, error)` as deliveries report, then **compacts** the per-recipient results — chronologically,
  for free, because delivery ids are time-ordered branded snowflakes — into **ONE Result row** at the end
  of the template's `period`. 100k deliveries become **1 archived row per broadcast**, plus a small
  hot **failures** subset and long-lived **counters**.
- **`RecipientGroup`** resolves the audience AND **receives failure feedback** — a 403 suppresses that user.

---

## 1. Reconcile — the as-built surface (ground truth) [KEPT from v1]

Every claim is read from the tree. Citations are `file:line`.

### 1.1 codemojex notification pipeline (today)

| Surface | What it is | Key facts |
|---|---|---|
| `Codemojex.Notifier.notify/3` | Enqueue side | `notifier.ex:24` — mints a `"NOT"` branded id, JSON `%{chat, text, opts, id, attempt: 1}`, enqueues on a **fair lane per chat** via `EchoMQ.Lanes.enqueue/5` (`notifier.ex:30`). `{:ok, job_id}`, no network I/O. |
| `Codemojex.NotificationWorker.handle/1` | Consumer (queue `cm.notify`) | `notification_worker.ex:37` — decodes; `RateLimiter.take(chat)` → `:ok` deliver, `{:wait, ms}` re-enqueue via `EchoMQ.Jobs.enqueue_in/5` (`:88`) + ack (defer, never block/drop). On deliver, `EchoBot.deliver/3` → `:ok` ack · `{:retry, reason}` capped backoff to `@max_attempts 6` (`:25`,`:67`) · `{:drop, reason}` **ack-and-drop, only a `Logger.warning`** (`:77-79`). |
| `Codemojex.RateLimiter` | In-memory token bucket | `rate_limiter.ex` — a **single GenServer** (`:30`). Global default **30/s burst 30** (`:48-52`) **AND** per-chat **1/s burst 3** (`:54-55`); a send needs BOTH (`:67-78`). Lazy refill from `System.monotonic_time` (`:107`) — **local clock, per-node**. Idle per-chat buckets evicted (`:102-105`). |
| `Codemojex.EchoBot.deliver/3` | Result classifier | `echo_bot.ex:41` — collapses to `:ok \| {:retry, reason} \| {:drop, reason}`. 429/5xx → retry, other 4xx → drop (`:46-49`); Telegram `error_code` 429/5xx → retry else drop (`:52-55`); network → retry (`:58-60`). **Discards `_result` on `:ok` (`:43`) → `message_id` lost.** |
| `Codemojex.Telegram.send_message/3` | Bot API client (`:httpc`) | `telegram.ex:21` — `{:ok, result_map} \| {:error, reason}`. **Success `result_map` carries `message_id`** (`decode_ok` returns Telegram's `result`, `:50-52`). Errors: `{:telegram_status, status, body}` (`:45`) or the Telegram `%{"ok"=>false,"error_code"=>…,"description"=>…}` map (`:53`). |

The two data losses: `echo_bot.ex:43` discards the success `message_id`; `notification_worker.ex:77` logs
(does not persist) the 403 `reason`.

### 1.2 Deployment shape — single-node today, multi-node anticipated

The tree starts ONE `RateLimiter` + ONE of each consumer (`application.ex:21-44`); no libcluster/FLAME dep
(grep found only a comment, `config/prod.exs:4`). **Single-node today.** But multi-node is anticipated: the
Graft committer starts conditionally on a configured volume (`application.ex:99-116`), and `mesh.8.1` names
FLAME elastic workers as first-class. An in-memory global cap is correct on one node and silently wrong on
two — hence D-1 (ruled): a Valkey cluster-wide cap.

### 1.3 The EchoMQ "rate" surface is CONCURRENCY, not THROUGHPUT

`EchoMQ.Lanes.limit/4` (`lanes.ex:216`) is a **concurrency ceiling** (`glimit`/`gactive` — "lowering it
below the live count parks the lane"); conformance: *"the concurrency gate refuses `EMQRATE` at the
ceiling"* (`conformance.ex:102`). `rate_consult` (`:118`) is the in-flight consult-before-claim. `EchoMQ.Meter`
(`meter.ex`) is `:telemetry` only — `rate_limit_hit/2` (`:189`) merely emits. **No server-clock token bucket
exists → the 27/s cap is genuinely new surface.**

### 1.4 The substrate the v2 surface builds on

- **Branded-id contract:** `EchoData.BrandedId.generate!/1` (`branded_id.ex:93`) takes a 3-byte namespace →
  a 14-byte typed, **time-ordered** snowflake (`Snowflake`/`Base62`). `valid?/1` (`:95`), `decode/1` (`:55`).
  Taken brands across `echo/`: `CMD CMT DEL EMS … JOB NOT ORD PRT RND TXN USR …` — v2's new brands below are
  free.
- **Chronological-array carrier — `EchoData.Timeline`** (`timeline.ex`): "time-ordered, concurrently
  writable feed over `:ets` `ordered_set`… **key order IS chronological order**: latest-N, cursor
  pagination, time-window counts are all range operations on the key — no timestamp column, no secondary
  index, **no sort**." `latest/2`, `since/3`, `window_count/3`, `after_cursor/3`. **This is why chronological
  compaction is free.** `EchoData.BrandedChamp` (`branded_champ.ex`) is the persistent-map alternative when
  in-trie placement is part of a cross-runtime contract — heavier; **the compaction array does not need it**
  (the array is written once, read once), so `Timeline` (during the run) → a plain ordered list (the frozen
  Result) is the right pairing.
- **The send-path bus surfaces** (all real): `EchoMQ.Jobs.enqueue_many/4` (`jobs.ex:124`) for fan-out;
  `EchoMQ.Repeat.register/6` (`repeat.ex:58`) for the schedule; `EchoMQ.Flows.add/3` (`flows.ex:219`,
  parent→children) + `children_values/3` (`flows.ex:534` — the fan-in, reading the `:processed` hash, the
  real child result threaded through `Jobs.complete/5` `ARGV[5]`) for the parent/aggregation shape.
- **Inline-Lua path** for the new primitive: `EchoMQ.Connector.eval/5` (`echo_wire/.../connector.ex:65`) +
  `Script.new/2` (`script.ex:13`). The construction client codemojex uses: `EchoWire.Cmd` via
  `Codemojex.Wire.run/2` (`wire.ex:33`).
- **`EchoMQ.Conformance.run/2` is `{:ok, 59}` today** (`conformance_run_test.exs:48`) — any new echo_mq
  scenario re-pins this under the additive-minor law.
- **Postgres** (`Codemojex.Repo`, schemas under `lib/codemojex/schemas/`, the `Store.upsert/3` + `Wallet`
  precedent) is the durable cold store for the compacted Result rows (v2 §4).

---

## 2. The BCS entity / component model

The Broadcast system is a **system in the BCS sense** — a process that owns its private state, gated on a
branded namespace, and the only values crossing its boundary are **identities and messages about
identities** (the law, `mesh.8.1`). Four entities, each a branded identity; their data are plain components
(bundles), never behaviour modules.

### 2.1 Brands (all free — verified against the taken set)

| Entity | Brand | Why | Time-ordering use |
|---|---|---|---|
| `BroadcastTemplate` | **`BTP`** | reusable content + schedule + period | id sorts by creation |
| `Broadcast` | **`BCA`** | one template instance / run | id sorts by run start |
| `BroadcastDelivery` | **`BDV`** | one per recipient message | **id IS the chronological key** → free-order compaction |
| `RecipientGroup` | **`RGP`** | the audience + the failure sink | id sorts by creation |

> Brands are minted with `EchoData.BrandedId.generate!("BTP" | "BCA" | "BDV" | "RGP")`. The `BDV` time
> ordering is load-bearing: compaction reads deliveries in mint order with no sort (§3.3).

### 2.2 `BroadcastTemplate` (`BTP`) — the reusable definition

A component bundle (data only):

| Field | Meaning |
|---|---|
| `id` | `BTP` brand |
| `content` | the message text **with placeholders** (e.g. `"Hi {first_name}, round {round} is live"`) |
| `placeholders` | the declared placeholder keys (so a recipient row supplies the substitutions) |
| `schedule` | scheduling parameters → an `EchoMQ.Repeat` registration (`every_ms`, `first_in_ms`) or a one-shot `enqueue_at` instant |
| `period` | **the compaction window** — after this elapses from a run's start, that run's deliveries compact into the Result and the transient `BDV` records trim. (e.g. `24h`.) |
| `default_opts` | default `sendMessage` opts (`:parse_mode`, `:reply_markup`) |
| `recipient_group` | a **ref** (`RGP` id) to the audience — an identity, never an embedded list (the BCS law) |

A `BTP` is **immutable content + policy**; a run instantiates it into a `BCA`.

### 2.3 `Broadcast` (`BCA`) — the run, a STATE MACHINE that aggregates

The heart of v2. A `BCA` is a template instance whose **state is a lifecycle**, and whose component
**aggregates `(res, err)` per recipient** as deliveries report.

**States (the machine):**

```
 scheduled ──▶ fanning_out ──▶ draining ──▶ compacting ──▶ completed
     │              │              │             │
  (Repeat/        (enqueue_many   (deliveries   (final transition:
   enqueue_at      the recipient   report res/    compact handler runs)
   fires)          children)       err; counters
                                   tick)
```

- **`scheduled`** — registered; the schedule (`Repeat`/`enqueue_at`) has not yet fired.
- **`fanning_out`** — the schedule fired; the recipient list (resolved from `RGP`) is being fanned out as
  per-recipient jobs (`enqueue_many` / a Flow parent→children, §5).
- **`draining`** — fan-out complete; per-recipient `BDV` deliveries are reporting their `(res, err)`; the
  `BCA` aggregates them and the Valkey counters tick.
- **`compacting`** — the **final transition's handler** runs (triggered when all recipients have reported OR
  the template `period` elapses, whichever the run's completion rule, §3.4): it **compacts the per-recipient
  results chronologically into a single array** and writes the Result row.
- **`completed`** — the Result is the durable archive; transient `BDV` records are trimmed; the audience
  feedback (failed group) is applied to `RGP`.

**Aggregation component** (the `BCA`'s private state during `draining`):
- a **running counter set** per `(status, reason)` (mirrored to Valkey for live tiles, §4.2),
- the **in-flight delivery references** (the `BDV` ids reported so far) — the array the compaction reads.

**On the final transition (`compacting`)** a handler folds the reported `BDV` records — in mint order, which
is chronological order (the snowflake property) — into **one array**:

```
result_array = [ (recipient_id, status, message_id, reason?), …chronological… ]
```

→ the **Result is ONE row** (§4.1), not N. The carrier during the run is `EchoData.Timeline` (free
chronological order, range reads); the frozen Result array is a plain ordered list serialized into the row.

### 2.4 `BroadcastDelivery` (`BDV`) — the per-recipient record

The atom of delivery: `(telegram_user_id, status, message_id, reason?)` + its `BDV` id (mint time =
delivery time) + the parent `BCA` ref + `attempt`.

- **Created per message**, as each recipient's send produces a terminal outcome.
- **Batch-written DURING the run** in **configurable batches** (§3.2) for durability — a crash mid-broadcast
  resumes from the last persisted batch, not from zero.
- **Compacted** into the `BCA` Result array after the template `period`, then **transient records trimmed**
  — so the steady state is 1 Result row per broadcast, not 100k `BDV` rows (§3.3).

### 2.5 `RecipientGroup` (`RGP`) — the audience AND the failure sink

The audience component, with **bidirectional** duty:

- **Resolves** to the recipient list a `BCA` fans out to. Kinds: **`[all, admin, group_of_n, from_csv]`**
  - `all` — every known player (resolved from the codemojex player store),
  - `admin` — the admin chat set,
  - `group_of_n` — a bounded subset (e.g. a cohort / sample of N),
  - `from_csv` — an uploaded list of chat ids.
- **Receives failure feedback** — when a `BCA` completes, every recipient whose terminal status was a
  **permanent 403** (`blocked` / `chat_not_found` / `deactivated`) is **suppressed** in (or split into a
  **failed group** off) the `RGP`, so the next broadcast does not re-send to a dead chat. This is the
  audience self-healing the brief asks for: deliverability feeds back into the audience.

> BCS-faithful: a `BCA` references its `RGP` by id; failure feedback is **a message about identities**
> (the suppressed recipient ids), not an object graph. The `RGP`'s suppression set is its own gated state.

---

## 3. Storage mechanics — the "efficiently" mandate

Three lifecycle phases, three storage behaviours; the design target is **100k deliveries → 1 archived row**.

### 3.1 DURING run — batched `BDV` writes (durable in-flight)

As recipients report, `BDV` records accumulate and are **bulk-written in configurable batches** (batch size
a template/config parameter, e.g. 500). Rationale:
- **Durability:** a node crash mid-broadcast loses at most the last unflushed batch; the run resumes from the
  last persisted batch (the `BCA` state + the persisted `BDV` ids reconstruct progress).
- **Efficiency:** one bulk write per batch, not one write per message — O(batch) round-trips, not O(N).
- The in-flight carrier is `EchoData.Timeline` (the `BCA`'s aggregation feed) + the batched durable store
  (Postgres `bulk_insert`, or the Valkey side per D-2 below).

### 3.2 The batch parameter

`batch_size` (default e.g. 500) lives on the `BroadcastTemplate` (or global config). It trades durability
granularity (smaller = less loss on crash) against write amplification (larger = fewer round-trips). At
27/s, a 500-batch flushes ~every 18s — a sensible default; the Operator may tune (D-2).

### 3.3 AFTER template `period` — compact + trim

When the `period` elapses (the `BCA`'s `compacting` transition):
1. **Compact** — fold all `BDV` records for the run, **in `BDV`-id (= chronological) order, no sort**, into
   the single Result array `[(recipient_id, status, message_id, reason?), …]`. `EchoData.Timeline.latest/2`
   / a full range read returns them already ordered.
2. **Write** the Result row (§4.1) — ONE row carrying the array (+ the failures column, §3.4).
3. **Trim** the transient `BDV` records for the run — they are now redundant (the Result is the archive).

**Steady state:** 100k `BDV` records during the ~1h run window → **1 Result row** after the period. The only
unbounded raw growth is the **failures** subset (§3.4 / §6).

### 3.4 Efficient failures-only fetch — the extra column

A naive Result needs a full-array scan to find failures. v2 adds an **extra column on the Result** so
failures extract without touching the 100k-element array:
- a **`failures` jsonb/array column** holding only the failed `(recipient_id, reason)` pairs (typically a
  small fraction of N), **OR** a **partial index `WHERE status = 'failed'`** if the model keeps a queryable
  delivery view.
- **Recommendation:** the **`failures` jsonb column** — it is the hot, actionable subset (it feeds `RGP`
  suppression), it is small (only the bounced recipients), and it extracts with no full-array scan. The full
  chronological array stays the cold archive (rarely read; replay/audit only).

**The completion rule** (when `draining → compacting` fires): either (a) all fanned-out recipients have
reported a terminal `BDV`, or (b) the template `period` elapses with stragglers — whichever first. Stragglers
at period end are recorded `status: timed_out` (a terminal class) so the array is always complete. (D-3.)

### 3.5 Live dashboard — Valkey counters (instant tiles)

Independent of compaction: **Valkey `HINCRBY` counters per `broadcast × status × reason`** are the always-
fresh dashboard tiles, ticked as deliveries report (during `draining`). One `HGETALL` per broadcast renders
its tiles. These are codemojex **application** keys (prefix `cm:bcast:`), NOT the `emq:{q}:` bus grammar
(stated so Mars does not mis-file them under the emq master invariant). Bounded by cardinality: one hash per
broadcast (+ a rollup-by-day hash), TTL'd.

**Three reads, three stores (the CAP-segmented split, `mesh.8.1`):**
- **Valkey counters** = hot, live tiles (availability-first; a lost increment self-heals from the Result).
- **Result `failures` column** = hot, actionable subset (feeds `RGP`).
- **Result chronological array** = cold archive (consistency-first Postgres; replay/audit).

---

## 4. The data model

### 4.1 The compacted Result (cold archive — Postgres)

A new Ecto schema `Codemojex.Schemas.BroadcastResult` + migration. **One row per completed `BCA`.**

| Column | Type | Notes |
|---|---|---|
| `id` | `BCA` brand (PK) | the broadcast id; time-ordered |
| `template_id` | `BTP` brand | which template produced it |
| `recipient_group_id` | `RGP` brand | the audience snapshot ref |
| `state` | text | terminal = `completed` |
| `started_at` / `completed_at` | utc_datetime_usec | the run window |
| `totals` | jsonb | `%{delivered: n, failed: n, timed_out: n}` — the headline tallies (also in Valkey, persisted here at compaction) |
| `deliveries` | jsonb (array) | the **compacted chronological array** `[(recipient_id, status, message_id, reason?), …]` — the cold archive |
| `failures` | jsonb (array) | **the hot actionable subset** — only `(recipient_id, reason)` for failed/timed_out; small; feeds `RGP`; no full-array scan |

**Write:** ONE `Repo.insert` at compaction (O(1) per broadcast). **Reads:** the dashboard's per-broadcast
detail reads `totals`/`failures`; a deep audit reads `deliveries`. No row-per-delivery, no 2.3M-row/day
table.

### 4.2 The Valkey counters (live tiles)

- **Per-broadcast:** `cm:bcast:rollup:{<BCA-id>}` → `HINCRBY` fields `status:delivered`, `status:failed`,
  `status:timed_out`, `reason:blocked`, `reason:chat_not_found`, `reason:deactivated`, … One `HGETALL`
  renders the broadcast's tiles. TTL = the template period + a grace (the live window).
- **Per-day rollup (optional):** `cm:bcast:rollup:{day:<YYYY-MM-DD>}` for cross-broadcast daily tiles.
- Best-effort side-write (a lost `HINCRBY` self-heals — the Result's `totals` is the truth). Written via
  `Codemojex.Wire.run/2` (`EchoWire.Cmd`).

### 4.3 The `BDV` transient store (during run)

Configurable-batch bulk writes (§3.1). Carrier per D-2:
- **Recommendation:** a **lightweight Postgres `broadcast_deliveries` table** (bulk-inserted in batches,
  truncated/trimmed per broadcast at compaction) — durable, and the compaction `GROUP BY`/order read is
  trivial. It exists only for the run's lifetime + `period`, never accumulating across broadcasts.
- Alternative (D-2): a **Valkey list/stream per broadcast** (`cm:bcast:deliv:{<BCA-id>}`, `RPUSH` batches,
  `DEL` at compaction) — keeps the in-flight set off Postgres entirely, at the cost of a Valkey-side read at
  compaction. Either is bounded to the run window.

---

## 5. The send path

Unchanged control discipline; the fan-out is the new shape.

1. **Schedule** — a `BCA`'s schedule rides `EchoMQ.Repeat.register/6` (recurring) or `Jobs.enqueue_at/6`
   (one-shot). When it fires, the `BCA` transitions `scheduled → fanning_out`.
2. **Resolve the audience** — the `RGP` resolves to the recipient list (minus its suppression set).
3. **Fan-out** — the recipient list becomes per-recipient jobs. Two shapes (fork in §6):
   - **`Jobs.enqueue_many/4`** (`jobs.ex:124`) — simplest bulk admit; the `BCA` aggregation is host-side
     (each delivery reports back to the `BCA`).
   - **A Flow parent→children** (`Flows.add/3`, `children_values/3`) — maps **naturally** to the state
     machine: the parent IS the `BCA`, the children are the per-recipient sends, and `children_values/3` is
     the fan-in the `compacting` transition reads. Recommended where the natural parent/fan-in fit is worth
     the Flow machinery (§6, fork F).
4. **Per-recipient send** — each child runs the existing path, now **gated by `EchoMQ.Throttle`**:
   `Throttle.take(conn, "tg:broadcast", 27, 1000)` (cluster-wide 27/s) **then** the per-chat `RateLimiter`
   1/s; over budget → `enqueue_in` defer + ack (the existing plumbing). `EchoBot.deliver/3` (widened to
   carry `message_id`) produces the `(status, message_id, reason)` → a `BDV` record (batched, §3.1).
5. **Aggregate + compact** — deliveries report to the `BCA` (`draining`); counters tick; at the completion
   rule the `compacting` handler compacts + writes the Result + trims + feeds `RGP` (§3.3).

---

## 6. Forks — resolved (recommend each, state the trade-off)

### Fork D-1 — the 27/s cap home → **Valkey `EchoMQ.Throttle` [RULED by Operator]**
Cluster-wide server-clock token bucket; new echo_mq primitive (§rung R2). Kept from v1; ruled. The
in-memory limiter stays for per-chat 1/s fairness (no round-trip, correct per-node-per-chat).

### Fork F — fan-out shape → **`enqueue_many` for the floor; a Flow parent→children RECOMMENDED for the aggregation fit**
| Option | For | Against |
|---|---|---|
| **`enqueue_many`** | simplest; one bulk admit; no Flow machinery | the `BCA` aggregation + fan-in is entirely host-side (the `BCA` process tracks every reported `BDV`) |
| **Flow parent→children (RECOMMENDED)** | the parent = the `BCA`, children = sends; **`children_values/3` IS the fan-in** the compaction reads (`flows.ex:534`); the real per-child result threads via `complete/5` `ARGV[5]`; multi-level failure propagates up (`flows.ex` emq.3.5) | heavier; a 100k-child flow is large — weigh chunking the fan-out into sub-flows |

**Recommendation:** model the `BCA` as a **Flow parent with batched children** (sub-flows of `batch_size`)
so the fan-in maps onto `children_values/3` and the state machine's `draining→compacting` reads the Flow's
processed set. Where 100k children in one flow is too large, **chunk** the fan-out into N sub-flows and
aggregate across them in the `BCA`. (D-4: confirm Flow-vs-`enqueue_many`; recommend Flow.)

### Fork P — the `BDV` transient store → **lightweight Postgres `broadcast_deliveries` (batched, trimmed at compaction)** vs a per-broadcast Valkey list
Recommend **Postgres** (durable, trivial compaction read, trimmed per broadcast so never accumulates).
Valkey-list alternative keeps it off Postgres at the cost of a read at compaction. (D-2.)

### Fork C — failures extraction → **a `failures` jsonb column on the Result** (vs a partial index)
Recommend the **column** — small hot subset, no full-array scan, feeds `RGP` directly (§3.4). (Ruled into
the model; D-3 only confirms the `timed_out` straggler class.)

### Fork S — the deliver contract → widen `EchoBot.deliver/3` to `{:ok, %{message_id: id}}` (v1 fork 3, KEPT)
Retry/drop reasons already structured; success carries `message_id`. The worker maps each terminal branch to
its control action **and** a `BDV` write. `classify/1` maps Telegram 403 descriptions to the closed reason
enum.

---

## 7. The rung ladder (the spec-driven build plan)

Decomposed so each rung is a thin, gateable increment. Triads live under
`docs/codemojex/notifications/specs/`. **codemojex rungs** prefix `cmn.` (codemojex notifications); the **one
echo_mq rung** is an `emq.*` rung (it touches the bus + the wire master invariant).

| Rung | Title | App | Risk | Depends |
|---|---|---|---|---|
| **cmn.1** | **BCS entities + brands** — `BroadcastTemplate`/`Broadcast`/`BroadcastDelivery`/`RecipientGroup` components, brand minting (`BTP`/`BCA`/`BDV`/`RGP`), `RecipientGroup` resolution (`all/admin/group_of_n/from_csv`). Pure data + resolution; no send. | codemojex | LOW | — |
| **emq.throttle** | **`EchoMQ.Throttle`** — the Valkey server-clock token-bucket primitive (`take/3..4` → `:ok \| {:wait, ms}`), one inline `Script.new/2`, +1 conformance scenario re-pinned `{:ok, 59}→{:ok, 60}`. | echo_mq | **HIGH** (new wire primitive + keyspace under the master invariant) | — |
| **cmn.2** | **Broadcast state machine + send path** — the `scheduled→…→completed` machine, fan-out (Flow parent→children per D-4), per-recipient send gated by `Throttle` + per-chat limiter, `EchoBot.deliver/3` widened, `BDV` produced. | codemojex | MED | cmn.1, emq.throttle |
| **cmn.3** | **Batched durability + compaction** — batched `BDV` writes (`batch_size`), crash-resume from last batch, the `compacting` handler (chronological compaction via `Timeline`), the Result row (`deliveries` + `failures` + `totals`), trim transient records. | codemojex | MED | cmn.2 |
| **cmn.4** | **RecipientGroup failure feedback** — 403 terminal outcomes feed `RGP` suppression / failed-group; the next broadcast skips suppressed recipients. | codemojex | MED | cmn.3 |
| **cmn.5** | **Dashboard counters** — Valkey `HINCRBY` per `broadcast × status × reason` live tiles + per-day rollup; the read API (`HGETALL` + the Result `totals`/`failures`). | codemojex | LOW | cmn.3 |

**Build order:** cmn.1 → emq.throttle → cmn.2 → cmn.3 → cmn.4 → cmn.5. emq.throttle is independent of cmn.1
and can run in parallel; cmn.2 needs both. **emq.throttle is HIGH-risk** (Apollo mandatory — a new
process/keyspace surface under the wire master invariant).

The triad for each rung is authored under §spec artifacts (this chain delivers cmn.1 + emq.throttle as the
exemplars; cmn.2–cmn.5 are carved as `.specs.md` stubs to author next).

---

## 8. The worked case — 100k users daily

**Scenario:** a daily broadcast to 100k recipients, one template type.

- **Burst window:** 100k sends ÷ 27/s ≈ **3,704 s ≈ 1.03 h**. So a 100k broadcast drains over ~1 hour at the
  cap (the cap is the floor on duration — by design, to respect Telegram). Per-chat 1/s is not the binding
  constraint for a broadcast to *distinct* chats; the 27/s global cap is.
- **`BDV` records during the run:** up to 100k transient records, batch-written (500-batch → ~200 bulk
  writes over the hour). Durable; crash-resumable.
- **At `period` end:** compact → **1 Result row** carrying the 100k-element chronological `deliveries` array
  + a small `failures` array + `totals`. **Transient `BDV` records trimmed → 0.**
- **Steady state of N daily broadcasts:** **N Result rows** (1 per broadcast), not N×100k delivery rows. A
  year of daily broadcasts ≈ 365 rows.
- **The only growing raw set is failures** — and it is bounded by the *bounce rate* (the fraction of
  recipients who blocked/deleted), held in the per-Result `failures` column + the `RGP` suppression set.

**Three-class retention:**
| Class | What | Retention | Why |
|---|---|---|---|
| **Counters** (Valkey) | live tiles per broadcast/day | **long** (e.g. 90–365d) — small, bounded by cardinality (1 hash/broadcast) | cheap headline history |
| **Raw `failures`** (Result column) | the actionable bounced subset | **short-to-medium** — the recent actionable window; older failures already applied to `RGP` suppression | drill-down on recent bounces; the long-term state is the suppression set, not the raw failures |
| **Suppression** (`RGP`) | the dead-chat set | **permanent** | a blocked chat stays suppressed forever (re-subscribe is a separate opt-in event) |

(The full chronological `deliveries` array is cold archive — kept with the Result row for audit/replay; it
does not grow with traffic, only with broadcast count.)

---

## 9. Open decisions for the Operator

- **D-1 [RULED]** — global cap = Valkey `EchoMQ.Throttle`. ✓
- **D-2 — `BDV` transient store + batch.** Confirm the in-flight `BDV` store: **Postgres
  `broadcast_deliveries` (recommended)** vs a per-broadcast Valkey list; confirm the default `batch_size`
  (recommend 500).
- **D-3 — straggler completion rule.** At `period` end with un-reported recipients, record them
  `status: timed_out` (recommended) — confirm the terminal class set `{delivered, failed, timed_out}` and
  the closed `reason` enum `{blocked, chat_not_found, deactivated, other}`.
- **D-4 — fan-out shape.** Flow parent→children (recommended, maps to the aggregation) vs `enqueue_many`
  (simpler, host-side aggregation); and, if Flow, the sub-flow chunk size for 100k children.
- **D-5 — Throttle keyspace grammar** (echo_mq). `{emq}:throttle:<name>` first-byte-disjoint reserve
  (recommended) vs a per-name braced key `emq:{throttle:<name>}:tb` — touches the wire master invariant, so
  the design-canon/Operator's call (not the rung's).
- **D-6 — `RecipientGroup.all` source + admin set.** Where does `all` resolve (the codemojex player store)
  and what is the `admin` set? (Shapes cmn.1 resolution.)
- **D-7 — dashboard surface owner.** A codemojex LiveView reading `HGETALL` + Result `totals`/`failures`, vs
  external. (Shapes cmn.5's read API.)

---

## 10. References (grounded)

- **Telegram Bot API limits:** ~30 msg/s broadcast → the **27/s = 90%** cap; ~1 msg/s per chat; ~20 msg/min
  per group. `429` carries `parameters.retry_after`; `403` = blocked/kicked/chat-not-found (**permanent** →
  suppress). Source: core.telegram.org/bots/api (sendMessage) + core.telegram.org/bots/faq (limits).
- **As-built code:** `echo/apps/codemojex/lib/codemojex/{notification_worker,rate_limiter,notifier,echo_bot,
  telegram,application,store,wire,wallet}.ex`; `echo/apps/echo_mq/lib/echo_mq/{lanes,meter,jobs,repeat,flows,
  keyspace,events,conformance}.ex`; `echo/apps/echo_wire/lib/echo_mq/{connector,script}.ex`;
  `echo/apps/echo_data/lib/echo_data/{branded_id,snowflake,base62,timeline,branded_champ,bcs/*}.ex` (cited
  inline at `file:line`).
- **The BCS law + whole-picture frame:** `docs/echo/mesh/mesh.8.1.md`; `echo/apps/echo_data/lib/echo_data/bcs/`.
- **The v2 master invariant + conformance additive-minor law:** repo `CLAUDE.md`, `echo/CLAUDE.md`,
  `docs/echo_mq/emq.design.md`.
