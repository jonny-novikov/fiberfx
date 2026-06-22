# Redis caching: cache-aside and branded Snowflake keys

<show-structure depth="2"/>

Cache-aside is the default pattern for Redis in front of PostgreSQL or SQLite, and the part of it that shapes daily operation is not the GET/SET choreography — it is the key. This article walks the pattern and its failure modes, places the alternatives, then takes one decision apart in detail: whether the entity key is the conventional `user:274557032793636864` or the branded Snowflake `USR0NgWEfAEJfs`, what each component of the branded form — namespace, base62, embedded timestamp — buys and costs, and which alternatives sit between the two forms.

## The pattern

Cache-aside keeps Redis passive: it stores bytes and expires them; the application owns the read path, the fill, and the invalidation. Read: `GET key`; on a hit, deserialize and return; on a miss, load from the system of record, `SET key value EX ttl`, return. Write: commit to the database, then `DEL key` — the next reader repopulates.

Three properties fall out. Only data that is read enters the cache, so the working set is demand-shaped. The cache is an optimisation, not a dependency: when Redis is down, every call degrades to the loader. And staleness is bounded — the TTL caps the lifetime of any value the invalidation path missed.

<tabs group="runtime">
<tab title="Elixir — Redix" group-key="elixir">

```elixir
defmodule Echo.Cache do
  @moduledoc """
  Cache-aside over Redix. Keys are branded Snowflake IDs:
  3-letter namespace + base62(snowflake) left-padded to 11 — 14 bytes, fixed.
  A Redis outage degrades every call to the loader: slower, not broken.
  """

  @redix :redix
  @base_ttl 300
  @nil_sentinel "@nil"
  @nil_ttl 30

  @type loader :: (-> {:ok, map()} | :not_found)

  @spec fetch(String.t(), loader) :: {:ok, map()} | :not_found
  def fetch(<<_ns::binary-size(3), _b62::binary-size(11)>> = key, loader) do
    case Redix.command(@redix, ["GET", key]) do
      {:ok, nil}            -> fill(key, loader)
      {:ok, @nil_sentinel}  -> :not_found
      {:ok, json}           -> {:ok, Jason.decode!(json)}
      {:error, _redis_down} -> loader.()
    end
  end

  defp fill(key, loader) do
    case loader.() do
      {:ok, entity} = hit ->
        set(key, Jason.encode!(entity), ttl())
        hit

      :not_found ->
        set(key, @nil_sentinel, @nil_ttl)
        :not_found
    end
  end

  defp set(key, value, ttl) do
    Redix.noreply_command(@redix, ["SET", key, value, "EX", Integer.to_string(ttl)])
  end

  # Jitter desynchronises the expiry of keys filled together.
  defp ttl, do: @base_ttl + :rand.uniform(div(@base_ttl, 10))
end
```

The call site decodes once, on the miss path, for the SQL bind:

```elixir
key = Branded.encode(:user, snowflake)          # "USR0NgWEfAEJfs"

Echo.Cache.fetch(key, fn ->
  case Repo.get(User, snowflake) do             # WHERE id = 274557032793636864
    nil  -> :not_found
    user -> {:ok, UserJSON.render(user)}        # the cross-runtime shape
  end
end)
```

</tab>
<tab title="TypeScript — Fastify worker, ioredis" group-key="node">

```typescript
import type { Redis } from "ioredis";

const BRANDED = /^[A-Z]{3}[0-9A-Za-z]{11}$/;    // 14 chars, fixed width
const BASE_TTL = 300;
const NIL = "@nil";

type Loader<T> = () => Promise<T | null>;

export async function fetchAside<T>(
  redis: Redis,
  key: string,
  load: Loader<T>,
): Promise<T | null> {
  if (!BRANDED.test(key)) throw new Error(`malformed branded id: ${key}`);

  try {
    const hit = await redis.get(key);
    if (hit === NIL) return null;
    if (hit !== null) return JSON.parse(hit) as T;
  } catch {
    return load();                              // Redis outage: read the source
  }

  const entity = await load();
  const value = entity === null ? NIL : JSON.stringify(entity);
  const ttl =
    entity === null ? 30 : BASE_TTL + Math.floor(Math.random() * BASE_TTL * 0.1);
  redis.set(key, value, "EX", ttl).catch(() => {});   // fill is best-effort
  return entity;
}
```

</tab>
</tabs>

Set the value and the TTL in one command, as above. A separate `EXPIRE` after `SET` leaves an immortal key when the process dies between the two.

## Failure modes

### Stampede

When a hot key expires, every concurrent reader misses at once and the loader runs N times against the database. Defenses stack. TTL jitter (in the code above) desynchronises keys that were filled together. A per-key Redis lock lets one filler through while the rest briefly poll or serve stale:

```text
SET lock:{USR0NgWEfAEJfs} <token> NX PX 3000
```

In-process deduplication collapses concurrent misses inside one runtime — `Cachex.fetch/4` funnels same-key fallbacks through its courier, one loader run per key per BEAM node, and a Fastify worker can memoise the in-flight promise — but per-process dedup does not coordinate across a Node cluster or between runtimes; that is what the Redis lock is for. For keys that are both hot and expensive, probabilistic early refresh recomputes shortly before expiry with probability rising as expiry approaches — the XFetch rule from "Optimal Probabilistic Cache Stampede Prevention" (VLDB 2015): refresh when `now − Δ·β·ln(rand) ≥ expiry`, with `Δ` the recompute cost and `β ≈ 1`.

### The stale-set race

Cache-aside carries a known write race: a reader misses and loads version 1 from the database; a writer commits version 2 and deletes the key; the slow reader then fills the cache with version 1, which survives until the TTL. Two points of discipline follow. The write path deletes rather than sets — two set-on-write writers can interleave and leave the older value in place indefinitely, while delete-on-write is wrong for at most one TTL. And the TTL is the staleness ceiling, so choose it as a correctness bound, not a memory knob. Facebook's memcache fleet closed the window with leases — a miss hands out a token, and only the token holder may fill ("Scaling Memcache at Facebook", NSDI 2013); on Redis, a Lua compare-and-set against a version field in the value envelope buys the same guarantee for entities that warrant it.

### Negative lookups

A miss for an identifier that does not exist costs a database round trip every time, and unvalidated identifiers turn that into an amplification primitive. Two layers respond: the 14-character shape check rejects malformed identifiers before Redis is touched, and existence misses are cached as a short-TTL sentinel (`@nil`, 30 s above). Cached entities serialize as JSON objects and begin with `{`, so the sentinel cannot collide with a value.

### The value is a contract too

Three runtimes read what one wrote, so the value deserves the same governance as the key: JSON — or MessagePack when size demands — with an explicit schema-version field in the envelope, encoded at fill time from the rendered map rather than from runtime-native structs. Prefer `UNLINK` to `DEL` for large values; reclamation moves off the command thread.

## When cache-aside is the wrong shape

| Pattern | Miss handled by | Writes go to | Staleness | Reach for it when |
|---|---|---|---|---|
| Cache-aside | application code | DB, then `DEL` key | bounded by TTL | the default; tolerant of cache loss |
| Read-through | the cache library | DB, then `DEL` key | bounded by TTL | same semantics with ownership moved into a library (`Cachex.fetch/4`) |
| Write-through | rarely misses | cache + DB, synchronously | low | read-heavy entities that must read fresh |
| Write-behind | rarely misses | cache now, DB async via a queue | DB lags the cache | burst writes where a bounded loss window is acceptable |
| Refresh-ahead | background refresh | DB, then `SET` | low on hot keys | hot keys with expensive loaders (XFetch above) |

Read-through is cache-aside with the loader relocated, which is why the table rows match; the distinction matters for ownership, not semantics. Write-behind needs a durable buffer — Redis Streams or, in this stack, an EchoMQ queue — and an answer for the flush that never happens. Orthogonal to all five: Redis 6's server-assisted client-side caching (`CLIENT TRACKING`) pushes invalidations to clients, so each runtime can hold a short-lived in-process L1 (ETS on the BEAM, a map in a Fastify worker) in front of the shared Redis L2 without inventing its own invalidation protocol.

## One snowflake, two keys

Both schemes name the same 64-bit Snowflake; they differ in which representation of it the cache speaks.

```text
user:274557032793636864      convention ":" decimal          23 bytes today, 24 from mid-2031
USR0KHTOWnGLuC               in-band namespace ++ base62     14 bytes, fixed
└┬┘└────┬────┘
 3      11                   same snowflake, same instant: 2026-01-27 15:11:37 UTC
```

The decimal form widens with the timestamp field; the branded form cannot, because `62^11 ≈ 5.2 × 10^19` covers the full 63-bit range (`2^63 − 1 ≈ 9.2 × 10^18`), which makes the left-pad to 11 total rather than typical. Each component of the branded triplet changes something specific about what the key can do.

### Namespace: convention versus in-band

`user:` lives in key templates scattered across three codebases; `USR` travels inside the identifier itself. The consequences sit at boundaries. An Elixir function head can demand the type — `def get_user("USR" <> _ = id)` — and a wrong-type identifier fails loudly at the clause. With `user:` plus a raw integer, handing an order's snowflake to the user template produces a well-formed key for the wrong entity: a silent wrong-answer class of bug rather than a crash. Both approaches need namespace governance; the branded registry already exists for the API, so the cache inherits it instead of adding a second convention to police.

The cost lands in tooling. RedisInsight and its peers fold keyspaces into trees on `:`, and a flat branded keyspace will not fold. Prefix scans behave identically — `SCAN 0 MATCH USR* COUNT 1000` is the exact analogue of `MATCH user:*` — and SCAN is an operator's tool either way, never a hot-path lookup.

### Base62: fixed width changes what a key can do

The alphabet `0–9A–Za–z` is ASCII-ordered — digits before uppercase before lowercase — so fixed width plus left-padding means lexicographic comparison equals numeric comparison. Keys of one namespace sort in snowflake order, which is creation order: `redis-cli --scan --pattern 'USR*' | sort` reads chronologically, and a sorted set holding branded IDs at score 0 (`ZADD idx:usr 0 USR…`) yields time-window ranges through `ZRANGEBYLEX`, with window boundaries minted by encoding `(window_ms − epoch) << 22`.

Fixed width also makes the boundary check one regex, and the charset closes an injection class outright: it excludes `:`, `*`, `?`, `[`, `]`, `{`, `}` — every character Redis globbing and cluster hash tags treat as structure — so a validated branded ID interpolates into a `MATCH` pattern or a braced satellite without an escaping layer, and delimiter smuggling of the `"123:profile"` form is unrepresentable. Decimal keeps one ergonomic edge: it pastes straight into SQL. Base62 needs the decode helper next to `redis-cli`; budget for that tooling, because incidents are where keys get read by humans.

### The timestamp: every key self-dates

The high 41 bits date every key. Decode any identifier seen in a SCAN dump, a slowlog entry, or an EchoMQ trace and the entity reports its own age — "this cached user was minted at 15:11:37, two minutes before the bad deploy" comes from the key alone. The same property leaks outward: anyone holding an ID learns its creation time, and a sequence of IDs sketches volume. That is a fact about exposing snowflakes at the API, which the cache key inherits rather than introduces; inside a private Redis it is neutral. Slot distribution is unaffected — CRC16 scrambles the monotonic input, so time-ordered keys do not pile onto cluster slots the way they pile onto a B-tree's right edge.

## Codec locality decides

The database column stores the integer; the edge speaks branded; the key scheme decides where the conversion runs. With `user:<int>` keys, a Fastify worker receiving `GET /users/USR0NgWEfAEJfs` must decode base62 before it can ask Redis anything — the decode sits on the hit path of every edge read, and the loader's SQL bind gets the integer for free. With branded keys the request already carries the key: the hit path is conversion-free, and the single decode moves to the miss path where the SQL bind needs it — the cold path by construction, since cache-aside exists because hits dominate. The bill flips for integer-domain planes: a batch job walking primary keys must encode before every cache operation.

Two alignments compound at the edges. EchoMQ invalidation envelopes already carry the branded ID, so a consumer in any runtime executes `DEL` on the payload verbatim instead of re-deriving the key through a template that can drift per codebase. And observability collapses to one identifier: the value grepped from a Fastify access log is the argument to `GET` in `redis-cli` and the correlation ID in the queue trace, with no translation step mid-incident.

## Cluster slots, satellites, locks

Redis Cluster hashes CRC16 of the whole key — unless the key contains `{…}`, in which case only the content between the first `{` and the next `}` is hashed. That rule hands the branded scheme a co-location property at no cost: bare `USR0NgWEfAEJfs` hashes the full 14 bytes, and `{USR0NgWEfAEJfs}:sessions` hashes exactly those same 14 bytes, so the entity and its satellites share a slot and multi-key operations — `MGET`, a Lua script deleting the family on write — stay legal. The colon scheme co-locates only if braces are adopted from the first key written: `user:{274557032793636864}` and `user:274557032793636864` land on different slots, so a later move to cluster mode becomes a key migration.

> On a single node the braces cost nothing and constrain nothing. Adopt the satellite shape before cluster mode makes it mandatory; locks ride along as `lock:{USR0NgWEfAEJfs}` on the entity's slot.
>
{style="note"}

A note on size, since it comes up: 14 fixed bytes against 23 reads like a win, but short keys are SDS strings landing in allocator size classes, and per-key dictionary overhead dominates both. The difference mostly vanishes into jemalloc rounding. Choose the scheme for the codec and the contract, not the bytes.

## Side by side

| Dimension | `user:274557032793636864` | `USR0NgWEfAEJfs` |
|---|---|---|
| Identifier it matches | the DB column (integer domain) | the API, logs, EchoMQ events (edge domain) |
| Codec on the edge hit path | decode base62 before every `GET` | none — the request carries the key |
| Codec in integer-domain jobs | none | encode before cache operations |
| Boundary validation | per-template, after integer parse | one shape: `/^[A-Z]{3}[0-9A-Za-z]{11}$/` |
| Delimiter and glob smuggling | possible when interpolating raw input | charset excludes `: * ? [ ] { }` |
| GUI tree grouping on `:` | yes | no — `SCAN MATCH USR*` unaffected |
| Cluster co-location with satellites | only if braced from day one | bare key + `{key}:suffix` share a slot |
| Size | 23–24 bytes, variable | 14 bytes, fixed |
| Chronological sort | numeric only | lexicographic, per namespace |
| Onboarding cost | none — universal convention | the contract must be documented |

## Between and beyond the two forms

**`usr:0NgWEfAEJfs` — convention prefix, bare payload.** Regains GUI folding and keeps the width, but the key no longer equals the public identifier: a third dialect appears beside the integer and the branded form, and every log-to-CLI paste needs surgery. Take it only when tree grouping in tooling is a hard requirement.

**`user:USR0NgWEfAEJfs` — folding plus identity.** Nine redundant bytes buy `:` folding while the branded substring stays paste-able and grep-able. A defensible compromise for a team that cannot give up tree views; otherwise the prefix repeats information the key already carries.

**Bare integer, no namespace.** `GET 274557032793636864` collides across entity types sharing a keyspace. Not a scheme — an outage in waiting.

**UUIDv7, ULID, KSUID.** Reach for these when minting without node-ID coordination outranks the 64-bit integer column. UUIDv7 is time-ordered and 128-bit — 36 hex characters as a key, around 22 in base62; ULID is 26 characters of Crockford base32, case-insensitive and sortable; KSUID is 160-bit and 27 characters. All widen every index and forfeit the integer-column rule; none changes cache-aside mechanics.

**Epoch prefix: `c7:USR0NgWEfAEJfs`.** A deployment-scoped version segment that mass-invalidates by incrementing the epoch, orthogonal to the scheme choice. Pair an epoch bump with warm-up or rollout jitter — a cold cache is a planned stampede. For per-entity shape changes, version the value envelope instead of the key.

**Query-result keys.** List and filter results live under `q:` plus a hash of the normalised query — a different key class with its own invalidation problem, since any member write dirties the result. Keep entity keys and query keys in separate namespaces, and never encode filters into an entity key.

## The contract, written down

```text
key        = namespace payload                ; 14 bytes, fixed width
namespace  = 3 × [A-Z]                        ; registry-governed: USR, SES, LSN, TSK …
payload    = 11 × [0-9A-Za-z]                 ; base62(snowflake), left-padded with "0"
snowflake  = ts(41) << 22 | node(10) << 12 | seq(12)    ; epoch 2024-01-01T00:00:00Z

satellite  = "{" key "}" ":" suffix           ; {USR0NgWEfAEJfs}:sessions — entity's slot
lock       = "lock:{" key "}"                 ; NX-acquired, PX-bounded
index      = "idx:" lower(namespace)          ; ZADD idx:usr 0 USR… → ZRANGEBYLEX windows
```

> The codec is correctness-critical infrastructure in three runtimes. Pin the alphabet (`0–9A–Za–z`), the padding width (11), the namespace registry, and the epoch with one shared test-vector file consumed by ExUnit, the Node test runner, and `go test` — `TSK0KHTOWnGLuC ⇄ 274557032793636864 ⇄ 2026-01-27 15:11:37 UTC` belongs in that file. A drifted codec produces no errors, only silent misses: the hit rate sags and nothing logs.
>
{style="warning"}

## Choosing

The deciding question is not aesthetics but codec locality: 

which side of the integer-to-branded conversion does the hot path live on. In an architecture where the API, the logs, and the EchoMQ envelopes already speak branded — and three runtimes share one Redis — the branded ID as the entity key removes a conversion from every edge read, turns invalidation events into literal `DEL` arguments, and gives every boundary one 14-character validator. Keep conventional `name:` namespaces for infrastructure keys with no entity identity — locks, rate limits, epochs, query results — and brace the branded ID for satellites. Reserve `type:integer` keys for planes whose traffic originates in the integer domain, such as batch jobs walking primary keys, where the convention removes a hop instead of adding one.