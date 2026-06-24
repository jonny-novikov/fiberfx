# BCS · B1 — Ideas Behind
<show-structure depth="2"/>

B1 is Part I of the Branded Component System: the conceptual floor every later chapter stands on. Three dives carry it — the law made executable as a process owning a private table, the identity contract read as architecture, and the gap in the Entity-Component-System pattern that branding fills. The chapter is served at `/bcs/ideas`; its dives at `/bcs/ideas/the-substrate`, `/bcs/ideas/the-contract`, and `/bcs/ideas/ecs-to-bcs`.

Part I argues by assertion and derivation. Where a dive would make a size or speed claim, the number rides a committed benchmark output and appears only once that output is in the tree; the only figures shown here are the contract's own, which the runtime asserts at boot.

## B1.1 · The system substrate

The smallest faithful system is one process. It owns a private table keyed only by a branded id; nothing outside reads it except by sending a message, so the law's first clause — ownership behind a boundary — is enforced by the runtime rather than by convention. A supervisor starts the process and restarts it if it falls; the boundary is the process, and the process has an owner.

The table holds one kind of key, the branded id, and a property bundle as its value. There is no surrogate key and no composite. The entity is the name, and the table is this system's view of the names it owns. A read is a lookup by id; a write replaces the bundle under that id.

Because the id sorts as its mint instant sorts, the table is already in time order — no timestamp column, no clock. A newest-first page is the last row walked backward; a time window is a contiguous range of keys. The order theorem turns storage order into chronology, so the substrate gets a feed and a window from the shape of the key alone.

## B1.2 · The identity contract

A bare integer handle is enough inside one process and fails the moment it leaves. The branded contract is best read as four answers to four of those failures, each property earning its place by retiring a specific weakness.

The integer is untyped — nothing stops a portfolio id being passed where an order id belongs — and the namespace fixes it: three characters declare the domain class on the wire and to the type system, and the gate refuses a foreign one before a handler runs. The integer has no inherent order across systems; the contract's order theorem gives it one, because the name's lexicographic order is its mint order, and a table keyed by it is a timeline.

The integer needs a side table to say where its row lives; the contract carries placement in the value — `hash32` locates a row from the identity alone, and `placement(USR0KHTOWnGLuC)` is `234878118`, the same on every holder and on both the native and pure code paths. And the integer means different things in different languages; the canon — one source, one vector file — makes encode and decode identical across five runtimes, so the runtime is a deployment detail. The self-check asserts the native and pure paths agree at boot, or the system refuses to start.

The self-check asserts, in `branded_id.ex`, before either code path is trusted:

```
placement("USR0KHTOWnGLuC")  →  234878118              (native and pure agree)
parse("USR0NgWEfAEJfs")      →  {:ok, "USR", 320636799581945856}
decode("USRzzzzzzzzzzz")     →  :error                 (an overflow is refused, not wrapped)
```

## B1.3 · From ECS to BCS

The Entity-Component-System pattern was right to give each system a clean boundary, and incomplete in what it let cross: a process-local integer index. That index is a fine handle while the process lives, and it dies three times the moment it leaves.

It dies at the save file, because an index means nothing after the process that issued it exits. It dies at the socket, because an index on one machine names a different row on another. And it dies at the foreign store, because a database has nothing to hold or order it by, and no type to catch a join against the wrong table. Each death is the absence of a contract property: stability past the process, one identity scheme across machines, a printable ordered key a store can keep.

The branded id fills each gap — minted once and never re-derived, unique across machines by its node bits, printable and ordered for a store to hold — so the move from ECS to BCS is a short translation. An entity becomes a branded id; a component becomes a property row keyed by that id; a system becomes a process owning those rows behind a namespace gate. The pattern keeps its boundary and gains a value strong enough to leave it.

## References

- [Erlang/OTP — the ets module](https://www.erlang.org/doc/apps/stdlib/ets.html) — the per-system table the component row lands in.
- [The Go Project — Share Memory By Communicating](https://go.dev/doc/codewalk/sharemem/) — the owner-goroutine counterpart: sequential access by construction.
- [King — Announcing Snowflake (2010)](https://blog.twitter.com/engineering/en_us/a/2010/announcing-snowflake) — the node-and-sequence layout that makes the id unique without coordination.
- [Hoare — Record Handling (ALGOL Bulletin 21, 1965)](https://archive.computerhistory.org/resources/text/Knuth_Don_X4100/PDF_index/k-9-pdf/k-9-u2293-Record-Handling-Hoare.pdf) — the tag inside the value, the type system guarding access by it.
- [Leonard — Postmortem: Thief: The Dark Project](https://www.gamedeveloper.com/design/postmortem-i-thief-the-dark-project-i-) — the Dark Object System: properties and relations over object handles.
