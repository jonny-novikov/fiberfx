# The Bus — authoring brief (persistent prompt · pillar II · BCS-direction)

> **Who reads this & how.** A `general-purpose` agent loading the **`echo-mq-writer`** skill, authoring ONE module
> of the **Bus pillar** (`/echomq/bus`) in the **dark-editorial** identity. Read **both** skills —
> **`echo-mq-writer`** (the craft: dark-editorial, as-shipped/no-version voice, extract-and-annotate Elixir,
> two-column References, the clickable segmented route-tag + canonical 3-column footer, the branded stamp) AND
> **`bcs-writer`** (`references/bcs-canon.md`, the five deltas + §1a). Build the module **hub + its 3 dives** from
> your `## MODULE` section, **md-first then HTML** (the route-mirror is the source-of-record), gate to STATUS: PASS.
> **NEVER run git.** Model the design system on the **built Bus landing** `html/echomq/bus/index.html` and a built
> Queue dive `html/echomq/queue/the-lifecycle/claim-and-the-lease.html`.

## The thesis (one paragraph)

The Bus is pillar II: where the Queue hands one job to **one** worker, the Bus does the opposite — it broadcasts to
**everyone** and keeps an **append-only log** many readers replay at their own pace. Two surfaces, one wire.
**Events** (`EchoMQ.Events`) are fire-and-forget pub/sub on `emq:{q}:events` — a consumer reacts to work as it
happens, without polling the sets. The **stream log** (`EchoMQ.Stream`) is a retained, replayable log **ordered by
mint** — the branded `EVT` id is the receipt. This run builds the first two modules: **01 the events channel** (the
pub/sub surface) and **02 the stream log** (the append-only writer + the order theorem). The Stream Tier is **real
shipped code** (emq3.1–3.6, on disk since 2026-06-23) — it is **NOT `[RECONCILE]` canon**; ground every figure in
`echo/apps/echo_mq` directly.

## Shared context

**Chapter / routes / dirs.** Pillar II, `/echomq/bus`. **The landing exists — do NOT rebuild it.** This run:
- Module 01 → `html/echomq/bus/the-events-channel/` — `index.html` (hub) + 3 dives.
- Module 02 → `html/echomq/bus/the-stream-log/` — `index.html` (hub) + 3 dives.
- md mirrors (write FIRST) → `docs/echo/echo_mq/markdown/bus/<module>/<page>.md` (the real mirror root is
  `docs/echo/echo_mq/markdown/`, NOT the course-map's stale `docs/echo_mq/course/markdown/`).

**The as-built floor — every surface this run teaches (verified on disk 2026-06-25, all MATCH real code; the arity
is in the file — confirm before citing, never print a `file:line` on a page):**

- **`EchoMQ.Events`** (`lib/echo_mq/events.ex`) — the per-queue pub/sub event channel:
  `subscribe(server, pid \\ self())` (register a pid for `{:emq_event, event_name, raw_payload}`),
  `unsubscribe(server, pid \\ self())`, `publish(conn, queue, event, job_id, extra \\ [])` → `PUBLISH emq:{q}:events`,
  `channel(queue)` → `emq:{q}:events` (via `Keyspace.queue_key(queue, "events")`), `close(server, timeout \\ 5_000)`,
  `event_name(payload)` (substring scan → an existing atom or `:unknown`), the `handle_event/3` behaviour +
  `use EchoMQ.Events` (a no-op default). **Fire-and-forget / at-most-once** — a PUBLISH with no live subscriber is
  lost (moduledoc, verbatim). Subscribe ONCE, on a connector that MUST be `protocol: 3` + `push_to` the listener;
  the **emq.1 resubscribe `MapSet`** keeps the feed live across a reconnect. Published lifecycle events are issued
  **HOST-SIDE** after a transition's verdict (the byte-frozen transition scripts stay byte-unchanged).
- **`EchoMQ.Cancel`** (`lib/echo_mq/cancel.ex`) — the worker-side cooperative cancellation token (module 01's
  fire-and-forget *control* sibling): `new/0` (a `make_ref()`), `cancel(pid, token, reason \\ nil)` (sends
  `{:emq_cancel, token, reason}`), `check(token)` (non-blocking `receive after 0` → `:ok | {:cancelled, reason}`),
  `check!(token)` (raises `EchoMQ.Cancel.Cancelled`). **NO wire identity** — a host-side process primitive.
- **`EchoMQ.Stream`** (`lib/echo_mq/stream.ex`) — the writer + reader:
  `append(conn, queue, name, fields)` (mints an `EVT` id host-side, `XADD emq:{q}:stream:<name>`, returns
  `{:ok, branded}`), `append_id/5` (a caller-supplied id; the kind door RAISES on a malformed/wrong-kind id),
  `append_batch/4`, `read(conn, queue, name, from \\ "-", to \\ "+", count \\ nil)` (`XRANGE`, the minimal un-grouped
  read-back → `{:ok, [{branded, fields_map}]}`), `read_since/5` / `read_window/6` (time-travel — a `%DateTime{}` →
  an id bound via `minid_floor/1` + `maxid_ceil/1`), `trim/4` (`XTRIM MAXLEN ~ | MINID`), `stream_key(queue, name)`
  → `emq:{q}:stream:<name>`, `put_archived/get_archived/clear_archived` (the archive watermark cache). The
  `id≤top` rejection maps to **`{:error, :nonmonotonic}`** — never swallowed.
- **`EchoMQ.Stream.Id`** (`lib/echo_mq/stream/id.ex`) — the pure order math: `kind/0` (`"EVT"`),
  `xadd_id(branded)` (`{:ok, "<ms>-<tail22>"} | {:error, :kind | :malformed}`), `evt?/1`. **The order theorem**
  (stream order == id sort == mint order) is proven BY CONSTRUCTION here (order-preserving Base62 within one
  namespace + the high-ts/low-tail snowflake packing). Real doctest vectors you MAY quote verbatim:
  `xadd_id("EVT000xY9Wvvcd") == {:ok, "1704117200000-1620567"}`, `xadd_id("ORD000xY9Wvvcd") == {:error, :kind}`,
  `evt?("EVT000xY9Wvvcd") == true`.
- **`EchoMQ.StreamConsumer`** (`lib/echo_mq/stream_consumer.ex`) — the reader **LAW** (module 03's surface): a BEAM
  consumer group over one per-stream key, **at-least-once** with idempotent handlers, crash → re-delivery. A
  supervised `spawn_link` loop on a **PRIVATE** connector lane (`child_spec/1`, `start_link/1`, `stop/2`). The **group
  door** is lazy ensure-on-start — `XGROUP CREATE <key> <group> <start> MKSTREAM`, swallow **ONLY** the `BUSYGROUP`
  reply (idempotent start; restart-storms never error), a `WRONGTYPE`/other reply is **LOUD** (the consumer fails to
  start). The `:group_start` is **DECLARED, no default** (`:new` → `$` only-after-creation / `:head` → `0` from the
  head) — a missing/malformed value **RAISES** at start, forcing the replay-vs-tail decision open. **Recovery is two
  mechanisms:** PEL-drain-on-(re)start recovers **SELF** (`XREADGROUP GROUP g <self> … 0` reads the OWN un-acked
  backlog to exhaustion, then switches to `>`); the `XAUTOCLAIM <key> <group> <self> <min_idle_ms> 0` beat recovers
  dead **PEERS** (entries idle past the threshold, **server-side idle, no host clock**, one pass per beat). The
  blocking `XREADGROUP GROUP g <self> BLOCK <beat_ms> COUNT <n> STREAMS key >` parks on the consumer's **OWN** lane
  (the `BLPOP`-on-its-own-lane precedent — the single-owner socket is never stalled). The **handler**
  `fun(%{id, payload, attempts, group}) :: :ok | {:error, reason}` is **byte-identical in SHAPE** to the job
  `Consumer`'s handler: `:ok` → `XACK`; `{:error, reason}` or a raise → **LEFT un-acked** (survives in the PEL,
  re-delivered — the at-least-once posture; a raise converts to `{:error, reason}` and the loop survives). `attempts`
  is the `XPENDING` per-entry **delivery-count** (NOT a handler-failure count — a poison threshold `attempts >= N`
  calibrates correctly). The **order-theorem PEL exception:** new entries stay id-ordered (the writer's theorem
  untouched), but a **RE-CLAIMED** entry returns OUT of real-time delivery order — its branded id is **OLDER** than
  entries already handled, the irreducible cost of at-least-once (exactly-once is **not** claimed) → the handler **MUST
  be idempotent**, the branded id the dedup key (BCS newer-wins). **No new `Script.new/2`** — `XGROUP` / `XREADGROUP`
  / `XACK` / `XAUTOCLAIM` / `XPENDING` are issued **DIRECT** through `EchoMQ.Connector.command/3`.
- **`EchoMQ.StreamRetention`** (`lib/echo_mq/stream_retention.ex`) — the **named, OPT-IN trim driver** (module 05's
  cadence surface): a `:transient` GenServer beating on `:tick_ms` (default 1_000) that, on each beat, re-applies a
  **DECLARED** per-stream `:policy` (a list of `{queue, name, window}`) via the public `EchoMQ.Stream.trim/4`
  (`child_spec/1`, `start_link/1`, `stop/2`, `sweep/1` exposed for a direct-drive test → `{:ok, %{trimmed, calls}}`).
  **Retention is a property of the STREAM, not of a consumer** — DECOUPLED from consumer liveness (a stream nobody
  drains still trims), the `EchoMQ.StreamConsumer` loop UNTOUCHED. **Opt-in, owner-started** (no `mod:` auto-start —
  a stream you want UNBOUNDED is simply never declared); the policy is **BEAM-side** (no `emq:{q}:stream:<name>:policy`
  keyspace subkey, no at-rest cleanup); the trim is **idempotent** over the stream (a restart loses no guarantee,
  over-deletes nothing). A manual `Stream.trim/4` is the equally-supported cadence (the driver is sugar over the verb).
- **`EchoStore.StreamArchive`** (`echo/apps/echo_store/lib/echo_store/stream_archive.ex`) — **THE ARCHIVE** (module
  05's durable floor): `fold(volume_id, slice, db)` folds a mint-ordered `{branded, fields}` slice into the native
  **`EchoStore.Graft`** engine's CubDB — one page per record at a **RESERVED high range** (`@archive_base = 2^49`,
  **disjoint from business pages by construction**: a forward `:arc_seq` allocator counting from 0 can never reach
  `2^49`) — through the **PUBLIC** `VolumeServer.commit/3` (engine internals UNTOUCHED), advancing the watermark
  **`W`** (`archive_frontier/1` → `{:ok, W} | :empty`) to the branded `EVT` id of the highest-folded record (**a
  branded id, NEVER the integer `head_lsn`**). The page axis is **branded-id-monotone** (records fold in mint order —
  the order theorem reaching disk), so a forward scan reads oldest-first with **no second index**. `merge_read/5`
  reads archived ∪ live-tail split on `W` (id ≤ W from the archive, id > W from the live `Stream.read/6`);
  **no-gap/no-overlap is a CONSEQUENCE of fold-before-trim + the order theorem**, never a per-read check. The watermark
  is cached on the wire by `EchoMQ.Stream.{put_archived,get_archived}` (`emq:{q}:stream:<name>:archived`) — a polyglot
  CACHE of the seam, NEVER the source of truth. → the **`/echo-persistence`** door (the durability dial in full).
- **Keyspace / no-Lua.** `emq:{q}:stream:<name>` and `emq:{q}:events` share the queue's `{q}` hashtag → one of
  16384 Valkey Cluster slots (no `CROSSSLOT`; cite `valkey.io/topics/cluster-spec/`). **NO LUA on these pages** —
  the stream tier issues `XADD` / `PUBLISH` / `XRANGE` / `XTRIM` **DIRECT** through `EchoMQ.Connector.command/3`
  (the moduledocs say "no new script, no Lua"). The two-beat Lua rule **does not apply** — extract-and-annotate the
  Elixir fn only, and **never fabricate a Lua script**.

**The four disciplines (echo-mq-writer §4).** (1) As-shipped, **no version labels** in prose (no "2.0/3.0", no
"as it is built"); a real wire constant inside a code extract is fine as code. (2) Extract-and-annotate the atomic
**Elixir** fn (the real code + added teaching comments); **NO `file:line` on any page**. (3) The `[RECONCILE]` md
shadow: here there is **NONE** — the stream tier is shipped, so every claim grounds in real code; do not invent a
reason to add one, and **zero `[RECONCILE]` may leak into HTML**. (4) No-invent: every surface is in code above —
never a key, field, arity, or module not listed.

**Identity + the branded stamp.** Dark-editorial (copy the `:root` tokens + the whole design system from
`html/echomq/bus/index.html`). The build stamp is **`EMQ`** — copy the stamp block + the Branded-Snowflake decoder
`<script>` from the Bus landing's footer verbatim, and set `id="stampId"` to **`EMQ0OGUWI87UdF`** with
`id="st-ts"` left as `&mdash;` (the decoder fills it from the id). **NEVER a `TSK` stamp on an echomq page.**

**The frozen-tree guard (§3a — load-bearing).** Ground ONLY in `echo/apps/echo_mq` (underscore). The scrub
`grep -E 'echo/apps/echomq\b|EchoMQ\.Keys\b|EchoMQ\.LockManager|EchoMQ\.Scripts|moveToActive|EchoMQ\.Worker|QueueEvents|CancellationToken'`
must be **0** on every page. Teach the real new names **`EchoMQ.Events`** and **`EchoMQ.Cancel`** — never the v1
`EchoMQ.QueueEvents` / `EchoMQ.CancellationToken` (the moduledocs mention them as lineage; the page must not).

**Doors (resolving — all real, mounted in the gate).** → `/redis-patterns/streams-events` (R5, the pattern side —
the `.applied` reverse-door); → `/bcs/bus` (the manuscript chapter B3 these figures realize — figure home
`docs/echo/bcs/bcs.3.md` §B3.3, quote verbatim where cited); → `/echo-persistence` (the archive frontier from
module 02). Within-chapter: `/echomq/bus` (the landing), `/echomq/queue`, `/echomq/protocol`.

**Sources (vetted — from bcs.3.md; use the real Valkey command pages, never a `.out`):**
[Valkey — Introduction to Streams](https://valkey.io/topics/streams-intro/),
[Valkey — Cluster specification](https://valkey.io/topics/cluster-spec/), the Valkey command pages
(`commands/xadd/`, `commands/xrange/`, `commands/publish/`, `commands/subscribe/`, `commands/xtrim/`),
[Kreps — The Log](https://engineering.linkedin.com/distributed-systems/log-what-every-software-engineer-should-know-about-real-time-datas-unifying),
[Lamport — Time, Clocks, and the Ordering of Events](https://dl.acm.org/doi/10.1145/359545.359563).

**Gate command (ship only at STATUS: PASS):**
```bash
go/jonnify-cms/bin/cms check \
  --routes-from /echomq=html/echomq --routes-from /redis-patterns=html/redis-patterns \
  --routes-from /bcs=html/bcs --routes-from /elixir=elixir \
  --routes-from /echo-persistence=html/echo-persistence \
  --require-refs html/echomq/bus/<module>/<page>.html
```
Gate-invisible checks (verify by reading): clamp spacing; the clickable segmented route-tag; the no-version scrub;
**no `file:line`**; **no Lua block** (this pillar issues commands direct); the §3a frozen-tree scrub → 0; the EMQ
stamp; every `EchoMQ.*`/`EchoStore.*` re-found in `echo/apps/`; zero `[RECONCILE]` in HTML.

---

## MODULE 01 — The events channel  ·  dir `the-events-channel`
**Surface:** `EchoMQ.Events` (+ `EchoMQ.Cancel`, the worker-side control-signal sibling). **Hub** + 3 dives.

- **Hub (`the-events-channel/index.html`).** Frame the events channel: fire-and-forget pub/sub on
  `emq:{q}:events` — subscribe once, publish after a verdict, react without polling. The two-way delivery
  (subscriber pids receive `{:emq_event, name, payload}`; an optional `:handler` module implements
  `handle_event/3`). Set up the contrast with the durable stream (module 02 — the events say it once, the stream
  remembers). One framing interactive (e.g. a publish→fan-out-to-subscribers visual) + the 3 dive cards.
- **Dive `subscribe-and-handle`.** `subscribe/2` registers a pid; the listener subscribes ONCE to
  `channel(queue)` = `emq:{q}:events` (it rides the existing connector pub/sub seam — the `{:emq_push, …}` push +
  the emq.1 resubscribe `MapSet` that keeps the feed live across a reconnect); delivery as `{:emq_event, event,
  payload}` to every subscriber pid + the `:handler` behaviour (`use EchoMQ.Events` derives a no-op
  `handle_event/3`, override the events of interest).
- **Dive `publish-after-the-verdict`.** `publish/5` issues `PUBLISH emq:{q}:events` **HOST-SIDE** after a
  transition's verdict (WHY host-side: the byte-frozen transition scripts stay byte-unchanged — the recommended D1
  placement); the cjson `{"event":"<name>","job":"<id>",…}` payload; the id is **gated at the key builder**
  (`job_key/2`, INV5) before the wire; `event_name/1` reads the name by **substring scan** (the bus carries no JSON
  parser, cjson key order is not guaranteed) and answers `:unknown` for an unknown name — **never minting an atom
  from the wire** (`String.to_existing_atom`).
- **Dive `fire-and-forget`.** At-most-once: a PUBLISH with no live subscriber — or one issued in the window between
  a socket drop and the resubscribe — is **lost**; the emq.1 resubscribe is the mitigation, and the **durable
  receipt is the stream** (module 02 — the door to the log). Pair it with `EchoMQ.Cancel` as a second
  fire-and-forget *control* signal: a `make_ref()` token, `cancel/3` sends `{:emq_cancel, token, reason}` to the
  handler's mailbox, `check/1` is a non-blocking `receive after 0` — a worker-side **cooperative** cancel (a handler
  that never checks completes normally), **no wire identity**.
- **Pager:** hub ↔ dives loop; the chapter pager places module 01 before module 02.

## MODULE 02 — The stream log  ·  dir `the-stream-log`
**Surface:** `EchoMQ.Stream` + `EchoMQ.Stream.Id`. **Hub** + 3 dives.

- **Hub (`the-stream-log/index.html`).** The append-only log: `append/4` mints an `EVT` id host-side and `XADD`s it
  onto `emq:{q}:stream:<name>`; the log is **ordered by mint**; the branded id is the **receipt**; the order
  theorem holds it; the `:nonmonotonic` signal tells the truth. The contrast with module 01 (the stream
  **remembers** what an event forgets). One framing interactive (e.g. an append→ordered-cells log visual) + the 3
  dive cards.
- **Dive `the-host-side-mint`.** `append/4`: mint `EVT` host-side (`EchoData.Snowflake.next_branded("EVT")` — the
  writer **owns** the mint, so there is nothing to spoof); derive the explicit XADD id by field correspondence
  (`Stream.Id.xadd_id/1` → `"<ms>-<tail22>"`, the real Unix-ms high, the 22-bit `node|seq` tail low); issue
  `XADD <key> <xadd_id> id <branded> <fields…>` **DIRECT** (no Lua); return `{:ok, branded}` (the receipt). The
  kind door (`append_id/5`) RAISES before any wire on a malformed / wrong-namespace id.
- **Dive `the-order-theorem`.** Stream order == id sort == mint order, proven **by construction** (the `Stream.Id`
  moduledoc): (1) branded byte order == snowflake integer order — order-preserving Base62, but **only within one
  namespace**, which is why the kind door admits one brand (`EVT`) per stream; (2) the A1 id is an order-preserving
  image of the snowflake (timestamp packed high, tail low, no overlap). A **single writer**'s strictly-monotone
  `:atomics` cell ⇒ the next id always exceeds the stream top ⇒ no XADD rejection is possible; a multi-writer
  violation surfaces **`{:error, :nonmonotonic}`** honestly — never swallowed, never retried with `*`.
- **Dive `the-claims-only-id`.** The branded id is stored as the stream **`id` field** (the claims-only contract: a
  polyglot reader gets the canonical id without re-encoding it from the XADD position); `read/6` (`XRANGE`) is the
  minimal un-grouped read-back — the order-theorem proof surface, **not** a consumer group (`XREADGROUP` is module
  03) — recovering `{branded, fields_map}` in mint order (the stored `id` field becomes the branded receipt, the
  rest the payload map). Name the forward doors without building them: time-travel (`read_window/6` / `read_since/5`,
  module 04) and retention → the archive (`trim/4` → `EchoStore.StreamArchive` → `/echo-persistence`, module 05).
- **Pager:** hub ↔ dives loop; placed after module 01.

## MODULE 03 — The consumer group  ·  dir `the-consumer-group`
**Surface:** `EchoMQ.StreamConsumer` (the reader law). **Hub** + 3 dives.

> **THIS RUN (follow-on) — MODULE 03 ONLY.** Modules 01 (`the-events-channel`) + 02 (`the-stream-log`) are **already
> built — do NOT touch them.** Build only `the-consumer-group/` (hub + 3 dives = 4 pages) + its md mirrors under
> `docs/echo/echo_mq/markdown/bus/the-consumer-group/`. Module 03 is the **reliable read** that sits on module 02's
> un-grouped `read/6` (XRANGE) replay. Everything in **Shared context** above (the as-built floor — note the new
> `EchoMQ.StreamConsumer` bullet; the four disciplines; the EMQ stamp; the frozen-tree guard; the doors; the gate)
> applies. **No Lua** (the group verbs issue DIRECT). Forward doors **named, not built:** time-travel (module 04),
> retention + the archive (module 05 → `/echo-persistence`).

- **Hub (`the-consumer-group/index.html`).** Frame the consumer group: where module 02's un-grouped `read/6` (`XRANGE`)
  is a **stateless replay** (the order-theorem proof surface — every reader sees the whole log from `-`), a consumer
  group is the **reliable, distributed read** — many cooperating readers, **each entry delivered to one**, acked, and
  resumable. The group remembers each consumer's un-acked backlog (the **PEL**) so a crashed reader resumes where it
  left off **without replaying what it handled**. The promise in one line: **read `>`, ack, resume.** Name the cost up
  front — **at-least-once, not exactly-once** (the dive `at-least-once-and-the-handler` pays it off). One framing
  interactive (e.g. a group fan-out: N entries distributed across consumers, each `XACK`ing its own; a crash leaving a
  PEL that a peer reclaims) + the 3 dive cards. Contrast module 02 (replay everything) ↔ module 03 (each entry once,
  resumable).
- **Dive `the-group-door`.** `XGROUP CREATE <key> <group> <start> MKSTREAM` issued **DIRECT** on `start_link` (no Lua):
  it creates the group **and** the stream if absent. Swallow **ONLY** the `BUSYGROUP` reply (the group already exists —
  an idempotent no-op start, so a restart-storm never errors); a `WRONGTYPE` (a non-stream key collision) or **any
  other** error is **LOUD** — the consumer fails to start (the gate-liveness discipline). The **declared `:group_start`**
  (`:new` → `$` = only entries appended *after* the group is created · `:head` → `0` = from the stream head) has **NO
  default** — a missing/malformed value **RAISES** at start, forcing the replay-vs-tail correctness decision into the
  open without a second verb. There is **no destructive group-tear-down verb** at this rung — the door creates and
  swallows-on-exists, never destroys (the at-rest removal surface stays unfrozen for the retention/archive family).
- **Dive `recover-self-then-peers`.** The two complementary recovery mechanisms, both named in the loop. **(1)
  PEL-drain-on-(re)start recovers SELF:** `XREADGROUP GROUP g <self> … 0` reads the un-acked backlog **keyed to THIS
  consumer name**, drained to exhaustion, **then** the loop switches to `>` — a crashed consumer that restarts with the
  same name recovers its own held work the instant it restarts; a clean cold start has an empty PEL (one code path
  covers both). **(2) The `XAUTOCLAIM <key> <group> <self> <min_idle_ms> 0` beat recovers dead PEERS:** entries idle
  past `:min_idle_ms` (evaluated **server-side** against `XPENDING` idle — **no host clock**) held by OTHER consumers
  that died and **never restarted** (so their PEL is never self-drained), re-assigned to this consumer, one pass per
  beat. Then the blocking `XREADGROUP … BLOCK <beat_ms> COUNT <n> STREAMS key >` parks for new entries on the
  consumer's **OWN private connector lane** (the `BLPOP`-on-its-own-lane precedent — the single-owner socket of the
  rest of the system is **never stalled**). `:min_idle_ms` is the single tunable for *how long before a dead peer's
  work is re-delivered*; `:beat_ms` is the block cadence. Control (stop/shutdown) is honored at the **settle points** —
  between entries, never inside one.
- **Dive `at-least-once-and-the-handler`.** The handler `fun(%{id, payload, attempts, group}) :: :ok | {:error,
  reason}` is **byte-identical in SHAPE** to the job `Consumer`'s handler — **one portable handler across job +
  stream**. `id` is the stored **branded record id** (the module-02 `append/4` receipt, recovered from the entry's
  reserved `id` field); `payload` the remaining fields as a map; `group` the group name; **`attempts` the `XPENDING`
  per-entry delivery-count** — how many times THIS entry has been delivered, **NOT** a handler-failure count, so a
  poison threshold (`attempts >= N`) calibrates correctly. On `:ok` the entry is **`XACK`ed** (it retires from the
  PEL); on `{:error, reason}` or a raise it is **LEFT un-acked** (it survives in the PEL → re-delivered by the
  `XAUTOCLAIM` beat or the next PEL-drain — the at-least-once posture; a raise converts to `{:error, reason}` and the
  loop **survives**). **The order-theorem PEL exception:** the stream stays id-ordered for **new** entries (the
  writer's theorem of module 02 is untouched), but a **RE-CLAIMED** entry returns OUT of real-time delivery order — its
  branded id is **OLDER** (lower) than entries already handled. This is the **irreducible cost of at-least-once**
  (exactly-once is **not** claimed) → the handler **MUST be idempotent**: handling the same entry twice, or an older
  entry after a newer one, must be safe — the **branded id is the dedup key** (the BCS newer-wins discipline). Name the
  forward doors without building them: time-travel (`read_window/6` / `read_since/5`, module 04) and retention → the
  archive (`trim/4` → `EchoStore.StreamArchive` → `/echo-persistence`, module 05).
- **Pager:** hub ↔ dives loop; the chapter pager places module 03 after module 02 (and before module 04 time-travel,
  a `soon` card).

## MODULE 04 — Time-travel  ·  dir `time-travel`
**Surface:** `EchoMQ.Stream.{read_window/6, read_since/5, minid_floor/1, maxid_ceil/1}`. **Hub** + 3 dives.

> **THIS RUN (follow-on) — WAVE 1, alongside MODULE 05.** Modules 01/02/03 are built — do NOT touch them. Build only
> `time-travel/` (hub + 3 dives = 4 pages) + its md mirrors under `docs/echo/echo_mq/markdown/bus/time-travel/`.
> Module 04 reads the log **by a mint instant** — the order theorem (module 02) cashed out: because the stream is
> mint-ordered, a wall-clock `%DateTime{}` is an EXACT id position, so a historical window is a **range read, not a
> scan**. **NO Lua** (the reads delegate to the byte-frozen `read/6` → `XRANGE`). Forward door **named, not built
> here:** deep history beyond the live log is the archive (module 05 → `/echo-persistence`).

- **Hub (`time-travel/index.html`).** Frame time-travel: where module 03's consumer group reads **forward** (`>`, new
  entries), module 04 reads a **historical window** by instant. "What did the log look like between 14:30 and 14:32?"
  is `read_window/6` (a **closed** `[t0, t1]`); "everything since 14:30" is `read_since/5` (a **half-open** `[t0, ∞)`).
  Both compute their `XRANGE` bounds host-side from `minid_floor/1` / `maxid_ceil/1` — **zero new Lua**, the whole
  feature is id-math over the shipped `read/6`. The use cases: **backtest · audit · debug**. One framing interactive
  (e.g. a timeline with a draggable window selecting a slice of mint-ordered entries) + the 3 dive cards.
- **Dive `time-is-the-address`.** The mechanism: `minid_floor(dt)` → `"<ms>-0"` (the smallest id at/after `dt`;
  `ms = DateTime.to_unix(dt, :millisecond)`) is the **half-open lower edge**, exact — a `dt - 1ms` entry is OUT, a
  `dt` entry is IN. `maxid_ceil(dt)` → `"<ms>-<0x3FFFFF>"` (the largest id mintable at/before `dt`; `0x3FFFFF` the
  maximal 22-bit `node|seq` tail) is the **inclusive upper edge**, exact — a `dt` entry reads back, a `dt + 1ms` entry
  does not. This is exact **only because** the stream is mint-ordered (the order theorem, module 02) and one brand
  (`EVT`) makes byte-order == snowflake-order. **NEVER a raw snowflake integer to the wire** — the wire wants `ms-seq`
  (the F-1-class discipline `minid_floor/1` holds).
- **Dive `the-two-reads`.** `read_since(conn, q, name, t0, count \\ nil)` → `[t0, ∞)` half-open (`from =
  minid_floor(t0)`, `to = "+"`); `read_window(conn, q, name, t0, t1, count \\ nil)` → `[t0, t1]` closed (`from =
  minid_floor(t0)`, `to = maxid_ceil(t1)`). Both **DELEGATE to the byte-frozen `read/6`** (`XRANGE`) and return
  `{:ok, [{branded, fields_map}]}` **in mint order**. `read_window` **RAISES** `ArgumentError` before any wire on an
  **inverted window** (`t1` strictly before `t0`) — a host-side guard, never a malformed bound to the wire. The window
  is a **server-side filter via the bounds** (it equals reading the whole stream and filtering each entry by its id's
  mint instant). **No Lua.**
- **Dive `backtest-audit-debug`.** The application: replay a window for a **backtest**, **audit** "what happened
  between X and Y", **debug** a past state — each a `read_window/6` over a mint-instant interval, no resident memory of
  the window required. The **codemojex** angle (a page-OWN example, real brands): replay a round's events over its
  open→settle interval (`read_window/6` between two `%DateTime{}` bounds), folding the `GES`/`RND` entries into the
  round's history. Name the forward door **without building it:** deep history beyond the live log folds to the archive
  (module 05 → `EchoStore.StreamArchive` → `/echo-persistence`).
- **Pager:** hub ↔ dives loop; the chapter pager places module 04 after module 03, before module 05.

## MODULE 05 — Retention & the archive  ·  dir `retention-and-archive`
**Surface:** `EchoMQ.Stream.trim/4` + `EchoMQ.StreamRetention` + `EchoStore.StreamArchive`. **Hub** + 3 dives.
**This is the module that doors to `/echo-persistence` in full.**

> **THIS RUN (follow-on) — WAVE 1, alongside MODULE 04.** Modules 01/02/03 built — do NOT touch them. Build only
> `retention-and-archive/` (hub + 3 dives = 4 pages) + its md mirrors under
> `docs/echo/echo_mq/markdown/bus/retention-and-archive/`. A log that only grows is a **leak**; retention bounds the
> live log, and **what is trimmed is not lost** — it folds to the durable Graft floor. **NO Lua** (`XTRIM` issued
> DIRECT; the fold is a store-side `EchoStore.Graft.VolumeServer.commit/3`, not Lua). This is the Bus pillar's
> **`/echo-persistence`** door — name it in prose AND `<a>`-link it (the door target is built).

- **Hub (`retention-and-archive/index.html`).** Frame it: retention is a **POLICY**, not a default — coupling a
  **safety** property (bounded memory) to a **liveness** fact (a consumer is up) is the silent-no-op class the design
  refuses, so the trim cadence lives on its **own** beat. `EchoMQ.Stream.trim/4` bounds the live log by **length**
  (`MAXLEN`) or **age** (`MINID`); `EchoStore.StreamArchive` folds the trimmed segments into the durable Graft floor,
  readable beside the live tail. One framing interactive (e.g. a growing log → a trim sweep → the trimmed segment
  sliding into the durable floor) + the 3 dive cards. The door out is **`/echo-persistence`**.
- **Dive `retention-is-a-policy`.** `EchoMQ.Stream.trim/4`: `{:maxlen, count, approx?}` → `XTRIM <key> MAXLEN [~|=]
  <count>` (keep the `count` newest); `{:minid, %DateTime{}, approx?}` → `XTRIM <key> MINID [~|=] "<ms>-0"` (remove
  every entry minted strictly before the instant; the floor via `minid_floor/1`). `approx?` `true` → `~` (the **SAFE
  default** — trims in whole macro-nodes, may UNDER-trim but **NEVER OVER-trim**, so **INV4** holds by construction: a
  trim can never delete an entry **inside** the window); `false` → `=` (the exact opt-in). Answers `{:ok,
  removed_count}` (a `WRONGTYPE` surfaced, never swallowed). The named OPT-IN driver `EchoMQ.StreamRetention` — a
  `:transient` GenServer beating on `:tick_ms`, re-applying a **DECLARED** BEAM-side `:policy` of `{queue, name,
  window}` via `trim/4`, **decoupled from consumer liveness** — is one cadence; a manual `trim/4` is the equally
  supported one (the driver is sugar). **NO Lua.**
- **Dive `nothing-is-lost`.** `EchoStore.StreamArchive.fold/3`: a mint-ordered `{branded, fields}` slice folds into the
  native **`EchoStore.Graft`** engine's CubDB — one page per record at a **RESERVED high page range**
  (`@archive_base = 2^49`, **disjoint from business pages by construction**: a forward `:arc_seq` allocator counting
  from 0 can never reach `2^49`) — through the **PUBLIC** `VolumeServer.commit/3` (engine internals UNTOUCHED). The
  page axis is **branded-id-monotone** (records fold in mint order — the order theorem reaching disk), so a forward
  scan reads oldest-first with **no second index**. The watermark **`W`** (`:arc_frontier`, the branded `EVT` id of
  the highest-folded record — **NEVER the integer `head_lsn`**) splits the **merge-read** (`merge_read/5`): id ≤ W from
  the archive, id > W from the live `Stream.read/6` tail. **Fold-before-trim** is the no-loss ordering (on a fold
  error the caller does **NOT** trim — the safe direction); no-gap/no-overlap is a **CONSEQUENCE** of it + the order
  theorem, never a per-read check. The wire-side cache `EchoMQ.Stream.{put_archived,get_archived}`
  (`emq:{q}:stream:<name>:archived`) lets a **polyglot** reader find the seam without a store call — a CACHE, never
  the source of truth (`archive_frontier/1` is).
- **Dive `the-door-to-persistence`.** The **durability dial** in depth — the door to **`/echo-persistence`** (a real
  built course) + **`/bcs/persistence`** (B5, `bcs.5.md` the narrative). The dial a system turns: **hold nothing** · a
  **bounded in-heap window + a checkpoint per K** · **commit-per-record + replicate off-box** (Graft → Tigris). The
  deep feed survives **without resident memory** — the merge-read serves archived ∪ live as one mint-ordered stream.
  The **comparison is Oban** (jobs in the same Postgres as the data → one transaction); the bus **separates** the log
  from the store and buys an in-memory hot path + the dial, **giving up** Oban's one-transaction coupling — state the
  trade beside the win, never claim Echo has the coupling. **`<a>`-link `/echo-persistence`** here.
- **Pager:** hub ↔ dives loop; placed after module 04, before the workshop.

## WORKSHOP — The retained event log, end to end  ·  file `workshop.html` (single page, NO dives)
**Surface:** the whole Bus pillar — `EchoMQ.{Events, Stream, StreamConsumer, StreamRetention}` + `EchoStore.StreamArchive`.

> **THIS RUN (follow-on) — WAVE 2, after modules 04 + 05 land.** A **single page** `html/echomq/bus/workshop.html`
> (the protocol-pillar `workshop.html` convention) + the flat md mirror `docs/echo/echo_mq/markdown/bus/workshop.md`.
> **NO dives.** ≥2 interactives. It **folds the whole pillar** — so it **links all five built modules** (01–05, built
> by the time this wave runs). The worked domain is **codemojex** (a retained activity feed); ground every surface in
> real `EchoMQ.*`/`EchoStore.*` + real `Codemojex.*`. Model on `html/echomq/protocol/workshop.html` (the pillar
> workshop convention) + the Bus landing for the design system + the EMQ stamp.

- **The build (a staged construction over the pillar's five surfaces):**
  1. **Publish** the live signal — `EchoMQ.Events.publish/5` → `PUBLISH emq:{q}:events` (module 01): react now,
     fire-and-forget.
  2. **Append + replay** the durable log — `EchoMQ.Stream.append/4` → the `EVT` receipt; `read/6` (`XRANGE`) folds it
     back in mint order (module 02): the log **remembers** what the publish forgets.
  3. **Consume reliably** — `EchoMQ.StreamConsumer` (`XREADGROUP`/`XACK`, module 03): the notification side **resumes,
     not replays**, idempotent on the `EVT` id.
  4. **Replay by instant** — `EchoMQ.Stream.read_window/6` (module 04): render the feed for a mint-time window
     (backtest / audit / debug).
  5. **Bound + fold to disk** — `EchoMQ.Stream.trim/4` under `EchoMQ.StreamRetention`, then
     `EchoStore.StreamArchive.fold/3` → the Graft floor (module 05): the deep feed survives without resident memory.
- **The worked domain — codemojex.** A retained activity feed off the game lifecycle: a guess submitted
  (`Codemojex.Guesses.submit/3`), scored (`Codemojex.ScoreWorker` / `Codemojex.Scoring.score/2`), a round settled
  (`Codemojex.Settle.close/1` / `Codemojex.Rooms.close_game/1`) — each appended as an `EVT` event, the feed a fold of
  the log. (The **redis** R5.05 workshop builds the same feed from the *pattern* side — door to it; this one builds it
  from the **pillar-depth** side.)
- **Doors (all built):** → `/redis-patterns/streams-events` (R5, the pattern side + its R5.05 workshop) · → `/bcs/bus`
  (B3) · → `/echo-persistence` (the durable floor). Within-pillar: link all of `the-events-channel`, `the-stream-log`,
  `the-consumer-group`, `time-travel`, `retention-and-archive`.
- **Pager:** the workshop is the pillar's closing page — `prev` = module 05 `retention-and-archive`, `up` = the Bus
  landing `/echomq/bus`.

## Acceptance
- **MODULES 04 + 05 + WORKSHOP (this follow-on run — completes the Bus pillar): 9 pages.** WAVE 1 (concurrent):
  MODULE 04 `time-travel/` (1 hub + 3 dives) + MODULE 05 `retention-and-archive/` (1 hub + 3 dives). WAVE 2 (after):
  `workshop.html` (1 single page, NO dives, links all 5 modules). md mirrors first under
  `docs/echo/echo_mq/markdown/bus/{time-travel,retention-and-archive}/` + `bus/workshop.md`. **Modules 01/02/03
  untouched.** Module 05 + the workshop **`<a>`-link `/echo-persistence`** (the door target is built).
- **MODULE 03 (the prior run): 4 pages** — 1 hub + 3 dives under `html/echomq/bus/the-consumer-group/`
  (`index.html` + `the-group-door.html` · `recover-self-then-peers.html` · `at-least-once-and-the-handler.html`),
  md mirrors first under `docs/echo/echo_mq/markdown/bus/the-consumer-group/`. **Modules 01 + 02 untouched.**
- **MODULES 01 + 02 (the prior run): 8 pages** — 2 hubs + 6 dives, each its own dir/file under
  `html/echomq/bus/{the-events-channel,the-stream-log}/`.
- Every page **STATUS: PASS** on the gate command; the md mirror written first under
  `docs/echo/echo_mq/markdown/bus/<module>/`.
- Gate-invisible: dark-editorial; the clickable segmented route-tag (`/ echomq / bus / <module> / <page>`); the
  canonical 3-column footer with the **`EMQ0OGUWI87UdF`** stamp; **no** version label; **no** `file:line`; **no** Lua
  block; the §3a frozen-tree + v1-name scrub → **0**; ≥2 interactives per dive (framing + a worked one); every
  surface re-found in `echo/apps/echo_mq`; the three doors resolve.
- **NEVER run git.** Edit only your module's files (your two dirs + their md mirrors).

## Inputs
- Skills: `echo-mq-writer` (+ its `references/course-map.md`) and `bcs-writer` (+ `references/bcs-canon.md`).
- Source (read before citing): `echo/apps/echo_mq/lib/echo_mq/{events,cancel,stream,stream_consumer,stream_retention}.ex`,
  `echo/apps/echo_mq/lib/echo_mq/stream/id.ex`, `echo/apps/echo_store/lib/echo_store/stream_archive.ex`. **Module 03
  grounds in `stream_consumer.ex`; module 04 in `stream.ex` (`read_window/6`/`read_since/5`/`minid_floor/1`/
  `maxid_ceil/1` — the moduledoc proves the exact edges); module 05 in `stream.ex` `trim/4` + `stream_retention.ex`
  (the opt-in driver) + `stream_archive.ex` (`fold/3`, `@archive_base = 2^49`, the `W` watermark, fold-before-trim);
  the workshop folds all five. For the workshop's codemojex domain: `echo/apps/codemojex/lib/codemojex/{game,scoring,
  rooms}.ex` (`Codemojex.{Guesses.submit/3, ScoreWorker, Settle.close/1, Scoring.score/2, Rooms.close_game/1}`).**
- Models: `html/echomq/bus/index.html` (the landing — the design system + the EMQ stamp), a built Queue dive
  `html/echomq/queue/the-lifecycle/claim-and-the-lease.html`.
- Manuscript figure home: `docs/echo/bcs/bcs.3.md` §B3.3 (the Stream Tier) — quote verbatim where cited.
