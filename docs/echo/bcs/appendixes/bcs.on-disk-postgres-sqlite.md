# BCS · On Disk — PostgreSQL and SQLite for a Branded Component System

<show-structure depth="2"/>

Inside a system's database the primary key is the snowflake as a `bigint`; the fourteen-byte branded text is the value that crosses a boundary, not the value that keys a row. This article measures that decision on PostgreSQL 16 and SQLite 3.45 — primary-key forms, the two clocks an id carries, and the schema for Sessions, Users, composite Profiles, and Friends — then follows the rows into the near-cache that fronts the database for graph reads.

## Scope and method

Two engines at fixed versions: PostgreSQL 16.14 (C locale, so text keys compare by byte order, which for base62 is mint order) and SQLite 3.45.1. 
One canonical dataset of five hundred thousand entities, generated once with the project's real base62 branding (`EchoData.BrandedId`) so the `bigint`, branded-text, and UUIDv7 forms describe the same identities; the same generator emits five hundred thousand friendship edges. 
Sizes are read from `pg_relation_size` and from vacuumed SQLite file bytes; plans from `EXPLAIN`. 
Every figure below appears verbatim in `evidence/bcs-db.out`; the schema is `schema.postgres.sql` and `schema.sqlite.sql`, both applied and exercised. What is measured: key-form storage, the mint-versus-insert clock gap, the sweep and adjacency plans. What is cited: the snowflake and UUIDv7 layouts, the two engines' storage rules, and the social-graph store this design echoes. What is out of frame: replication, sharding, and multi-node ordering.

## The question: which value is the key

A branded id is a text value of a three-letter namespace and an eleven-character base62 body encoding a sixty-three-bit snowflake, `ts(41) | node(10) | seq(12)` against the 2024-01-01 epoch [1]. The snowflake is the integer underneath; the branded text is its readable, namespaced projection. Both exist. The database question is narrow: which one goes in the primary-key column.

Three candidates present themselves. The snowflake as `bigint` — eight bytes, monotone, the integer the id already is. The branded text — fourteen bytes, readable, globally unique across namespaces, the form that appears in URLs, logs, and API payloads. A UUIDv7 — sixteen bytes, the standard time-ordered external identifier [2]. The BCS position falls out of the same observation the in-memory column rested on: a component table holds one namespace, so the namespace is a property of the table, not of every row. Storing it in each key — as the branded text does — repeats a constant. The snowflake keys the row; the branded text is composed at the edge and decoded at the door.

## What the engines reward

Before the numbers, what each engine does with a key.

PostgreSQL stores the row in a heap and the primary key in a separate B-tree. An index entry pays a tuple header and alignment to an eight-byte boundary, so the key's own width matters in steps: an eight-byte `bigint` and a fifteen-byte branded text and a sixteen-byte UUID do not cost in proportion to eight, fifteen, and sixteen — the two wider forms round to the same tuple, while the `bigint` rounds smaller. A monotone key means inserts arrive in key order, landing at the right edge of the index rather than splitting interior pages, which keeps the index compact. The derivation: `bigint` smallest, branded text and UUID equal and larger.

SQLite is sharper. A rowid table *is* a B-tree keyed by a sixty-four-bit rowid, and when the declared primary key is a single `INTEGER` column, that column becomes an alias for the rowid — the row lives in the primary-key tree with no second structure [3]. Any other key, including a text primary key in a rowid table, is a separate UNIQUE index beside the hidden rowid: two trees [3]. A `WITHOUT ROWID` table clusters on the declared key instead, so a fourteen-byte text key threads through every interior node [4]. A sixty-three-bit snowflake is a positive sixty-four-bit integer, so it fits the rowid alias exactly. The derivation: the snowflake as `INTEGER PRIMARY KEY` is the compact case by a wide margin; a text key either doubles the trees or fattens every node.

## Measured: the primary key

```text
## PRIMARY KEY FORM — PostgreSQL, 500000 rows, C locale
  table   | heap  | pk_index | heap_b_row | pk_b_row | total
 u_bigint | 25 MB | 11 MB    |       52.2 |     22.5 | 36 MB
 u_text   | 29 MB | 15 MB    |       60.2 |     31.6 | 44 MB
 u_uuid   | 29 MB | 15 MB    |       60.2 |     31.6 | 44 MB

## PRIMARY KEY FORM — SQLite, 500000 rows, vacuumed (file bytes)
  u_int      11997184 B  (24.0 B/row)   id integer primary key             -- rowid alias, no 2nd index
  u_txt      28565504 B  (57.1 B/row)   id text primary key                -- rowid table + text index
  u_txt_wr   15532032 B  (31.1 B/row)   id text primary key WITHOUT ROWID  -- clustered 14-byte key
```

The prediction holds on both engines. **On PostgreSQL the `bigint` key is the smallest in index and in heap** — its primary-key index is 22.5 bytes per row against 31.6 for the other two, and its heap is 52.2 against 60.2, for a total schema 36 MB against 44 MB. **The branded text costs exactly what a UUID costs** — 31.6 and 60.2 for both — the alignment step swallows the one-byte difference between fifteen and sixteen, so a readable key is no cheaper than an opaque one once you leave `bigint`. **On SQLite the gap is severe**: the snowflake as `INTEGER PRIMARY KEY` is 24.0 bytes per row, the text primary key 57.1, the `WITHOUT ROWID` text 31.1. The naive text key is 2.4 times the integer because it carries a whole second B-tree; even the clustered form is a third larger, its fourteen-byte keys in every node. The loss recorded beside the win: the `bigint` is not readable and carries no namespace, which is the cost the boundary projection pays back.

## Two clocks

A row carries two timestamps that look alike and are not. The snowflake holds a `ts` field — the moment the id was minted, on the app node that minted it. A `created_at` column holds `now()` — the moment the row committed, on the database server. Two clocks, two machines, two events.

```text
## TWO CLOCKS — PostgreSQL, mint_at (generated from snowflake) vs inserted_at (now())
         id         |          mint_at           |          inserted_at          | lag_seconds
 325357439706726402 | 2026-06-16 19:34:18.475+00 | 2026-06-16 19:44:18.475468+00 |       600.0
 325359956289126401 | 2026-06-16 19:44:18.475+00 | 2026-06-16 19:44:18.475468+00 |         0.0
```

Both rows were inserted at the same instant; their mint clocks stand 600.0 seconds apart. The gap is real in any system where an id is assigned before its row lands — minted at request entry and inserted after validation, minted into a queue and written on drain, minted on one node and migrated to another. The mint clock is not the insert clock.

The stance BCS takes: the snowflake `ts` is the creation and ordering truth. It is embedded, so it is identical in every system that holds the id and survives a copy to another database unchanged; it is monotone, so the primary-key B-tree is already a time index. Reading newest-first needs no `created_at` index:

```text
## CHRONOLOGICAL FOR FREE — ORDER BY id DESC is the PK read
 Index Only Scan Backward using u_bigint_pkey on u_bigint
```

And expiry needs no `expires_at` index, because a session minted before a cutoff is expired by arithmetic on its own key:

```text
## GENERATIONAL SWEEP — delete where id < cutoff rides the PK
 Delete on sessions
   ->  Bitmap Heap Scan on sessions
         ->  Bitmap Index Scan on sessions_pkey
```

The mint clock is free to read, too: a generated column derives it from the key with no second clock and no second column written by hand — `STORED` on PostgreSQL, where only stored generated columns exist [5], and `VIRTUAL` on SQLite, where a read-time expression costs no storage at all [3]. So `created_at` earns its place only as the persistence clock: the database's own record of when the row arrived, kept for audit, for measuring mint-to-persist lag, and for backfilled rows whose mint time is old but whose insert time is the migration. It answers a question the snowflake cannot — when did this store first hold this — and the snowflake answers one it cannot: when was this identity born, everywhere at once. Neither is redundant; only one needs an index, and that one is the key. The caveats are worth stating: the snowflake's `ts` is millisecond-resolution and monotone per node but not globally across nodes, and its forty-one bits run out near 2093; for strict cross-node order the database clock or a logical clock is the authority, while BCS orders within a system by the key and across systems by the eleven-byte body.

## The four entities

The boundary rule governs every table. Inside one system's database, foreign keys are `bigint` — eight-byte joins between component tables that share an entity's snowflake. Across a *system* boundary only the identity travels, as the branded text, and it is not a foreign key here: a session row referencing a user carries the user's id, but the constraint that the user exists lives in the user system, not in a cross-database key. The schema files carry the full data definition; the shape is the argument.

**Users** (namespace `USR`) is the canonical identity, kept lean — the entity *is* the identity, and rich attributes live in profile components. The key is the snowflake; `handle` and `email` carry unique indexes; `mint_at` is generated, `inserted_at` defaults to `now()`. Other systems hold `USR…`, never a join into this table.

**Sessions** (namespace `SES`) is the high-churn case the generational sweep was built for. The key is the session's snowflake, whose `ts` is the issue time; `user_id` is the boundary reference to the owner; `last_seen_at` is a third, mutable, activity clock. Expiry is `DELETE FROM sessions WHERE id < floor`, a range on the primary key, so no row carries an `expires_at` and no index tracks one — the `EchoData.Buckets` generational pattern, expressed in SQL.

**Profiles** (composite, namespace `USR`) is where the Entity Component System lineage shows. A profile is not a table; it is a composite of component tables, each keyed by the same user snowflake. A 1:1 component — display name, preferences — shares the entity key as its own primary key. A multi-valued component — addresses — takes a composite primary key of two snowflakes, the entity's and the component's:

```sql
create table profile_addresses (
  user_id    bigint not null,           -- USR (the entity)
  address_id bigint not null,           -- ADR (the component instance)
  kind smallint, line1 text, city text, country text,
  primary key (user_id, address_id)     -- a user's addresses = the PK prefix
);
```

Reading a user's addresses is the left-prefix of that key; assembling the whole profile is a join of the components on `user_id`. The composite is computed at read time, not stored as one wide row, which is what lets a component change without rewriting the rest — the `EchoData.Bcs.Archetypes` idea on disk.

**Friends** (namespace `FRD`) is the graph. A friendship is an edge between two `USR` identities, and the adjacency table keys on the pair, so a user's friends are a prefix range scan:

```text
## FRIENDSHIPS — PostgreSQL, 500000 edges
  edges=500000  heap=29 MB  pk_forward(user_id,friend_id)=16 MB  bytes_per_edge=93.2
  reverse_index(friend_id,user_id)=15 MB
  a user's friends:
    Index Only Scan using friendships_pkey on friendships (actual rows=25 ...)  Execution Time: 0.084 ms
```

The forward primary key answers the friends of a user as an index-only scan, twenty-five rows in 0.084 ms. An undirected friendship is stored as two rows, `a→b` and `b→a`, kept in sync — the inverse-association discipline of Facebook's TAO, which keeps bidirectional edges consistent by configuring an inverse type [6] — so both endpoints read their neighbours from the forward key, and the reverse index, a further 15 MB, serves only the directed inbound case (followers). Recency — a user's most recent friends — is `ORDER BY edge_id DESC`: the edge has its own snowflake, its own mint clock, and so its own time order. SQLite stores the same adjacency `WITHOUT ROWID`, 22.2 bytes per edge, and reads it the same way:

```text
## FRIENDSHIPS — SQLite, 500000 edges, WITHOUT ROWID (user_id, friend_id)
  file=11096064 B  (22.2 B/edge)
  a user's friends:  SEARCH fr USING PRIMARY KEY (user_id=?)
```

## Loading graphs and dependencies in the near-cache

The database is the cold truth; the read path is the near-cache. `EchoCache` holds L1 ETS tables over the shared L2 Valkey, keyed by the branded id, and the database answers only misses. The interesting reads are not single rows but neighbourhoods, and there are two shapes.

The first is the composite. Loading a profile is loading its components for one identity — the core user, the display component, the preferences, the addresses. Two strategies trade against each other. Cache the assembled composite under the user's id, and reads are one hit but any component write invalidates the whole entry; the entry needs a version that is the maximum of its components' versions, or a coarse profile version bumped on any write. Cache the components separately, and a write invalidates only its component while reads assemble from several hits. BCS leans toward components: the coherence lane already invalidates by the eleven-byte body of a version id (`EchoCache.Coherence`), newer-wins and idempotent, so a per-component version is the natural unit, and the composite is rebuilt from parts the way the SQL profile is a join. The disk shape and the cache shape agree.

The second is the graph. A social view of user A is A's profile, then A's friends, then each friend's profile — a dependency closure, not a row. It loads in two phases. First the edges: A's adjacency, itself a cacheable component (`user_id → friend snowflakes`), filled on miss by the prefix scan above. Then the nodes: the friends' profiles, each independently cached and independently invalidated. The phases are why the edge list and the node are different cache entries with different lifetimes — an edge list churns on friend add and remove, a profile on profile edits — and why a friend-list change need not touch any profile. The fan-out is bounded and resolved by pulling, not pushing: the view is assembled at read time from the cached neighbourhood rather than precomputed on write, the choice TAO makes for the same reason — a page aggregates hundreds of graph items filtered per viewer, so materializing on write is infeasible and the store is read-optimized over a fixed query set [6].

Three mechanics keep the closure cheap. The friend snowflakes collected in phase one are resolved in one batch — a single multi-get against L2 and a single `WHERE id = ANY(:ids)` against the database — so a hundred friends are one round trip, not a hundred; this is where the `bigint` key pays again, an eight-byte `ANY` array against a fourteen-byte one. The single-flight gate in `EchoCache.Table` collapses a thundering herd on a hot node — a celebrity profile filled once while a thousand readers wait on the one fill. And the coherence lane carries invalidation by version-body comparison, so a profile write reaches every cache holding it, a friend add invalidates one adjacency entry, and a late or duplicate message is a comparison that answers stale the second time. The graph in the cache is the graph on disk — objects keyed by a sixty-four-bit id, edges as adjacency with a time field — which is the model TAO names: typed nodes and typed directed edges, a cache layer over a persistent store, with cache and store scaled and tuned apart [6].

## The decision

For a system's own database, the primary key is the snowflake as `bigint` on PostgreSQL and as `INTEGER PRIMARY KEY` on SQLite — the smallest index, the rowid alias, the monotone key that doubles as the time index and the expiry cursor, the eight-byte foreign key between component tables. The branded text is the boundary projection: composed at the edge, carried across system boundaries, written into the L2 cache key and into API payloads and logs, decoded by the gate on the way in, and never the storage key, because within one system its namespace is a constant. A profile is a composite of component tables sharing the entity key; a friendship is adjacency on the pair, stored both ways, ordered by the edge's own snowflake.

The strongest outside choice is UUIDv7 as a single identifier everywhere, storage and boundary both. It is broadly portable and time-ordered [2], and a team that values one identifier over a custom integer-plus-projection can adopt it and pay the measured width — 31.6 bytes of index per row against the `bigint`'s 22.5 on PostgreSQL, a whole extra B-tree against the rowid alias on SQLite. The two clocks resolve the same way under any of these keys: the embedded mint time is the creation and order truth, derived into a generated column at no second clock; `created_at` is the persistence clock, kept where the database's own event matters, indexed only when persistence-time queries demand it.

## Boundaries

The sizes are single-node, freshly loaded, and vacuumed; they do not model bloat under update churn, autovacuum timing, replication, or sharding. PostgreSQL ran with `fsync` off and a 256 MB buffer for load speed, which affects timing, not the relation sizes reported. The index-tuple alignment that makes a fourteen-byte text key cost a sixteen-byte UUID is PostgreSQL 16 behaviour; the rowid-alias and `WITHOUT ROWID` rules are SQLite's and have held across its 3.x line [3][4]. The branded id's monotonicity is a property of the snowflake generator, not of the database; the fixnum-versus-bignum distinction that shaped the in-memory key is a BEAM concern and does not appear here, where `bigint` is eight bytes throughout. The graph section describes a read path and its cache shapes; it measures the disk adjacency, not cache hit rates, which depend on the workload.

## References

1. Snowflake ID. https://en.wikipedia.org/wiki/Snowflake_ID
2. RFC 9562, Universally Unique IDentifiers (UUID), including version 7. https://www.rfc-editor.org/rfc/rfc9562.html
3. Rowid Tables — SQLite. https://sqlite.org/rowidtable.html
4. The WITHOUT ROWID Optimization — SQLite. https://sqlite.org/withoutrowid.html
5. Generated Columns — PostgreSQL 16 Documentation. https://www.postgresql.org/docs/16/ddl-generated-columns.html
6. N. Bronson et al., TAO: Facebook's Distributed Data Store for the Social Graph, USENIX ATC 2013. https://www.usenix.org/system/files/conference/atc13/atc13-bronson.pdf
