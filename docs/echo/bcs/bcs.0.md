# BCS · B0 — Overview
<show-structure depth="2"/>

B0 is the shortest path into the Branded Component System. Three dives carry the whole idea: the one move the system makes, the contract that move leaves behind, and the shape of the stack the rest of the course builds. Read these, and every later chapter is an elaboration of one of them. The course is served at `/bcs`; this chapter lives at `/bcs/overview`, and its dives at `/bcs/overview/the-relocation`, `/bcs/overview/identity-as-contract`, and `/bcs/overview/stack-and-floor`.

The id used throughout is a fourteen-byte printable name: a three-character namespace and eleven Base62 characters carrying a 63-bit snowflake — 41 bits of millisecond above a 2024-01-01 epoch, 10 of node, 12 of sequence. No number on these pages is a benchmark; the only figures shown are the contract's own, which the runtime asserts at boot.

## B0.1 · The one relocation

Object orientation drew the encapsulation boundary around the object: its data and the methods over that data lived together, and the boundary was the object's own surface. The Branded Component System keeps encapsulation and moves the boundary outward, around the system. The state an object used to hold privately now lives inside the system that owns it, and what leaves the object is the one thing a distributed program can carry between machines — its name.

The relocation promotes the name from a detail to the interface. A system no longer hands another system a reference to an object; it hands a branded identity and a message about it, and everything the receiver can do, it does by asking the owner. The coupling that once travelled as a shared object now travels as a question about a name.

The move looks like a loss — you give up the convenience of reaching into an object — and it buys three things the object model could not keep across a boundary: a value that survives the process, a value that means the same thing on another machine, and a value a database can hold and order. The rest of the course is the consequence of this one line, drawn around the system instead of the object.

The figure for this dive shows the move directly: on the left, the object model, with the boundary on the object itself; an arrow labelled *relocate the boundary*; and on the right, the system, its boundary around many private cells, with a single branded-id token at the edge as the interface.

## B0.2 · Identity as a contract

Because the name is the entire interface, it carries the weight a type used to. A branded identity is not a string; it is a contract with four properties, and each property answers a way the bare integer handle failed.

It is typed: the three-character namespace declares the domain class on the wire and to the type system, so a portfolio id cannot be passed where an order id is required. It is ordered: the name sorts as its mint instant sorts, so a table keyed by it is a timeline. It is placed: a single function, `hash32`, locates a row from the identity alone — `placement("USR0KHTOWnGLuC")` is `234878118`, the same for every holder. And it is conformant: one source of truth and one vector file make encode and decode identical across five runtimes, so which language runs is a deployment detail.

These are not aspirations; the runtime asserts them at boot. The self-check compares the native and pure code paths against the contract's vectors and refuses to start if they disagree:

```
placement("USR0KHTOWnGLuC")  →  234878118              (native and pure agree)
parse("USR0NgWEfAEJfs")      →  {:ok, "USR", 320636799581945856}
decode("USRzzzzzzzzzzz")     →  :error                 (an overflow is refused, not wrapped)
```

The name is trustworthy because the system proves it before trusting it. Those three lines are vectors `self_check!` asserts in `branded_id.ex` — source truths, not measurements.

## B0.3 · The stack and the floor

The course builds a stack, and the stack has a shape worth seeing before the chapters fill it in. At the top are your systems, written against BCS. Beneath them, `echo_data` provides the branded id, the property stores, and the CHAMP forest. Beneath that, `echo_mq` is the Valkey-native bus that moves work between systems. Then `echo_store` is the declared near-cache, holding hot state close to the systems that read it.

Those tiers are fast because they are volatile, and a system of record cannot be only volatile. The durable floor — Echo Persistence — sits beneath them: an ETS head, the Valkey bus and its L2, a durable local page tier on CubDB or Fjall, and a remote tier on Tigris. State lives somewhere fast and is made durable beneath, on a dial the system sets.

The line between the volatile tiers and the durable floor is the one the persistence chapter draws with care. Part I says state lives somewhere; Part II shows where in the heap; the floor chapter says where it lives when the heap is gone. Reading the stack top to bottom is reading the course in order.

## References

- [Leonard — Postmortem: Thief: The Dark Project](https://www.gamedeveloper.com/design/postmortem-i-thief-the-dark-project-i-) — the Dark Object System that relocated the boundary in shipping code.
- [The Go Project — Share Memory By Communicating](https://go.dev/doc/codewalk/sharemem/) — ownership behind a boundary, identities across it.
- [Hoare — Record Handling (ALGOL Bulletin 21, 1965)](https://archive.computerhistory.org/resources/text/Knuth_Don_X4100/PDF_index/k-9-pdf/k-9-u2293-Record-Handling-Hoare.pdf) — the tag inside the value, with access guarded by it.
- [King — Announcing Snowflake (2010)](https://blog.twitter.com/engineering/en_us/a/2010/announcing-snowflake) — the roughly-sortable id the contract hardens to exact per node.
- [Erlang/OTP — the ets module](https://www.erlang.org/doc/apps/stdlib/ets.html) — ordered_set term order and per-table protection.
- [lucaong — CubDB](https://github.com/lucaong/cubdb) — the durable local page tier in the floor.
- [Tigris — Object conditionals](https://www.tigrisdata.com/docs/objects/conditionals/) — the create-only fence on the remote tier.
- [Valkey — Streams](https://valkey.io/topics/streams-intro/) — the Valkey-native bus echo_mq is built on.
