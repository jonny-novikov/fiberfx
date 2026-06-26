# Workshop — A codemojex near-cache, end to end

> Route: `/echomq/cache/workshop` · Pillar III (the Cache) · the closing capstone (single page, no dives).
> Dark-editorial. Stamp `EMQ0OGUWI87UdF`. This page folds the **whole Cache pillar** — it links all three
> built modules (01 cache-aside-two-layers · 02 single-flight-and-jittered-ttl · 03 coherence). Every
> surface is **real shipped code** in `echo/apps/echo_store` + `echo/apps/codemojex` — there are **no
> `[RECONCILE]` markers** here.

## The thesis (one paragraph)

The Cache pillar taught three laws over two layers. This workshop builds **one thing** out of all three: a
**codemojex** read surface near-cached, end to end — a live game whose secret is read on every guess score,
served from local ETS, kept honest across nodes. It is a staged construction. **Declare** a codemojex cache —
register a table in the directory with a kind, a TTL, a jitter, and a coherence mode; a cache absent from the
directory does not exist (`EchoStore.Directory.register/3`). **Hit at ETS speed** — a read is a caller-side
`:ets.lookup`, the kind gate refuses a wrong-namespace id before the wire, and only a miss consults the owner
(`EchoStore.Table.fetch/3`, module 01). **Survive a herd** — concurrent misses coalesce onto one in-flight
fill, expiry is jittered so a cohort never dies together, and a full cache degrades to pass-through, never to
failure (module 02). **Invalidate from another node** — a write on node A sends a 29-byte message about a name
(the id and the writer's mint-time version), and node B's conditional drop deletes its row only when the
incoming version is newer, with the deep job-lane durability folding to the durable journal floor (module 03).
The thread through all of it is the branded id: the entity's own 14-byte id is the cache value's version, the
coherence comparison's clock, and the key the kind gate checks.

## The worked domain — codemojex, one game read

codemojex is the six-emoji code-breaking game on the same stack. On every guess, the scoring authority needs
the game (with its secret) and the emoji-set layout — a read on the hottest path in the game. Both are
**immutable for the game's life**, so they are perfect near-cache fodder: the value never goes stale, and the
cache fronts Postgres so the scorer never round-trips to the relational store on a hit.

The real seam (verified on disk, `echo/apps/codemojex/lib/codemojex/`):

- `Codemojex.Tables` (`tables.ex`) — the declaration site. A `Supervisor` (started `:rest_for_one` so the
  directory and the tables restart together) that declares three `EchoStore.Table` caches:
  - `:cm_games` (kind `GAM`) — a game and its secret, read on every guess score; `coherence: :none`.
  - `:cm_emojisets` (kind `EMS`) — an emoji set's layout, read alongside the game; `coherence: :none`.
  - `:cm_sessions` (kind `SES`) — the **first mutable** table (cm.4 auth); `coherence: :tracking`, because a
    revoked session must be evicted from every BEAM holder's L1 immediately.
- `Codemojex.Cache` (`store.ex`) — the read-hot seam over the near-cache. `fetch_game/1` reads a game through
  `EchoStore.Table.fetch(:cm_games, game_id)`; `put_game/2` writes both layers framed with the game's own id as
  the version. The reads keep a direct Postgres fallback for the boot window; the writes are best-effort
  (`safe_put/4`) so a Valkey blip never fails the writer recording a game.
- `Codemojex.Store` (`store.ex`) — the relational system of record (`game/1`, `set/1`, `room/1`) the loader
  falls through to on an L2 miss. `Codemojex.Tables.load_game/1` is the declared 1-arity loader: it reads
  `Store.game/1` and frames the result with the game's own `GAM` id as the version, or answers a clean miss.

The cache value is `:erlang.term_to_binary(game_map)`; the version is the game's own `GAM` id. The **redis**
course's R1 caching chapter builds these same patterns from the *pattern* side; this one builds the near-cache
from the *pillar-depth* side.

---

## Stage 1 — Declare a codemojex cache (module 01)

The first law of the near-cache: **the cache is declared, not discovered.** A codemojex cache exists only
because `Codemojex.Tables` registered its full specification at start. The directory is the roster of every
declared cache on the node; a cache absent from it does not exist.

Each `EchoStore.Table` GenServer, at init, creates its public L1 ETS table and registers its spec — the kind,
the TTL, the jitter, the max size, the coherence mode — with `EchoStore.Directory.register/3`, which
**monitors the owner** so a crash drops the row the instant the cache leaves the node:

```elixir
# echo/apps/codemojex — Codemojex.Tables (the declaration site, verbatim shape)
# Three declared L1-over-L2 caches in front of Postgres on the scoring hot path.
# Each registers a full spec; a cache absent from the directory does not exist.
children = [
  # the games near-cache: a game + its secret, read on every guess score.
  Supervisor.child_spec(
    {EchoStore.Table,
     name: :cm_games,        # the declared cache name (the L1 :ets table name)
     kind: "GAM",            # the namespace the kind gate enforces on every id
     loader: &load_game/1,   # the 1-arity fall-through to the system of record
     coherence: :none,       # immutable for the game's life — never goes stale
     ttl_ms: 600_000,
     max_size: 50_000,
     connector: connector},
    id: :cm_games_table
  ),
  # … :cm_emojisets (EMS) and :cm_sessions (SES, :tracking) declared the same way
]
# started :rest_for_one under the EchoStore.Directory, so a directory restart
# cascades to the tables and they re-register — the roster cannot silently empty.
```

Under the hood, the table's `init/1` does the registration the directory monitors:

```elixir
# echo/apps/echo_store — EchoStore.Table.init/1 (the declared registration)
:ets.new(name, [:set, :public, :named_table, read_concurrency: true])  # the L1 tier
spec = %{kind: kind, ttl_ms: ttl_ms, jitter: jitter, max_size: max_size,
         sweep_ms: sweep_ms, coherence: coherence, counters: counters}
:ok = EchoStore.Directory.register(name, spec, self())  # monitored — a :DOWN drops the row
```

An operator enumerates every declared cache with `EchoStore.tables/0` → `[{:cm_emojisets, spec}, {:cm_games,
spec}, {:cm_sessions, spec}]` (sorted), and reads one spec with `EchoStore.spec(:cm_games)` → `{:ok, spec}`.
The L2 key the cache will address is `EchoStore.Keyspace.key("cm_games", game_id)` → `ecc:{cm_games}:GAM…` — a
fresh prefix beside `emq:`, the `{cm_games}` hashtag landing every key of this cache on one of 16384 Valkey
Cluster slots, with the id shape-checked before the key is composed.

This is the manuscript's first law, in real codemojex code: *"the cache is declared, not discovered — every
table registers its kind, its TTL, and its coherence mode in a directory, and a cache absent from the directory
does not exist"* (B4.1).

## Stage 2 — Hit at ETS speed (module 01)

With the table declared, the scorer reads a game through `Codemojex.Cache.fetch_game/1` — the read-hot seam
over `EchoStore.Table.fetch/3`. **The read path never enters the owning process.** A hit is a caller-side
`:ets.lookup` in the scorer's own process, so reads scale with schedulers, not with one GenServer's mailbox:

```elixir
# echo/apps/codemojex — Codemojex.Cache.fetch_game/1 (the read-hot seam, verbatim)
# Read a game through the L1/L2 cache, falling back to the system of record. The
# cached value is term_to_binary(game_map); EchoStore frames it with the game's
# own id as the version. A direct Postgres fallback covers the boot window only.
def fetch_game(game_id) do
  case EchoStore.Table.fetch(:cm_games, game_id) do
    {:ok, bin, _source} when is_binary(bin) -> :erlang.binary_to_term(bin)
    _ -> Codemojex.Store.game(game_id)
  end
end
```

`fetch/3` runs the **kind law first**, then tries the layers in order:

```elixir
# echo/apps/echo_store — EchoStore.Table.fetch/3 (the cache-aside read, verbatim)
# 1. look the cache up in the directory (no such cache → {:error, :no_such_cache});
# 2. gate the id: 14 bytes, namespace == the table's declared kind, BrandedId.valid?
#    — a wrong-namespace id is refused at the door, before either layer is touched;
# 3. a caller-side :ets.lookup — a live row (now < expires_at) is {:ok, value, :hit}
#    and NEVER touches the owner; a miss is the only owner call: {:fill, id}.
def fetch(name, id, timeout \\ 10_000) do
  case EchoStore.spec(name) do
    :error -> {:error, :no_such_cache}
    {:ok, spec} ->
      with :ok <- gate(spec.kind, id) do
        now = System.monotonic_time(:millisecond)
        case :ets.lookup(name, id) do
          [{^id, value, expires_at, _version}] when now < expires_at ->
            :counters.add(spec.counters, @counters[:hits], 1)
            {:ok, value, :hit}                       # in the caller's process — no owner, no wire
          _ ->
            :counters.add(spec.counters, @counters[:misses], 1)
            GenServer.call(name, {:fill, id}, timeout)   # the only path that consults the owner
        end
      end
  end
end
```

The answer is tagged with its **source**: `:hit` (L1, in the caller's process), `:l2` (found in the shared
Valkey), or `:fill` (loaded through the declared loader and written to both layers). The kind gate is the
series' oldest law riding into the cache unchanged — a `PLR…` id handed to the `:cm_games` cache (kind `GAM`)
is `{:error, :kind}`, refused before any key is composed. And the L2 frame is self-describing: a cached value
is stored as `version <> value` and split as `<<version::binary-14, value::binary>>`, so the game's own `GAM`
id rides with the bytes.

This is B4.2, in codemojex code: *"the read path never enters the owning process. A hit is a caller-side
`:ets.lookup` against the public L1 table, so reads cost nothing but the lookup and scale with schedulers, not
with one GenServer's mailbox."*

## Stage 3 — Survive a herd (module 02)

A cache that serves a hot read must not stampede when a popular game's row expires, and must not grow without
bound. The second law holds on the miss path: **one fill per herd.** When a thousand guesses arrive for one
game the instant its row expires, the owner runs **one** flight, not a thousand:

```elixir
# echo/apps/echo_store — EchoStore.Table.handle_call({:fill, id}) (single-flight, verbatim)
# Re-check L1 first — the race may have been won between the caller's miss and this
# call. Then: if a flight for this id already exists, append the caller to its
# waiters and count :coalesced — start NO second flight. Else launch one flight.
case :ets.lookup(state.name, id) do
  [{^id, value, expires_at, _v}] when now < expires_at ->
    {:reply, {:ok, value, :hit}, state}            # the race was already won
  _ ->
    case Map.fetch(state.flights, id) do
      {:ok, {ref, waiters}} ->
        :counters.add(state.spec.counters, counter(:coalesced), 1)
        {:noreply, put_in(state.flights[id], {ref, [from | waiters]})}   # join the herd
      :error ->
        ref = launch_flight(state, id)             # the FIRST caller's single flight
        {:noreply, put_in(state.flights[id], {ref, [from]})}
    end
end
```

The flight is a `spawn_monitor`d task, so the owner is never blocked: it `GET`s the L2 key, and on a miss runs
the declared `load_game/1` loader (the fall-through to Postgres), `SET`s both layers, and sends back one
result. `handle_info({:flight, id, result})` replies **the one answer to every waiter** and clears the flight;
a flight crash fails all its waiters with `{:flight_crashed, reason}` — no caller wedges.

Two more guards keep the games cache bounded and herd-free. Expiry is **jittered** so a cohort of games filled
together never expires in step:

```elixir
# echo/apps/echo_store — EchoStore.Table.expires_at/1 (the jittered clock, verbatim)
# base = now + ttl; spread = ttl * jitter; the deadline is base ± a uniform band
# of width spread — so no two rows filled together share an exact expiry instant.
defp expires_at(spec) do
  base = System.monotonic_time(:millisecond) + spec.ttl_ms
  spread = trunc(spec.ttl_ms * spec.jitter)
  if spread == 0, do: base, else: base + :rand.uniform(2 * spread + 1) - spread - 1
end
```

And a full cache **degrades to pass-through, it never fails**. `insert/4` inserts if there is room, else tries
a sweep-on-demand (`reclaim/1`), else counts `:full_skips` and skips the insert — the scorer is still served
from L2 + the loader, the cache simply does not record the row:

```elixir
# echo/apps/echo_store — EchoStore.Table.insert/4 (the full-cache degrade, verbatim)
cond do
  size < state.spec.max_size -> :ets.insert(state.name, {id, value, expires_at(state.spec), version})
  reclaim(state) > 0         -> :ets.insert(state.name, {id, value, expires_at(state.spec), version})
  true ->
    :counters.add(state.spec.counters, counter(:full_skips), 1)
    :skip                       # serve the caller from L2/loader, skip only the cache write
end
```

The cache reports itself honestly through `EchoStore.Table.stats(:cm_games)` — the live counters (`hits`,
`misses`, `fills`, `l2_hits`, `coalesced`, `swept`, `full_skips`, `sweeps`) plus the ETS size. This is B4.2's
second half: *"expiry is deliberately uneven … so a cohort filled together never expires together and a herd
never forms at the second boundary; a sweeper reclaims dead rows on a fixed tick, so memory is bounded by the
declaration rather than by luck."*

## Stage 4 — Invalidate from another node (module 03)

The games and emoji-set caches are `coherence: :none` because their entities are immutable for the game's life
— they can never go stale. But codemojex's **sessions** table (`:cm_sessions`, kind `SES`) is the first mutable
one, and there the third law bites: **a write on one node must not leave a stale read on another.** When a
player's session is revoked or re-issued, every BEAM node holding that session in L1 must drop it — fast.

For sessions, codemojex declares `coherence: :tracking` (RESP3 server-assisted client-side caching): Valkey
itself pushes an invalidation for any write or `DEL` to the `ecc:{cm_sessions}:` prefix, and the owner evicts
the L1 row. A revoke is `EchoStore.Table.invalidate/3` (the unconditional admin drop) on node A; the tracking
push evicts the row on every other node. That is why `:none` would be a *defect* for sessions — a revoked
`SES` surviving in L1 would keep authenticating.

For a versioned write that costs money if read stale, the same pillar carries coherence as **a message about a
name** — `EchoStore.Coherence`. A write mints a new version, and an invalidation carries exactly two identities
— the cached `id` and the writer's mint-time `version`, 29 bytes — over a broadcast lane (`broadcast/4` →
`PUBLISH ecc:{table}:coh`, at-most-once) or a job lane (`enqueue/5` → `Lanes.enqueue` on `ecc.coh.<table>`,
at-least-once). Node B applies it with the conditional drop, which deletes the L2 row **only if the incoming
version is newer**:

```elixir
# echo/apps/echo_store — EchoStore.Coherence.drop_l2/4 (newer-wins, the named handle)
# Conditionally drop the L2 row: deleted only when `version` is newer than the
# version framed into the stored value — one transition, one script, so a late
# stale invalidation can NEVER erase a newer row. The one Lua of the pillar lives
# in module 03 (the `:coherence_drop` script) — printed there, not re-printed here.
def drop_l2(conn, table, id, version) do
  Connector.eval(conn, @drop, [Keyspace.key(table, id)], [version])
end
```

`newer?/2` is the whole engine: it compares the **11-byte snowflake payloads** of two branded ids and ignores
the namespace, so the order theorem's *lexicographic == chronological* property holds across kinds — coherence
needs **no coordinator, no lock, and no clock but the one already inside every id**. Application is idempotent
by construction (the same message applied twice answers stale the second time). The deep durability — a
crash-surviving coherence job whose `applied` table remembers the last version per name even after L1 forgot
the row — folds to the durable journal floor at `/echo-persistence`. The full Lua body and the two lanes are
taught in module 03; this stage names the move.

## The whole pillar, one near-cache

| Stage | Surface | Wire | Law | The game's moment |
|---|---|---|---|---|
| 1 Declare | `EchoStore.Directory.register/3` (via `Codemojex.Tables`) | the directory roster | declared, not discovered | `:cm_games` (GAM) registered at start; absent ⇒ does not exist |
| 2 Hit | `EchoStore.Table.fetch/3` (via `Codemojex.Cache.fetch_game/1`) | `:ets.lookup` · `GET ecc:{cm_games}:GAM…` | the kind gate, caller-side | the scorer reads the game's secret at ETS speed |
| 3 Survive | `launch_flight` · `expires_at/1` · `insert/4` | `GET` → `SET … PX` (one per herd) | one fill per herd; jitter; degrade | a popular game's herd collapses to one fill |
| 4 Invalidate | `EchoStore.Coherence.drop_l2/4` · `:tracking` | `PUBLISH ecc:{t}:coh` / `Lanes.enqueue` / RESP3 push | newer wins | a revoked `SES` is dropped on every node |

The thread through all four rows is the branded id: the game's own `GAM` id is the cache value's version, the
key the kind gate checks, and — for a mutable table — the clock the coherence comparison reads. Minted once,
carried unchanged.

## Pattern → implementation

The *pattern* — a read-through cache, single-flighted under a herd, with bus-coherent invalidation — is what
the **Redis Patterns Applied** course frames in its caching chapter, and its R1 workshop builds this same
codemojex read surface from the pattern side. Here it is built from the *implementation* side: the real
`EchoStore.{Table, Coherence, Directory, Keyspace}` surfaces over the real `Codemojex.{Cache, Tables, Store}`
seam, the branded id the thread through all of them.

## Recap — the pillar, exercised

The Cache pillar taught three laws over two layers; this workshop built one codemojex near-cache out of all
three. **Declare** the cache so it exists, **hit** at ETS speed with the kind gate at the door, **survive** a
herd with one fill and a jittered clock, **invalidate** from another node with a message about a name. The
games cache never goes stale (`:none`); the sessions cache is evicted everywhere the instant it is revoked
(`:tracking`). The deep durability — the lane that remembers past a crash — is `/echo-persistence`. And the
architecture law these figures realize is the BCS store chapter.

## References

### Sources

- Erlang/OTP — *the ets module* — the public, read-concurrent L1 table a hit reads directly, in the caller's
  process.
- Valkey — *Cluster specification* — the `{cm_games}` hashtag landing every `ecc:` key of one cache on one of
  16384 slots.
- Valkey — *GET* / *SET* / *DEL* — the L2 commands the flight and the writer issue direct.
- Helland — *Life Beyond Distributed Transactions* — the entity addressed by a key, cached close to where it is
  used.
- Söderqvist — *A new hash table (Valkey)* — the L2 Valkey the near-cache fronts, costed at rest.
- King — *Announcing Snowflake* — the time-ordered id every cached value is framed with, and whose byte order
  is the coherence comparison.

### Related in this course

- `/echomq/cache/cache-aside-two-layers` — modules 1–2: the declared tiers and the cache-aside read.
- `/echomq/cache/single-flight-and-jittered-ttl` — module 2: one fill per herd, the jittered clock, the
  degrade.
- `/echomq/cache/coherence` — module 3: a message about a name, the two lanes, the conditional drop.
- `/echomq/cache` — the Cache pillar landing this workshop closes.
- `/echomq/queue` — the fair lanes a crash-surviving coherence job rides.
- `/echomq/bus` — the wire a coherence broadcast rides.
- `/redis-patterns/caching` — the pattern side of the door; the cache-aside / stampede / session patterns this
  pillar applies.
- `/bcs/store` — the manuscript chapter (B4) these figures realize.
- `/echo-persistence` — the durable floor: the journal that remembers a coherence verdict past a crash.
