# The door to EchoMQ

> Route: `/redis-patterns/overview/patterns-become-protocol/the-door-to-echomq` · Module R0.3 · dive 3 ·
> Grounding: `docs/echo/bcs/content/bcs3.2.md` (the script is the contract) · `bcs3.3.md` (the Go consumer
> loop, verbatim) · `bcs3.1.md` + `bcsA.md` (the slot figures) · `docs/echo_mq/emq.design.md` (the wire form,
> the ladder statuses).

An owned protocol buys one thing: any runtime that loads the same scripts against the same grammar speaks the
same bus. No port, no shared codebase — a contract. The contract has three clauses: **the script is the
contract** (same bytes, same SHA1, same semantics), **the branded id is the wire form** (keys, set members,
payloads — fourteen bytes everywhere), and **one queue answers one slot by grammar** (the hashtag is the queue
name). This dive retells the contract, places the bus in the BCS build, and opens the live doors.

## §1 · The script is the contract; the id is the wire form

The cross-runtime story needs no port at all. The six scripts are the contract: the same source string yields
the same SHA1, and any client on any runtime that loads it speaks identical semantics — the same pop, the same
token mint, the same lease arithmetic. A producer in Elixir runs `enqueue`; a consumer in Go is a loop around
the same EVALSHA calls (`bcs3.3`, verbatim):

```go
id, payload, token, ok := claim(conn, q, lease)
if !ok { time.Sleep(idle); continue }
if err := work(payload); err != nil {
    retry(conn, q, id, token, backoff(attempt), maxAttempts, err.Error())
} else {
    complete(conn, q, id, token)
}
```

The second clause makes the data legible everywhere: **the branded form is the wire form**. Job ids are branded
Snowflakes — three-letter namespace, base62 body, fourteen bytes — and they appear as themselves in keys, set
members, and payloads. Byte order is mint order, so any runtime browses newest-first from the bytes alone, and
the decimal rendering stays internal arithmetic.

## §2 · One queue, one slot, by grammar

The third clause is spatial. The hashtag is the queue name, so every key of one queue answers one cluster slot
— the committed lines hold the figures: `pending, active, meta, and the job row of {orders} all answer slot
105; {fills} answers 4165`, with the payments queue at `8507` and the client-side CRC16 asserted against the
specification vector `12739`. The consequence is the part's future: every per-queue transition script is
single-slot legal **by grammar**, so the clustered day needs no wire change — and cross-queue choreography goes
through the application, never through a multi-queue script.

> **Notes on Valkey.** Hash tags exist to ensure that multiple keys are allocated in the same hash slot —
> CRC16 modulo 16384 over the tag — [valkey.io/topics/cluster-spec](https://valkey.io/topics/cluster-spec/).

## §3 · The placement — the bus and the near-cache

In the BCS build the contract has an address. **EchoMQ is the bus**: the queue patterns of this course —
atomic moves, leases, schedules, the morgue — live in its bundle, backed by Valkey under the hood.
**EchoCache is the near-cache in front**: branded keys, local speed, bus-driven coherence — an L1 of ETS
tables over the shared L2 Valkey. The cache family of this course lands in EchoCache; the queue, coordination,
time, and flow families land in the bus. One engine, two surfaces, and the patterns of the catalog map onto
them chapter by chapter.

## §4 · The doors

This is where the module hands off, and the doors are real routes now.

- **[/echomq](/echomq)** — the protocol, taught rung by rung: the grammar, the bundle, the fence, conformance
  on Valkey. Living status: emq.1 built · emq.2 specced · emq.3–5 drafted · emq.6 specced.
- **[/bcs](/bcs)** — the Branded Component System: the architecture the bus and the near-cache are built
  inside, every figure from a frozen transcript.
- **[/elixir](/elixir)** — the functional-Elixir craft, and the echo umbrella where the EchoMQ reference runtime lives.

**The pattern → its EchoMQ application.** A shared, written-down contract makes two systems interoperate
without shared code. EchoMQ's contract is the scripts, the branded wire form, and the slot-by-grammar law — an
Elixir producer and a Go consumer share one queue because both load the same bytes. With this dive, the
Overview chapter closes and the pattern chapters begin.

## References

### Sources
- [Valkey — Cluster specification](https://valkey.io/topics/cluster-spec/) — hash slots, CRC16 modulo 16384, and hash tags as the same-slot mechanism.
- [Valkey — Programmability](https://valkey.io/topics/programmability/) — scripts cached by SHA1; the dispatch the contract rides.
- [Redis — Documentation](https://redis.io/docs/) — the shared store the runtimes read and write through the grammar.
- [llmstxt.org — The llms.txt convention](https://llmstxt.org/) — the machine-readable maps this course and the EchoMQ course publish.

### Related in this course
- [R0.3 · Patterns become protocol](/redis-patterns/overview/patterns-become-protocol) — the module hub; the pager loops back here.
- [R0.3.2 · The immutable core](/redis-patterns/overview/patterns-become-protocol/the-immutable-core) — the core this contract rides on.
- [R0.2 · Valkey under the Exchange Platform](/redis-patterns/overview/redis-under-portal) — where Valkey sits in the build.
- [/echomq](/echomq) — the far side of this door.
- [/bcs](/bcs) — the architecture, with the frozen transcripts.
