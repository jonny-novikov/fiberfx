# The Cache — authoring brief (persistent prompt · pillar III · BCS-direction)

> **Who reads this & how.** A `general-purpose` agent loading the **`echo-mq-writer`** skill, authoring ONE module
> of the **Cache pillar** (`/echomq/cache`) in the **dark-editorial** identity. Read **both** skills —
> **`echo-mq-writer`** (the craft: dark-editorial, as-shipped/no-version voice, extract-and-annotate Elixir,
> two-column References, the clickable segmented route-tag + canonical 3-column footer, the branded stamp) AND
> **`bcs-writer`** (`references/bcs-canon.md`, the five deltas + §1a). Build the module **hub + its 3 dives** from
> your `## MODULE` section, **md-first then HTML** (the route-mirror is the source-of-record), gate to STATUS: PASS.
> **NEVER run git.** Model the design system on the **built Cache landing** `html/echomq/cache/index.html` and a built
> Queue dive `html/echomq/queue/the-lifecycle/claim-and-the-lease.html` (for the dive anatomy).

## The thesis (one paragraph)

The Cache is pillar III: where the Queue distributes work and the Bus broadcasts signals, the Cache **serves reads**.
It is a **declared near-cache** — an L1 ETS table in front of the L2 Valkey the bus already runs on — read
**cache-aside**: the read path never enters the owning process, a hit is a caller-side `:ets.lookup`, and the owner is
consulted only on a miss, where the second law holds — **one fill per herd**. Expiry is **jittered** so a cohort
filled together never dies together, and a full cache **degrades to pass-through, it never fails**. Every value is
framed with its writer's **mint-time version**, the seed of the coherence (pillar III's third module) that keeps the
caches honest. This run builds the first two modules: **01 cache-aside, two layers** (the declared tiers + the read
path + the write) and **02 single-flight & jittered TTL** (one fill per herd, the jittered clock, the full-cache
degrade). **Coherence — newer wins on the Bus** is module 03 and stays `soon` this run; the **workshop** is module 04.
Every surface is **real shipped code** in `echo/apps/echo_store` — it is **NOT `[RECONCILE]` canon**; ground every
figure in the file directly.

## Shared context

**Chapter / routes / dirs.** Pillar III, `/echomq/cache`. **The landing exists — do NOT rebuild it** (the
orchestrator built it). This run:
- Module 01 → `html/echomq/cache/cache-aside-two-layers/` — `index.html` (hub) + 3 dives.
- Module 02 → `html/echomq/cache/single-flight-and-jittered-ttl/` — `index.html` (hub) + 3 dives.
- md mirrors (write FIRST) → `docs/echo/echo_mq/markdown/cache/<module>/<page>.md` (the mirror root is
  `docs/echo/echo_mq/markdown/`; the landing mirror is the flat `markdown/cache.md`; a module hub is
  `markdown/cache/<module>/index.md`, a dive `markdown/cache/<module>/<page>.md` — mirror the exact shape of the
  built `docs/echo/echo_mq/markdown/bus/` tree).

**The as-built floor — every surface this run teaches (verified on disk 2026-06-25, all MATCH real code; the arity is
in the file — confirm before citing, never print a `file:line` on a page). All under
`echo/apps/echo_store/lib/echo_store/`:**

- **`EchoStore`** (`echo_store.ex`) — the directory / declared-cache roster:
  `tables/0` → `[{name, spec}]` (every declared cache on the node, sorted); `spec(name)` → `{:ok, spec} | :error`;
  the nested `EchoStore.Directory` GenServer — `register(name, spec, owner)` / `unregister(name)`, **monitors each
  owner** so a `:DOWN` deletes the row the moment a cache leaves the node (the roster is never stale). The **declared
  spec** map: `kind` (a 3-byte namespace), `ttl_ms`, `jitter` (0.0..0.5), `max_size`, `sweep_ms`, `coherence`
  (`:none | :broadcast | :tracking`), `counters`. **The law: a cache absent from the directory does not exist.**
- **`EchoStore.Keyspace`** (`keyspace.ex`) — `key(table, id)` → `"ecc:{" <> table <> "}:" <> id`. A **fresh prefix
  beside `emq:`**, never inside it; the table name is **hashtagged** (`{table}`) so every key of one cache lands on
  **one of 16384 Valkey Cluster slots** when clustering arrives (cite `valkey.io/topics/cluster-spec/`). The id is
  shape-checked (`BrandedId.valid?(id)`, **raises** on a malformed name) **before any key is composed** — a malformed
  name never reaches the wire.
- **`EchoStore.Table`** (`table.ex`) — one declared L1 cache over L2 Valkey (a GenServer; the read path stays out of
  it):
  - `fetch(name, id, timeout \\ 10_000)` → `{:ok, value, source}` with `source` ∈ `:hit | :l2 | :fill`, or
    `{:error, :kind}` (wrong-namespace id), `{:error, :no_such_cache}`, or the loader's error. **The read path:** a
    caller-side `:ets.lookup(name, id)` in the **caller's** process — a hit (`now < expires_at`, monotonic ms) is
    `{:ok, value, :hit}` and never touches the owner; a miss is `GenServer.call(name, {:fill, id})`.
  - `put(name, id, value)` (mints a version of the table's `kind` — the write is its own event) /
    `put(name, id, value, <<_::binary-14>> = version)` (carries the writer's own). Both layers: `SET ecc:{t}:id
    (version <> value) PX ttl_ms`, then `insert/4` into L1. **The L2 frame is `version <> value`** — every stored
    value carries its own 14-byte mint-time version.
  - `invalidate(name, id, timeout \\ 10_000)` — the **admin** verb: `DEL` L2 + `:ets.delete` L1, unconditionally.
  - `stats(name)` — the counter snapshot + live `:ets.info(name, :size)`. Counters (by key):
    `hits, misses, fills, l2_hits, coalesced, swept, full_skips, sweeps, coh_applied, coh_stale`.
  - The **gate** (`defp gate(kind, id)`): `byte_size(id) == 14 and binary_part(id, 0, 3) == kind and
    BrandedId.valid?(id)` else `{:error, :kind}` — **the kind law runs before either layer is touched.**
  - **Single-flight (the owner):** `handle_call({:fill, id}, from, state)` — re-checks L1 (the race may have been won),
    else: if a flight for `id` exists, append `from` to its waiters and count `:coalesced` (start **no** second
    flight); else `launch_flight/2`. `launch_flight(state, id)` is a `spawn_monitor`d task: `GET ecc:{t}:id` →
    `{:ok, nil}` runs the declared `loader.(id)` (a 1-arity fun), `SET`s both layers, sends `{:fill, value, version}`;
    `{:ok, <<version::binary-14, value::binary>>}` sends `{:l2, value, version}`; `{:ok, _short}` →
    `{:error, :corrupt_l2_frame}`. `handle_info({:flight, id, result}, state)` replies **the one answer to every
    waiter** and clears the flight; a flight crash (`{:DOWN, …}`) replies `{:error, {:flight_crashed, reason}}` to all
    its waiters (no wedge).
  - **Jittered expiry + sweep + degrade:** `defp expires_at(spec)` = `base = monotonic_ms + ttl_ms`,
    `spread = trunc(ttl_ms * jitter)`, then `base + :rand.uniform(2*spread + 1) - spread - 1` (a uniform ± `spread`
    band; `spread == 0` ⇒ exactly `base`). `handle_info(:sweep, state)` →
    `:ets.select_delete(name, [{{:_, :_, :"$1", :_}, [{:<, :"$1", now}], [true]}])` (delete rows past expiry), count
    `:swept` + `:sweeps`, re-arm `Process.send_after(self(), :sweep, sweep_ms)`. `defp insert(state, id, value,
    version)` — if `size < max_size` insert; else if `reclaim(state) > 0` (a sweep-on-demand) insert; else count
    `:full_skips` and return `:skip` — **a full cache becomes a pass-through (serves its caller from L2/loader, skips
    only the cache write), it never refuses a read.** The ETS row shape is `{id, value, expires_at, version}`.
- **`EchoStore.Coherence`** (`coherence.ex`) — **module 03's surface** ("a message about a name"): an invalidation
  carries exactly TWO identities — the cached `id` + the writer's mint-time `version`, 29 bytes, nothing else.
  `payload(id, version)` → `id <> ":" <> version`; `parse/1` → `{:ok, id, version} | :error` (both `BrandedId.valid?`);
  `newer?(<<_::binary-3, pa::binary-11>>, <<_::binary-3, pb::binary-11>>)` → `pa > pb` — compare the **11-byte snowflake
  payloads**, ignore the namespace: the order theorem makes byte-order == mint-order ACROSS kinds, so coherence needs
  **no coordinator, no lock, no clock but the one inside every id**. **Two lanes, one payload:** `broadcast(conn, table,
  id, version)` → `PUBLISH ecc:{table}:coh <payload>` (fire-and-forget, one wire hop — for "a lost message costs one
  TTL of staleness"); `enqueue(conn, table, group, id, version)` → `Lanes.enqueue(conn, ecc.coh.<table>, group,
  generate!("JOB"), payload)` over EchoMQ's fair lanes (at-least-once, crash-surviving — for "a stale read costs
  money"). `channel/1` → `ecc:{table}:coh`; `queue/1` → `ecc.coh.<table>`. **THE ONE LUA** — `drop_l2(conn, table, id,
  version)` = `Connector.eval(conn, @drop, [Keyspace.key(table,id)], [version])`; the `:coherence_drop` script
  (`Script.new(:coherence_drop, …)`): `GET` the stored value; absent → `0`; `#cur < 14` (malformed frame) → `DEL` +
  `1`; `string.sub(ARGV[1],4,14) > string.sub(cur,4,14)` (incoming version payload > stored version payload) → `DEL` +
  `1`; else `0` — **one transition, one script, so a late stale invalidation can NEVER erase a newer row.** Application
  is **idempotent by construction** (applying the same version twice answers stale the second time). The table spec's
  `coherence: :none | :broadcast | :tracking` selects the lane (`:tracking` = RESP3 server-push, named only).
- **`EchoStore.Ring`** (`ring.ex`) — the **broadcast lane's applier** (module 03): a bounded ring, ONE producer / ONE
  applier — the Disruptor's shape on the BEAM (two `:atomics` carry head/tail sequences, an ETS table the preallocated
  slots, occupancy = tail − head = the backpressure gauge). Wakes are **edge-triggered** (one `:wake` on empty→nonempty;
  the applier re-checks the tail before parking) — "park, don't poll", arrival not discovery. **At-most-once by its
  substrate's contract:** a full ring **refuses the publish and counts the drop**, never blocks, never overwrites
  (surfaces that cannot accept a drop ride the job lane, which does not pass through the Ring). `publish/2`,
  `occupancy/1`, `stats/1`.
- **`EchoStore.Journal`** (`journal.ex`) — the **job lane's durability** (module 03 → the `/echo-persistence` door):
  "the lane that remembers" — a per-group SQLite journal beside the bus (the bus stays volatile by D-2). A
  **transactional OUTBOX** (`intend_and_enqueue/4`: record the intent → enqueue → mark enqueued; every crash window is
  covered by `replay/2` + the bus's job-id dedup + newer-wins). The `applied` table is the lane's **memory of the last
  version per name** — it survives the node, the cache, and the bus, so a replayed old intent **answers stale from the
  journal** even when L1 forgot the row (`last_applied/2`, `apply_and_remember/4`, `handler/2`). → `/echo-persistence`.

**The four disciplines (echo-mq-writer §4).** (1) As-shipped, **no version labels** in prose (no "2.0/3.0", no "as it
is built"); a real wire constant inside a code extract is fine as code. (2) Extract-and-annotate the atomic **Elixir**
fn (the real code + added teaching comments); **NO `file:line` on any page**. (3) The `[RECONCILE]` md shadow: here
there is **NONE** — the near-cache is shipped, so every claim grounds in real code; do not invent a reason to add one,
and **zero `[RECONCILE]` may leak into HTML**. (4) No-invent: every surface is in the floor above — never a key, field,
arity, counter, or module not listed.

**No Lua this run.** Modules 01 + 02 issue Valkey **direct** through `EchoMQ.Connector.command/2-3` — `GET` (the
flight's L2 probe), `SET … PX` (the write), `DEL` (invalidate). There is **no Lua script** in these two modules; the
two-beat Lua rule **does not apply** — extract-and-annotate the Elixir fn only, and **never fabricate a Lua script**.
(The pillar's one Lua, `:coherence_drop`, lives in module 03 — out of scope.)

**Identity + the branded stamp.** Dark-editorial (copy the `:root` tokens + the whole design system from
`html/echomq/cache/index.html`). The build stamp is **`EMQ`** — copy the stamp block + the Branded-Snowflake decoder
`<script>` from the Cache landing's footer verbatim, with `id="stampId"` = **`EMQ0OGUWI87UdF`** and `id="st-ts"` left
as `&mdash;` (the decoder fills it). **NEVER a `TSK` stamp on an echomq page.**

**The frozen-tree guard (echo-mq-writer §3a — load-bearing).** Ground ONLY in `echo/apps/echo_store` +
`echo/apps/echo_mq` (underscore). The scrub
`grep -E 'echo/apps/echomq\b|EchoMQ\.Keys\b|EchoMQ\.LockManager|EchoMQ\.Scripts|moveToActive|EchoMQ\.Worker'` must be
**0** on every page. Teach the real names **`EchoStore.*`** (never the retired `EchoCache.*` / `echo/apps/echo_cache`
— bcs-writer delta 2) and never the deleted `Exchange.*` consumer (delta 3).

**Doors (resolving — all real, mounted in the gate).**
- The `.applied` reverse-door (the **landing** carries the full one; a dive may name it): → `/redis-patterns/caching`
  (R1 — the cache-aside / stampede / session patterns this pillar applies, **built**) and
  `/redis-patterns/streams-events` (R5 — bus-coherent invalidation, **built**). Both **hard-linked**.
- → `/bcs/store` (B4 EchoStore — the manuscript figure home, `docs/echo/bcs/bcs.4.md`; quote a figure **verbatim**
  where cited, e.g. B4.1 "the cache is declared, not discovered", B4.2 "one fill per herd", the jittered clock).
- → `/echo-persistence` (the durable floor — name it only at a durability frontier; the deep durability lives in
  module 03's job lane, so this run touches it lightly if at all).
- Within-course (resolve on disk): `/echomq/cache` (the landing), `/echomq/queue`, `/echomq/bus`, `/echomq/protocol`,
  `/echomq/overview`.

**Sources (vetted — drawn from `bcs.4.md`'s References; use the real Valkey/OTP pages, never a `.out`):**
[Erlang/OTP — the ets module](https://www.erlang.org/doc/apps/stdlib/ets.html) (the public read-concurrent L1 table a
hit reads directly), [Valkey — Cluster specification](https://valkey.io/topics/cluster-spec/) (the `{table}` hashtag →
one slot), the Valkey command pages (`commands/get/`, `commands/set/`, `commands/del/`),
[Helland — Life Beyond Distributed Transactions](https://ics.uci.edu/~cs223/papers/cidr07p15.pdf) (the entity
addressed by a key, cached close to its use),
[Söderqvist — A new hash table (Valkey, 2025)](https://valkey.io/blog/new-hash-table/) (the L2 the near-cache fronts),
[King — Announcing Snowflake (2010)](https://blog.twitter.com/engineering/en_us/a/2010/announcing-snowflake) (the
mint-time id the value is framed with). **Valkey 9 is the only engine — never Dragonfly** (bcs-writer §1a.A).

**Gate command (ship only at STATUS: PASS):**
```bash
go/jonnify-cms/bin/cms check \
  --routes-from /echomq=html/echomq --routes-from /redis-patterns=html/redis-patterns \
  --routes-from /bcs=html/bcs --routes-from /elixir=elixir \
  --routes-from /echo-persistence=html/echo-persistence \
  --require-refs html/echomq/cache/<module>/<page>.html
```
Gate-invisible checks (verify by reading): clamp spacing (spaces around `+`/`-`); the clickable segmented route-tag
(`/ echomq / cache / <module> / <page>`); the no-version scrub; **no `file:line`**; **no Lua block** (these modules
issue commands direct); the §3a frozen-tree + `EchoCache`/`Exchange`/`dragonfly` scrubs → **0**; the EMQ stamp; every
`EchoStore.*`/`EchoMQ.*` re-found in `echo/apps/`; **zero `[RECONCILE]` in HTML**.

---

## MODULE 01 — Cache-aside, two layers  ·  dir `cache-aside-two-layers`
**Surface:** `EchoStore` (the directory) + `EchoStore.Keyspace` + `EchoStore.Table` (`fetch/3`, `put/3-4`,
`invalidate/3`, the gate). **Hub** + 3 dives. **No Lua.**

- **Hub (`cache-aside-two-layers/index.html`).** Frame the declared near-cache: an L1 ETS table in front of the L2
  Valkey the bus already runs on, read **cache-aside** — a hit costs only a caller-side lookup, a miss falls through
  to L2 then a declared loader, and a write frames the value with its mint-time version. Set up the contrast with
  module 02 (here the read is **served**; there it is kept **bounded and single-flighted**). One framing interactive
  (e.g. a read resolving across L1 / L2 / loader, lighting the path + the source tag) + the 3 dive cards.
- **Dive `declared-not-discovered`.** The first law: **the cache is declared, not discovered.** Every table registers
  its full spec in the directory at start (`EchoStore.Directory.register/3`); an operator enumerates every cache with
  `EchoStore.tables/0`; **a cache absent from the directory does not exist**; the directory **monitors** each owner, so
  a `:DOWN` drops the row the instant a cache leaves the node (never a stale roster). The **two tiers**: L1 is a public,
  read-concurrent ETS table (`:ets.new(name, [:set, :public, :named_table, read_concurrency: true])`), local to one
  node; L2 is the shared Valkey, addressed through `EchoStore.Keyspace.key/2` → `ecc:{table}:id` — a fresh prefix
  beside `emq:`, the `{table}` hashtag putting every key of one cache on **one of 16384 Valkey Cluster slots**. The id
  is shape-checked before any key is composed. Extract: `EchoStore.spec/1` (or `Directory.register`) + `Keyspace.key/2`,
  annotated. Interactive: a declared table (kind / ttl / coherence-mode) registered + watched in the directory.
- **Dive `the-cache-aside-read`.** `fetch/3` — **the read path never enters the owner.** A hit is a caller-side
  `:ets.lookup(name, id)` in the caller's process (so reads scale with schedulers, not one GenServer's mailbox), valid
  iff `now < expires_at` → `{:ok, value, :hit}`. The **kind law runs first** (`gate/2` — 14 bytes, namespace == the
  table's declared kind, `BrandedId.valid?`) → `{:error, :kind}` for a wrong-namespace id, refused at the door. A miss
  is the only owner call (`{:fill, id}`) → `{:ok, value, :l2}` (found in Valkey) or `{:ok, value, :fill}` (loaded). The
  **L2 frame is self-describing** — `version <> value`, split as `<<version::binary-14, value::binary>>`, so a cached
  value carries its own mint-time version. Extract: `fetch/3` + `gate/2`, annotated. Interactive: a read resolving
  to `:hit` / `:l2` / `:fill` over a fixed dataset, showing the source tag + the gate refusing a wrong-kind id.
- **Dive `writing-both-layers`.** The writer path: `put/3` mints a version of the table's `kind` now (the write is its
  own event); `put/4` carries the writer's own 14-byte version. Both layers, in order: `SET ecc:{t}:id (version <>
  value) PX ttl_ms` on L2, then `insert/4` on L1 (the `{id, value, expires_at, version}` row). Every value is **framed
  with its mint-time version** — the seed of coherence (the version greater-wins comparison module 03 builds on; name
  it forward, don't teach it). `invalidate/3` is the **admin** verb: `DEL` L2 + `:ets.delete` L1, unconditionally — the
  unguarded drop, distinct from the version-guarded coherence drop of module 03. Extract: the `{:put, …}` handler (or
  `put/4`) + `invalidate/3`, annotated. Interactive: a write framing `version <> value` into both layers, then a read
  recovering the version from the frame.
- **Pager:** hub ↔ dives loop; the chapter pager places module 01 before module 02.

## MODULE 02 — Single-flight & jittered TTL  ·  dir `single-flight-and-jittered-ttl`
**Surface:** `EchoStore.Table` — `launch_flight` + the `{:fill}` handler (single-flight), `expires_at` + the `:sweep`
handler (jitter), `insert` / `reclaim` (degrade), `stats/1` (the counters). **Hub** + 3 dives. **No Lua.**

- **Hub (`single-flight-and-jittered-ttl/index.html`).** Frame the second half of the read machine: a cache that does
  not stampede and does not grow without bound. On a miss, **one fill per herd** — concurrent misses coalesce onto a
  single in-flight load; expiry is **jittered** so a cohort never dies in step; and a full cache **degrades to
  pass-through, it never fails**. Contrast with module 01 (01 serves the read; 02 keeps the read cheap under a herd and
  bounded under pressure). One framing interactive (e.g. N concurrent readers collapsing to one loader call) + the 3
  dive cards.
- **Dive `one-fill-per-herd`.** The second law. Concurrent misses on the **same** key coalesce onto a single in-flight
  load. The owner's `handle_call({:fill, id})`: if a flight for `id` already exists, append the caller to its waiters
  and count `:coalesced` — start **no** second flight; else `launch_flight/2`. The flight is a `spawn_monitor`d task
  (the owner is never blocked): `GET ecc:{t}:id` → on `nil` run the declared `loader.(id)`, `SET` both layers, send
  `{:fill, value, version}`; on an L2 hit send `{:l2, value, version}`. `handle_info({:flight, id, result})` replies
  **the one answer to every waiter** and clears the flight; a flight crash (`:DOWN`) fails all its waiters with
  `{:flight_crashed, reason}` — no caller wedges. Extract: the `{:fill}` handler + `launch_flight`, annotated.
  Interactive: N concurrent readers → 1 flight → 1 loader call → N identical replies (the coalesce counter ticking).
- **Dive `jittered-expiry`.** Expiry is **deliberately uneven**: `expires_at(spec)` = `ttl ± ttl·jitter` (jitter in
  `0.0..0.5`), so a cohort filled together never expires together and no herd forms at the second boundary. A
  **sweeper** (`handle_info(:sweep)` → `:ets.select_delete` of rows past expiry, re-armed every `sweep_ms`) reclaims
  dead rows on a fixed tick, so memory is **bounded by the declaration, not by luck**. Extract: `expires_at/1` + the
  `:sweep` handler, annotated. Interactive: a cohort's expiry spread across the jitter band vs the thundering-herd
  spike at a single TTL boundary without it (a fixed before/after over a fixed dataset).
- **Dive `the-full-cache-degrades`.** A full cache **degrades, it does not fail.** `insert/4` — if `size < max_size`,
  insert; else if `reclaim/1` (a sweep-on-demand) freed room, insert; else count `:full_skips` and **skip the insert**:
  the cache becomes a **pass-through** that still serves its caller from L2 + the loader, never refusing a read. Close
  with the **stats surface** — `stats/1` reads the live counters (`hits / misses / fills / l2_hits / coalesced /
  swept / full_skips / sweeps`) + the ETS size, the cache's honest self-report. Name **coherence (module 03)** as the
  forward pointer: every row already carries its mint-time `version`, and that version is what the third module's
  newer-wins comparison rides — a one-line door, not a lesson. Extract: `insert/4` + `reclaim/1` + `stats/1`,
  annotated. Interactive: a cache at `max_size` taking a fill — reclaim-then-insert vs `:full_skips` pass-through.
- **Pager:** hub ↔ dives loop; placed after module 01.

## MODULE 03 — Coherence: newer wins on the Bus  ·  dir `coherence`
**Surface:** `EchoStore.Coherence` (+ `EchoStore.Ring` the broadcast applier · `EchoStore.Journal` the job-lane
outbox → `/echo-persistence`). **Hub** + 3 dives. **HAS ONE LUA** (`:coherence_drop`).

> **THIS RUN — MODULE 03 (finishes the Cache content modules).** Modules 01 (`cache-aside-two-layers`) + 02
> (`single-flight-and-jittered-ttl`) are built — do NOT touch them. Build only `coherence/` (hub + 3 dives = 4 pages)
> + its md mirrors under `docs/echo/echo_mq/markdown/cache/coherence/`. **THE "No Lua this run" SHARED-CONTEXT NOTE
> DOES NOT APPLY TO MODULE 03** — module 03 carries the pillar's **one** Lua (`:coherence_drop`), so the **two-beat Lua
> rule APPLIES** on the `newer-wins-the-conditional-drop` dive: first the named handle (`EchoStore.Coherence`'s
> `drop_l2/4` + the `@drop`/`:coherence_drop` script name), THEN a separate Lua block with the real body, deeply
> commented. Coherence is the third law: a write on one node must not leave a stale read on another.

- **Hub (`coherence/index.html`).** Frame coherence — the third law of the near-cache: **a write on one node must not
  leave a stale read on another.** Coherence is **a message about a name**: an invalidation carries exactly two
  identities (the cached `id` + the writer's mint-time `version`), 29 bytes, nothing else. **Newer wins** by comparing
  the 11-byte snowflake payloads — the order theorem makes byte-order == mint-order regardless of namespace, so
  coherence needs **no coordinator, no lock, no clock but the one inside every id**. Two lanes carry the same payload
  (broadcast / job); the choice is the **cost of staleness**. One framing interactive (e.g. a write on node A → an
  invalidation message → a stale row dropped on node B) + the 3 dive cards.
- **Dive `a-message-about-a-name`.** The vocabulary: `payload(id, version)` = `id <> ":" <> version` (29 bytes);
  `parse/1` recovers the two names (both `BrandedId.valid?`). `newer?/2` = `pa > pb` — compare the **11-byte snowflake
  payloads**, ignore the 3-byte namespace: the order theorem's *lexicographic == chronological* property holds **across
  kinds**, so a `GAM` version and a `PLR` version are still comparable. Coherence therefore needs **no coordinator, no
  lock, no clock**. **Idempotent by construction:** applying the same version twice is a comparison that answers stale
  the second time. Extract: `payload/2` + `parse/1` + `newer?/2`, annotated. Interactive: two versions compared by
  their 11-byte payloads (newer-wins) across namespaces.
- **Dive `the-two-lanes`.** Broadcast vs job — one payload, two carriers, chosen by the **cost of staleness**. **The
  broadcast lane** (`broadcast/4` → `PUBLISH ecc:{table}:coh <payload>`): fire-and-forget, one wire hop, for "a lost
  message costs one TTL of staleness"; applied by **`EchoStore.Ring`** — the Disruptor-shaped bounded ring (one
  producer / one applier, edge-triggered wakes), **at-most-once**: a full ring **refuses + counts the drop**, never
  blocks/overwrites. **The job lane** (`enqueue/5` → `Lanes.enqueue` on `ecc.coh.<table>` over EchoMQ's fair lanes):
  **at-least-once**, crash-surviving, for "a stale read costs money"; remembered by **`EchoStore.Journal`** (the
  transactional outbox). The table spec's `coherence: :none | :broadcast | :tracking` selects the lane (`:tracking` =
  RESP3 server-push, **named only**). Extract: `broadcast/4` + `enqueue/5` + `channel/1`/`queue/1`, annotated.
  Interactive: pick a staleness cost → the lane (broadcast/job) + its substrate (Ring/Journal) lights.
- **Dive `newer-wins-the-conditional-drop`.** **The two-beat Lua dive.** `drop_l2(conn, table, id, version)` =
  `Connector.eval(conn, @drop, [Keyspace.key(table, id)], [version])` (beat 1 — the named handle). Beat 2 — the
  `:coherence_drop` Lua body, deeply commented: `GET` the stored value; absent → `0`; `#cur < 14` (a malformed frame)
  → `DEL` + `1`; `string.sub(ARGV[1], 4, 14) > string.sub(cur, 4, 14)` (the incoming version's 11-byte payload > the
  stored version's, recovered from the `version <> value` frame) → `DEL` + `1`; else `0` — **one transition, one
  script, so a late stale invalidation can NEVER erase a newer row** (the unconditional `invalidate/3` admin drop of
  module 01 is the contrast). The **`EchoStore.Journal`'s `applied` memory** (the last version per name) survives the
  node/cache/bus, so a replayed old intent **answers stale from the journal** even when L1 forgot the row → name
  **`/echo-persistence`** (the durable floor for the job lane). Extract: `drop_l2/4` (beat 1) + the `@drop` body (beat
  2), annotated. Interactive: a late stale version vs a newer version both hitting the conditional drop (only the newer
  deletes).
- **Pager:** hub ↔ dives loop; module 03 after module 02 (and before the workshop).

## WORKSHOP — A codemojex near-cache, end to end  ·  file `workshop.html` (single page, NO dives)
**Surface:** the whole Cache pillar — `EchoStore.{Table, Coherence}` (+ the directory/keyspace) over a **codemojex**
read surface. **The landing card 04:** "Hit at ETS speed; invalidate from another node; survive a herd with one fill."

> **THIS RUN — the Cache workshop (after module 03).** A **single page** `html/echomq/cache/workshop.html` (the
> protocol/bus `workshop.html` convention) + the flat md mirror `docs/echo/echo_mq/markdown/cache/workshop.md`. **NO
> dives.** ≥2 interactives. It **folds the whole pillar** — so it **links all three modules** (01–03, built by the time
> this runs). The worked domain is **codemojex** (a read surface near-cached); ground every surface in real
> `EchoStore.*` + real `Codemojex.*` (verify `Codemojex.{Board, Store, Rooms}` on disk — `echo/apps/codemojex/lib/codemojex/`).

- **The build (a staged construction over the pillar's surfaces):**
  1. **Declare** a codemojex cache — register a table in the directory (kind / ttl / jitter / `coherence:` mode);
     a cache absent from the directory does not exist (`EchoStore` / `EchoStore.Directory.register/3`).
  2. **Hit at ETS speed** — `EchoStore.Table.fetch/3` resolves a hit caller-side (`:ets.lookup`), the kind gate refuses
     a wrong-namespace id (module 01).
  3. **Survive a herd** — concurrent misses coalesce onto one in-flight load; jittered TTL spreads expiry; a full cache
     degrades to pass-through (module 02).
  4. **Invalidate from another node** — a codemojex write on node A `broadcast/4`s (or `enqueue/5`s) "a message about a
     name"; node B's `drop_l2/4` drops the L2 row only if the incoming version is newer (module 03); the deep job-lane
     durability folds to `/echo-persistence`.
- **The worked domain — codemojex.** A near-cached read surface (e.g. a board/room/score read): a write mints a new
  version, the coherence message carries the name + version, the stale read is dropped newer-wins. Verify the real
  `Codemojex.*` read surface on disk before citing (do not invent).
- **Doors (all built):** → `/redis-patterns/caching` (R1 — the cache-aside/stampede/session patterns this applies) ·
  → `/bcs/store` (B4 EchoStore) · → `/echo-persistence` (the journal's durable floor). Within-pillar: link
  `cache-aside-two-layers`, `single-flight-and-jittered-ttl`, `coherence`.
- **Pager:** the pillar's closing page — `prev` = module 03 `coherence`, `up` = the Cache landing `/echomq/cache`.

## Acceptance
- **MODULE 03 + WORKSHOP (this run — completes the Cache pillar): 5 pages.** MODULE 03 `coherence/` (1 hub + 3 dives:
  `a-message-about-a-name` · `the-two-lanes` · `newer-wins-the-conditional-drop` — the two-beat `:coherence_drop` Lua)
  + the **`workshop.html`** single page (folds all 3 modules; a codemojex near-cache). md mirrors first under
  `docs/echo/echo_mq/markdown/cache/coherence/` + `cache/workshop.md`. **Modules 01 + 02 untouched.** Module 03 + the
  workshop **`<a>`-link `/echo-persistence`** (the journal's durable floor). Module 03 carries the **one Lua block**
  (the two-beat rule) — the workshop has **none**.
- **MODULES 01 + 02 (the prior run): 8 pages** — 2 hubs + 6 dives, each its own dir/file under
  `html/echomq/cache/{cache-aside-two-layers,single-flight-and-jittered-ttl}/`.
- Every page **STATUS: PASS** on the gate command; the md mirror written first under
  `docs/echo/echo_mq/markdown/cache/<module>/`.
- Gate-invisible: dark-editorial; the clickable segmented route-tag; the canonical 3-column footer with the
  **`EMQ0OGUWI87UdF`** stamp; **no** version label; **no** `file:line`; **no** Lua block; the §3a frozen-tree +
  `EchoCache`/`Exchange`/`dragonfly` scrubs → **0**; ≥2 interactives per dive (a framing one + a worked one); every
  surface re-found in `echo/apps/echo_store` (or `echo/apps/echo_mq`); the doors resolve.
- **NEVER run git.** Edit only your module's files (your one dir under `html/echomq/cache/` + its md mirror dir).

## Inputs
- Skills: `echo-mq-writer` (+ its `references/course-map.md`) and `bcs-writer` (+ `references/bcs-canon.md`).
- Source (read before citing): `echo/apps/echo_store/lib/echo_store/{table,keyspace,echo_store}.ex` (modules 01/02);
  **module 03: `echo/apps/echo_store/lib/echo_store/{coherence,ring,journal}.ex`** (`coherence.ex` is the spine — the
  `:coherence_drop` Lua is `@drop` in it); the workshop folds all three + a real `Codemojex.{Board,Store,Rooms}` read
  surface (`echo/apps/codemojex/lib/codemojex/`, verify on disk).
- Models: `html/echomq/cache/index.html` (the landing — the design system + the EMQ stamp), a built Queue dive
  `html/echomq/queue/the-lifecycle/claim-and-the-lease.html` (the dive anatomy).
- Manuscript figure home: `docs/echo/bcs/bcs.4.md` (B4 EchoStore — B4.1 the declared near-cache, B4.2 one fill per
  herd) — quote verbatim where cited.
