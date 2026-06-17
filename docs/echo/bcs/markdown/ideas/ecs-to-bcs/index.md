# B1.4 · From ECS to BCS — translation, not re-education

> Route: `/bcs/ideas/ecs-to-bcs` (module hub, B1.4). The route-mirror source-of-record. Teaches
> `content/bcs1.4.md`; every figure verbatim from that chapter and the committed sources it quotes. Build
> stamp: `BCS0NtOW9bwTwW`.

## Hero

Kicker: `B1.4 · FROM ECS TO BCS — manuscript chapter 1.4`. Title: **Translation, not re-education.** Lede —
ECS is the lingua franca of an entire industry, and its key is a refined artifact: the index-handle with a
generation counter. This module is what happens when that artifact meets a save file, a socket, and a foreign
store — each death traced to a missing property of the identity contract. BCS keeps everything ECS got right
and completes the one thing it left local: the migration is a promotion of the id, not a rejection of the
pattern. Heronote — the chapter is `content/bcs1.4.md`. ECS discovered two of the three BCS clauses on its
own, inside one process; distribution is where the undiscovered third presents its bill.

### Interactive — the three clauses, scored against ECS (hero)

The law's three clauses drawn as an SVG strip; the first two marked discovered, the third marked
undiscovered. Select a clause to read where ECS arrived at it and what distribution demands:

- **Clause one — systems own their state and behavior.** ECS form: Weissflog's 2018 discipline, *"the systems
  being the sole owner of their memory allocations"*; same-typed items grouped into arrays whose base pointers
  are system-private. Discovered independently, enforced by convention inside one address space.
- **Clause two — only identities, and messages about identities, cross boundaries.** ECS form: only
  index-handles cross to the outside world. The founding article records the pressure: at five percent CPU
  cost, *"we allowed the components to store pointers to one another"* (West, 2007). Discovered — and bent
  under frame-rate duress.
- **Clause three — identity is a typed, ordered, placed contract.** ECS form: none. The handle is placement
  and liveness wearing identity's clothes, valid only in one process's current memory layout. The undiscovered
  third; the bill arrives at the save file, the socket, and the foreign store.

Degrades to this static list without JavaScript.

## §1 · Why — translate, do not re-educate (#why)

Source: `content/bcs1.4.md` · Why. Engineers arrive at distributed systems fluent in ECS, and the trading
platform this series builds is the distributed case in full: positions, orders, and risk envelopes spread
across processes, machines, and stores, with identities expected to outlive all three. A chapter that
translates is worth more than a chapter that re-educates. The claim to be earned: BCS keeps everything ECS got
right and completes the one thing it left local.

## §2 · The diagnosis, in one figure (#diagnosis)

A handle is placement and liveness wearing identity's clothes. The contract separates what the handle fused —
and its answers are already on stage in the committed rung transcript:

```text
G4 ordered ok -- page_desc(2000) == byte-sort desc over 2000 minted ids; store holds no clock
G5 placed ok -- placement(USR0KHTOWnGLuC) -> 234878118
```

(Source: `content/echo_data/runtimes/elixir/bcs_rung_1_1_check.out`, G4–G5.) Placement is derived, never
embedded — hash32 computes the slot from the name, `234878118` for the reference id, at `0.9586` nanoseconds
in pure Go. Liveness-by-detection becomes uniqueness-by-prevention — the minting law never reuses a name; the
substrate paged two thousand mints in exact byte-sort order with no allocator and no free list. And the kind
rides in the value and the type, so the silent join dies at the gate: `200 / 400 / 400 / 404`, wrong kind
refused before any handler. What remains in the name is exactly what a name should carry — kind and instant —
at 65 bytes per key on the measured table.

## §3 · The dives (#dives)

- **The Handle at Its Best** (`the-handle-at-its-best`) — Weissflog's 2018 discipline; the per-slot generation
  counter; West's 2007 confession. Two clauses discovered inside one process.
- **The Three Deaths** (`the-three-deaths`) — the save file, the socket, the foreign store; each scope
  violation named and traced to a missing contract property.
- **The Translation Table** (`the-translation-table`) — entity → identity and the rest of the convention of
  record; the litmus question; hybrids legitimate strictly behind the boundary.

Booknote: keep classic ECS where it is the right tool — one process, a frame loop, identities that may die
with the run. The litmus is a single question: *must this id outlive the process?* The first yes — the first
save, the first socket, the first row — is the migration moment, and it arrives on day one for anything
trading-shaped.

## References (#refs)

Sources: West — Evolve Your Hierarchy (`https://cowboyprogramming.com/2007/01/05/evolve-your-heirachy/`) ·
Weissflog — Handles are the better pointers (`https://floooh.github.io/2018/06/17/handles-vs-pointers.html`) ·
Wikipedia — Entity component system (`https://en.wikipedia.org/wiki/Entity_component_system`).
Related: `/bcs/ideas` (B1 · Ideas Behind) · `/bcs` (course home) · `/echomq` (the bus the world becomes —
Part III's subject) · `/elixir` (the umbrella where `echo_data` lives).

## Pager

Previous: `/bcs/ideas` — B1 · Ideas Behind. Next: `/bcs/ideas/ecs-to-bcs/the-handle-at-its-best` — The Handle
at Its Best.
