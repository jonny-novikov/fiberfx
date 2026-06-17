# The Branded Component System — the course

> Route: `/bcs` (course landing, chapter B0). The route-mirror source-of-record for the landing. The page is the
> course's **design exemplar** (the BCS visual identity is defined here) and holds a full `links` PASS: unbuilt
> chapters render as non-anchor `soon` cards. Build stamp: `BCS0NtBpC9oGGW` (the course's own namespace, per D-8).

## Hero

Kicker: `B0 · ORIENTATION`. Title: **The Branded Component System**. Lede — the law in one sentence: encapsulation
boundaries are drawn around **systems**, not objects; the only values that cross are **identities and messages
about identities**; and identity is a **contract** — the 14-byte branded snowflake. The course teaches the BCS
manuscript Part for Part; every figure on every page is quoted verbatim from a committed output. The worked
project is a trading system; the bus is EchoMQ 2.0, backed by Valkey.

### The id anatomy (interactive SVG)

`USR0KHTOWnGLuC` — the canon's encode vector — dissected: a 3-character uppercase **namespace** (`USR`, oxide
red) + an 11-character Base62 **payload** carrying the 63-bit snowflake `274557032793636864`, split
`ts(41) | node(10) | seq(12)` from epoch `1704067200000` (2024-01-01 UTC). Four segment buttons (namespace ·
timestamp · node · sequence) update a readout; the SVG highlights the active segment. Degrades to a static
labelled diagram without JavaScript. The four gates refuse malformed forms: `USRzzzzzzzzzzz` → range ·
`usr0KHTOWnGLuC` → namespace · `USR0KHTOWnGLu` → length · `USR0KHTOWnGL!C` → charset.

## §1 · The law in three clauses (#law) — a triptych

1. **Systems own their state and behavior.** Failure retired: **the reach-through** — a change to one system's
   representation breaking code in another system's file.
2. **Only identities, and messages about identities, cross.** Failure retired: **the traveling object** — the
   entity, handle, or pointer that escapes its owner.
3. **Identity is a typed, ordered, placed contract.** Failures retired: **the silent join** (typed), **the second
   clock** (ordered), **the routing table** (placed), **the dialect** (the canon).

Composition note: enumerable → typeable → checkable — the architecture the type checker verifies.

## §2 · The contract (#contract)

The branded snowflake: 14 bytes, namespace + payload; string order is mint order (the order theorem — a table
keyed by branded id is already a timeline); `hash32` is placement any holder computes; one canon (Rust source, C
reference, `vectors.json`, a conformance suite per runtime) makes the runtime a deployment detail. The 41-bit
horizon is September 2093; the law of two clocks keeps identity time in the id and event time in data.

## §3 · The evidence ethic (#evidence) — frozen transcripts

Three transcript blocks, each labelled with its committed source, quoted verbatim:

1. `content/contract.md` · the normative vectors — `hash32(274557032793636864) = 234878118` ·
   `base62(2^63 − 1) = "AzL8n0Y58m7"` · encode `("USR", 274557032793636864) → "USR0KHTOWnGLuC"`.
2. `content/bcsA.md` · the connector gate, against live Valkey 9.1.0 — fence `echomq:2.0.0`; sequential INCR
   `29456` ops/s; pipelined SET `454483` ops/s; pipelined EVALSHA `161192` ops/s; `script_loads=1`;
   `10000-command pipeline returned 1..10000 in order`; `PASS 8/8`.
3. `content/bcs1.1.md` · the first rung — the smallest faithful system (gate · private-ETS store · supervisor),
   `PASS 6/6`.

Framing: every manuscript chapter that narrates built work is backed by a rung — an executable check script and a
frozen transcript. The course inherits the ethic: a number not present in a committed output does not appear.

## §4 · The course map (#map)

Nine chapter cards. **B0 · Orientation** — this page (the lit card, `href="/bcs"`). Non-anchor `soon` cards:
**B1 · Ideas Behind** (Part I, 6 modules) · **B2 · The Elixir BCS Core** (Part II, 6) · **B3 · The Bus — EchoMQ,
Valkey-native** (Part III, 7) · **B4 · EchoCache** (Part IV, 2) · **B5 · Go** (Part V, 2) · **B6 · Node 22+**
(Part VI, 3) · **B7 · Production on Fly** (Part VII, 4) · **B8 · The Trading System** (Part VIII, 4). Note: the
course mirrors a book being written — B1–B3 build over written Parts (Part III in progress); the manuscript plans
Parts IV–VIII.

## §5 · The doors (#doors)

- [`/echomq`](/echomq) — the bus protocol in depth: the `emq:{q}:` keyspace, the Lua inventory, conformance on
  Valkey.
- [`/redis-patterns`](/redis-patterns) — the substrate patterns applied: sorted sets, atomic Lua moves, locks,
  streams.
- [`/elixir`](/elixir) — the Portal engine and the umbrella where `echo_data`, the production identity library,
  lives.

## References (#refs, two columns, `class="refs"`)

Sources: Valkey (<https://valkey.io/>) · Lamport, "Time, Clocks, and the Ordering of Events"
(<https://lamport.azurewebsites.net/pubs/time-clocks.pdf>) · Kleppmann, "How to do distributed locking" — fencing
tokens (<https://martin.kleppmann.com/2016/02/08/how-to-do-distributed-locking.html>) · Snowflake ID
(<https://en.wikipedia.org/wiki/Snowflake_ID>) · Entity–component–system
(<https://en.wikipedia.org/wiki/Entity_component_system>) · Sketchpad
(<https://en.wikipedia.org/wiki/Sketchpad>) · Chassaing, the decider pattern
(<https://thinkbeforecoding.com/post/2021/12/17/functional-event-sourcing-decider>).
Related: the EchoMQ course (`/echomq`) · Redis Patterns Applied (`/redis-patterns`) · the Elixir course
(`/elixir`).

## Pager

Previous: none (the start of the course, a non-link span). Next: `/echomq` — the bus in depth, the open door
while B1 is authored.

## Footer (3 columns + bottom bar)

Brand + tagline · Chapters column (B0 anchor `/bcs`; B1–B8 non-anchor spans with `soon`) · The courses column
(`/bcs`, `/echomq`, `/redis-patterns`, `/elixir`). Bottom bar: © jonnify + the `BCS0NtBpC9oGGW` stamp with the
decoder panel (namespace · snowflake · node · seq · timestamp).
