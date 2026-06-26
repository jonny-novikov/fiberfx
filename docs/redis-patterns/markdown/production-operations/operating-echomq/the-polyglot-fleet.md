# R8.06.3 · The polyglot fleet

> Dive · `/redis-patterns/production-operations/operating-echomq/the-polyglot-fleet`
> The branded id is *conformant* — one canon across five runtimes, the basis for a polyglot worker fleet.

Scaling a job system eventually means more than more workers in one language. A platform grows services in
whatever runtime fits — a Go ingestion worker, a Node webhook handler, a WASM edge function — and they all
want to drain the same queues. That only works if every runtime agrees, byte for byte, on the one value
that crosses every boundary: the identity. The 14-character branded id is built for exactly that, and its
fourth property — *conformant* — is what a polyglot fleet depends on.

## The four properties, and the fourth that scales

A branded id is a 3-character uppercase namespace plus 11 Base62 characters carrying a 63-bit snowflake
`ts(41) | node(10) | seq(12)`. It has four properties:

- *typed* — the namespace declares the domain class on the wire and in the type system;
- *ordered* — the name sorts as its mint instant sorts, so a table keyed by it is a timeline;
- *placed* — one function, `hash32`, locates a row from the identity alone;
- *conformant* — one source of truth and one vector file make encode and decode identical across five
  runtimes: Elixir, Node, Go, PostgreSQL, and WASM. Which language runs is a deployment detail.

Conformance is the property a fleet needs. If a Go worker and the Elixir bus disagree by one bit on how an
id encodes, the Go worker cannot read a `JOB` key the bus wrote — the fleet is broken at the identity. One
canon, one vector file, removes that failure mode by construction.

## The vectors, proven at boot

Conformance is not a claim on a slide — it is asserted at boot. `self_check!` mints, encodes, decodes, and
hashes a known id down both the native and pure-Elixir paths and checks each result against a committed
vector. A node whose native core disagrees with the pure one never reaches its first message. The committed
vectors, verbatim:

```
placement("USR0KHTOWnGLuC")  →  234878118              (native and pure agree)
parse("USR0NgWEfAEJfs")      →  {:ok, "USR", 320636799581945856}
decode("USRzzzzzzzzzzz")     →  :error                 (an overflow is refused, not wrapped)
```

The `placement` line is the *placed* property read at boot: the id `USR0KHTOWnGLuC` encodes the snowflake
`274557032793636864`, and `hash32(274557032793636864)` is `234878118` down both paths. The `parse` line
proves a round trip recovers the namespace and the snowflake exactly. The `decode` line proves the codec is
total in the safe direction — `USRzzzzzzzzzzz` would overflow 63 bits, and the codec answers `:error`
rather than wrap to a wrong number. These are source truths, not benchmarks — no number on this page is a
measurement.

The `USR` namespace in these vectors is the manuscript's illustrative brand for teaching the id contract; it
is the figure exactly as the runtime asserts it. A real application uses its own brands — codemojex mints
`PLR`, `ROM`, `GAM`, `GES`, and `JOB`.

## The honest frame — the conformance target

What ships today is honest to state: the bus is Elixir, in `echo/apps/echo_mq`. A Go or Node worker fleet
does not run in production now. The polyglot fleet is the conformance *target* — the wire protocol and the
id contract are precisely what make it reachable, because a worker in any of the five runtimes can mint,
parse, and place the same id and address the same braced keys over the same wire. The id is the thread that
ties a worker to the bus regardless of the worker's language.

That target is the dedicated EchoMQ course's subject — the polyglot protocol, the full Lua inventory, and
the conformance suite that proves a second runtime agrees with the first. This dive is the door to it.

## The bridge

| The pattern — share one identity canon across runtimes | Its EchoMQ application |
|---|---|
| One source of truth and one vector file make an id encode and decode identically everywhere, so any runtime can address the same data | the branded id is *conformant* across Elixir, Node, Go, PostgreSQL, and WASM; `self_check!` asserts `placement("USR0KHTOWnGLuC") → 234878118` at boot, so a polyglot worker fleet can drain one bus over one wire |

The take: a polyglot fleet is possible only when the identity is conformant. One id canon, proven at boot
against committed vectors, lets a worker in any of five runtimes share the bus — the conformant id is the
contract that makes the wire portable.

## The production angle

When the fleet grows beyond Elixir, the wire and the id contract are already in place: a new-runtime worker
implements the same codec, passes the same vector file, and drains the same braced queues. For codemojex,
the bot workers draining the `cm` queue are an Elixir fleet today, and they mint the conformant ids —
`PLR`, `ROM`, `GAM`, `GES`, `JOB` — that a future polyglot worker would share. The protocol that makes a
second runtime a peer on the bus is the dedicated EchoMQ course.

## References

### Sources

- [Snowflake ID — *Twitter Engineering*](https://blog.twitter.com/engineering/en_us/a/2010/announcing-snowflake) — the
  time-ordered, coordination-free id the 63-bit `ts | node | seq` layout descends from.
- [Base62 — *Wikipedia*](https://en.wikipedia.org/wiki/Base62) — the printable encoding the 11-character
  payload uses, the basis for a cross-runtime canon.
- [PostgreSQL — *Functions*](https://www.postgresql.org/docs/current/functions.html) — one of the five
  runtimes the id canon conforms across, where the codec is a stored function.

### Related in this course

- [R8.06 · Operating EchoMQ](/redis-patterns/production-operations/operating-echomq) — the module hub.
- [R8.06.1 · Cluster colocation](/redis-patterns/production-operations/operating-echomq/cluster-colocation) — the braced keys the fleet addresses.
- [R8.06.2 · Prometheus and OpenTelemetry](/redis-patterns/production-operations/operating-echomq/prometheus-and-opentelemetry) — observing the fleet's work.
- [R7.04 · Bitmap patterns](/redis-patterns/data-modeling/bitmap-patterns) — the same `hash32` placement read as a bit offset.
- [/echomq · the Proof pillar](/echomq/proof) — conformance, telemetry, and the production evidence the bus carries.
- [/bcs · The bus](/bcs/bus) — EchoMQ and the branded keyspace as the architecture.
