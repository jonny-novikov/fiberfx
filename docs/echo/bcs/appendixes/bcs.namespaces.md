# BCS · Specified — Namespaces, and the System You Declare

<show-structure depth="2"/>

A BCS system is declared before it is coded: its namespaces, its components, and its boundaries are a specification, and the schema, the id registry, the cache tables, and the gates follow from it. This article specifies the namespace half of that declaration — a curated three-letter platform registry beside an open four-letter developer-space — weighs the split, measures what the extra letter costs, and writes the observability triad of log, trace, and correlation as the worked example.

## Scope and method

Elixir 1.14.0 / OTP 25, Valkey dev branch built on jemalloc 5.3.0, alongside the on-disk model of the companion article on PostgreSQL 16.14 and SQLite 3.45.1. What is measured: the per-key cost of a three-letter versus four-letter namespace on the BEAM's `:ordered_set` and on Valkey, at two hundred thousand distinct ids, and the fact that the namespace occupies no column on disk. What is cited: the snowflake layout [1], the trace-context propagation model [2], and the allocator size classes behind the cost result [3]. What is decided, not measured: the allocation policy itself. The figures are in `evidence/ns.out` and `evidence/bcs-db.out`; the registry is `EchoData.Namespace`, over the shape rules in `EchoData.BrandedId`.

## A system is a specification

BCS draws encapsulation around systems rather than objects: only identities and messages about identities cross a boundary. A system is therefore defined by three declarations. Its **namespaces** — the kinds of identity it mints. Its **components** — the tables and columns that hold those identities and their attributes, each with a key form and an access pattern. Its **boundaries** — which values cross as branded text and which stay as in-system `bigint` foreign keys. The build is mechanical from the declaration: a namespace becomes a registry entry and a gate, a component becomes a table — a snowflake `bigint` primary key on disk, an ordered `EchoData.Bcs.Column` in memory — and, for hot kinds, a cache table, and a boundary becomes the rule that the value crossing is the branded text, decoded at the door. The specification is canonical: it is edited, and the system follows. So the first thing to pin down is the namespace, because it is the name every later artifact keys on.

## The namespace registry

A namespace is two things at once: the leading letters of a branded id, and the identity of a component table. `EchoData.BrandedId` fixes the shape — three or four uppercase letters — and `EchoData.Namespace` fixes the policy, by splitting that shape into two spaces with different rules.

The **three-letter space is the platform registry**: a curated, scarce, readable set of distinctive system kinds — `USR`, `SES`, `ORD`, and the observability triad `LOG`, `TRC`, `COR`. Its capacity is 26^3 = 17576 names, small enough to curate by hand and large enough for a platform's primitives, and three letters stay short because these names are read constantly — in a log line, on the wire, in a correlation header. The **four-letter space is developer-space**: open to applications built on the platform — `SHOP`, `TEAM`, any well-formed four letters — with a capacity of 26^4 = 456976 names, far roomier, and reserved entirely for extension so an application's kind can never collide with a platform kind.

The classifier is total. A registered three-letter name is platform; an unregistered three-letter name is `reserved` — platform-owned, not available to applications; any four-letter name is developer; anything else is invalid.

```text
classify:
  LOG   -> {:platform, :log}        XYZ   -> :reserved
  TRC   -> {:platform, :trace}      SHOP  -> :developer
  COR   -> {:platform, :correlation} TEAM -> :developer
  USR   -> {:platform, :user}       LO    -> :invalid
  SES   -> {:platform, :session}    LOGGG -> :invalid
```

The governance is one rule with one home: applications mint in four letters, and the platform grows by registering a three-letter kind in `EchoData.Namespace`, the single place that decision is recorded.

## Measured: the cost of a letter

The split would not be worth proposing if the fourth letter cost anything. It does not.

```text
## ETS :ordered_set bytes/key, 200000 distinct ids
  14-byte (LOG  + 11 body) = 96.01
  15-byte (LOGX + 11 body) = 96.01      -- same word bucket

## Valkey 8+ SET bytes/key
  ns=LOG  len=14  keys=200000  = 53.86
  ns=LOGX len=15  keys=200000  = 53.84  -- same size class
```

On the BEAM's ordered set a fourteen-byte and a fifteen-byte id occupy the same 96.01 bytes per key — the same heap-binary word bucket, so the extra letter rounds away. On Valkey both sit in one size class, 53.86 against 53.84 bytes per key, a gap inside measurement noise, because both round into jemalloc's sixteen-byte class under the server's quantum [3]. And on disk the question is moot: the snowflake is the `bigint` primary key and the namespace is the table's identity, never a stored column, so a three- or four-letter namespace costs zero bytes per row (`bcs-db.out`). The fourth letter is free on every substrate the platform uses. The loss recorded beside the result: the four-letter id is one byte wider on the wire, visible only where the branded text is printed, never in storage and never in the keyspace. What the split spends is not memory but names — the platform keeps the short, scarce space; developers get the roomy, collision-free one.

## The observability triad: LOG, TRC, COR

The triad is the clearest case for platform-distinctive namespaces, because all three cross every system and are read by people. **Correlation** (`COR`) is the identity that threads one logical operation across system boundaries — minted once at the edge and carried unchanged through every system it touches, the way a W3C trace-context `traceparent` carries a trace-id that stays fixed while the per-hop span id changes [2]. It is the branded boundary value in its purest form: a `COR` id in every system's logs is the join key that reconstructs the operation, which is why it is carried as branded text and is never a foreign key. **Trace** (`TRC`) is the span record — append-heavy, time-ordered, sampled, short-lived. **Log** (`LOG`) is the log line — the highest-volume component the platform writes, time-ranged on read and aggressively expired.

The snowflake key serves all three with no secondary index. The embedded mint clock orders spans and lines by time — `ORDER BY id` is the primary-key read — and a retention window is an id-range delete, the generational sweep, so a day of logs drops by one bounded range on the key rather than a scan of a timestamp column. This is the `EchoData.Buckets` pattern, and it is why these append-mostly kinds key on the snowflake and never on a separate `created_at`. They are platform kinds, in three letters, because every application on the platform emits them and reads them, and a short, well-known name is the one that survives a log search at three in the morning.

## The spec that builds the system

A system declaration names its kinds and its components; each line expands into an artifact. For the entities of the on-disk model and the triad:

```text
system :accounts
  namespaces:
    USR platform/user         SES platform/session
    FRD platform/friendship   ADR platform/address
    COR platform/correlation  TRC platform/trace   LOG platform/log
  components:
    users             key USR          store table(users)      cache table("users")
    sessions          key SES          store table(sessions)   ttl id-range
    profile_addresses key (USR, ADR)   composite               -- a user's addresses by PK prefix
    friendships       key (USR, USR)   adjacency + reverse
    logs              key LOG          store buckets            ttl id-range
  boundaries:
    cross-system: USR, COR carried as branded text (not FK)
    in-system:    bigint FK between component tables
```

A namespace line is a registry entry in `EchoData.Namespace` and the gate in `EchoData.Bcs.gate/2`. A component line is a table — the snowflake `bigint` primary key on disk, the ordered `EchoData.Bcs.Column` in memory — and, for a hot kind, a cache table in `EchoStore.Table`. A composite or adjacency component is a multi-column primary key, read by its left prefix. A retention of `id-range` is `EchoData.Buckets`. A boundary line is the rule that the crossing value is the branded text, decoded at the door, and the in-system reference is the eight-byte `bigint`. The declaration is small; the system is its expansion, and the namespace registry is the part every other line refers back to.

## The decision

Platform kinds take the three-letter space — curated, scarce, readable, registered in one place — and the observability triad `LOG`, `TRC`, `COR` are platform kinds because every system emits and reads them. Applications take the four-letter developer-space — roomy, collision-free, and free on every substrate the platform uses, because the namespace is metadata in memory and in the keyspace and is not stored on disk at all. A system is specified by its namespaces, its components, and its boundaries, and the namespace registry is the first declaration because it is the name the schema, the cache, and the gate all key on. The strongest alternative is one flat namespace space with no width distinction: it saves a classifier and loses a guarantee, because without the reserved three-letter space an application kind and a platform kind can collide, and the platform can no longer add a primitive without auditing every application first. The width split buys that guarantee for one free byte.

## Boundaries

The cost measurement is one substrate per engine at fixed versions; the size-class equivalence is specific to jemalloc under Valkey's quantum [3] and the word-bucket equivalence is this BEAM's, and neither is a portable promise. The registry's platform set is the project's own, illustrative rather than exhaustive — kinds are registered as the platform grows. The triad's access patterns, append-heavy and retention-bounded, are stated from the design, not benchmarked here; the on-disk and in-memory costs they lean on are measured in `bcs-db.out` and the identity package. The capacity counts assume an uppercase-letter alphabet, which is what the shape rule admits.

## References

1. Snowflake ID. https://en.wikipedia.org/wiki/Snowflake_ID
2. Trace Context — W3C Recommendation. https://www.w3.org/TR/trace-context/
3. jemalloc 5.3.0 release notes. https://github.com/jemalloc/jemalloc/releases/tag/5.3.0
