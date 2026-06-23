# BCS · B2 — The Elixir BCS Core
<show-structure depth="2"/>

B2 is Part II of the Branded Component System: the law landed on OTP. Three dives carry it — a system as a supervised process, state as a branded keyspace on ETS, and a relation as a system of its own. The chapter is served at `/bcs/elixir-core`; its dives at `/bcs/elixir-core/otp-application`, `/bcs/elixir-core/property-stores`, and `/bcs/elixir-core/relations`.

Every surface here is real source under `echo_data/bcs`. Where a dive makes a performance or size claim the figure rides a committed benchmark output and appears only once that output is in the tree; the only number shown is the contract's own placement vector, asserted at boot.

## B2.1 · A system is an OTP application

The law's first clause — a system owns its state behind a boundary no other system reaches through — is, on the BEAM, a sentence about processes. A system is a supervised process; its state is unreachable except by message, so the runtime enforces the boundary rather than leaving it to discipline. `EchoData.Bcs.Supervisor` brings the system up: `start_link(stores)` starts one `EchoData.Bcs.PropertyStore` child per `{name, namespace}`, each a supervised boundary under one tree, and restarts a child that falls.

Inside a system the pattern is pure-core-and-shell. The decisions are total functions with no side effects; the GenServer is a thin shell that owns the ETS table and serializes access to it. A call arrives, the shell hands the relevant state to the pure core, the core returns a decision, and the shell applies it and replies. The interesting logic stays testable without a running process, and the effects live at the boundary.

The system topology is therefore a supervision tree of branded boundaries. A namespace is not a string prefix on shared rows; it is a process with its own private table and its own gate. Adding a system is adding a child to the tree, and the tree is the architecture made executable — ownership, isolation, and restart, all from the runtime.

## B2.2 · Property stores on ETS

A system's state is a property store: an ETS table created `:ordered_set` and `:private`, whose only key is the branded id and whose value is a property bundle. `:private` is the boundary — only the owning process reads it, so a lookup from outside raises rather than returning a forbidden row. `put(store, id, value)` writes the bundle under the id; `get(store, id)` reads it; `record_entity` notes that the system owns a name.

Because the id sorts as its mint instant sorts, `:ordered_set` keeps the table in time order, and the store needs no clock column. `page_desc(store, n)` reads a newest-first page by taking `:ets.last` and walking back through `:ets.prev`, n times; `window(store, lo, hi)` reads a time range as a key-range `:ets.select`. A feed and a window come from the shape of the key, not from a timestamp the system has to maintain.

The store also answers where a row belongs without a side table. `placement(id)` parses the id and routes it through `hash32` — `placement(USR0KHTOWnGLuC)` is `234878118` — the same function that locates a cache shard or a partition. One placement idea, reused: the store, the cache, and the bus all address a row from its identity alone.

The self-check asserts, in `branded_id.ex`, before either code path is trusted:

```
placement("USR0KHTOWnGLuC")  →  234878118              (native and pure agree)
parse("USR0NgWEfAEJfs")      →  {:ok, "USR", 320636799581945856}
decode("USRzzzzzzzzzzz")     →  :error                 (an overflow is refused, not wrapped)
```

## B2.3 · Relations are systems

The component-system tradition kept a relation as a list of ids embedded in an entity — the fat struct returning by another door. In BCS a relation is a system of its own. `EchoData.Bcs.EdgeStore` is one owning process for one kind of edge; *portfolio holds asset* is a row keyed by the tuple of the two branded ids, carrying its own properties, embedded in neither endpoint.

The relation has a type, and the type is enforced at its boundary. The store is configured with a relation and the namespaces it joins; the subject and object ids are gated on the way in, so a mismatched end is refused before the edge is written. A relation can only be drawn between the kinds it is declared to hold, and the wrong-kind edge is a checked error.

An edge store keeps two private `:ordered_set` indexes, forward and reverse. A subject's edges are a key-range read on the forward index; an object's back-references are a key-range read on the reverse one; a delete clears both directions together. The relation is readable and countable from either side, owns itself, and is referenced by id from the entities it joins — never embedded in them.

## References

- [Erlang/OTP — Supervisor](https://www.erlang.org/doc/apps/stdlib/supervisor.html) — the supervision tree the system topology is built from.
- [Erlang/OTP — gen_server](https://www.erlang.org/doc/apps/stdlib/gen_server.html) — the shell that owns the table and serializes access.
- [The Go Project — Share Memory By Communicating](https://go.dev/doc/codewalk/sharemem/) — the same boundary in another runtime: a goroutine owning its state.
- [Erlang/OTP — the ets module](https://www.erlang.org/doc/apps/stdlib/ets.html) — the two ordered_set indexes the edge store keeps.
- [King — Announcing Snowflake (2010)](https://blog.twitter.com/engineering/en_us/a/2010/announcing-snowflake) — the time-high layout that makes the key a timeline.
- [Söderqvist — A new hash table (Valkey, 2025)](https://valkey.io/blog/new-hash-table/) — the same key, costed at rest on the L2 store.
- [Leonard — Postmortem: Thief: The Dark Project](https://www.gamedeveloper.com/design/postmortem-i-thief-the-dark-project-i-) — relations between two objects as a first-class table.
- [Hoare — Record Handling (ALGOL Bulletin 21, 1965)](https://archive.computerhistory.org/resources/text/Knuth_Don_X4100/PDF_index/k-9-pdf/k-9-u2293-Record-Handling-Hoare.pdf) — the typed reference the gate enforces on each end.
