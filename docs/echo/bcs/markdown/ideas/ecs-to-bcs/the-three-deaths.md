# B1.4 · The Three Deaths — save file, socket, foreign store

> Route: `/bcs/ideas/ecs-to-bcs/the-three-deaths` (dive 2 of 3, module B1.4). The route-mirror
> source-of-record. Teaches the three deaths and the diagnosis of `content/bcs1.4.md`; the contract's answers
> quoted verbatim from the committed `bcs_rung_1_1_check.out`. Build stamp: `BCS0NtOW9rGoy0`.

## Hero

Kicker: `B1.4 · DIVE — THE THREE DEATHS`. Title: **Three boundaries, three deaths.** Lede — the handle's
validity is scoped to one process's current memory layout, and each scope violation has a name: the save file,
the socket, the foreign store. Each death traces to a missing property of the identity contract. Heronote —
source `content/bcs1.4.md` · What and the diagnosis; the contract's answers are on stage in
`bcs_rung_1_1_check.out`.

### Interactive 1 — the deaths, stepped (hero)

An SVG of the handle's home process and the three boundaries it cannot cross. Select a boundary to read what
dies, what the industry built around the corpse, and the missing contract property:

- **The save file** — an index is an address into an array arrangement that no longer exists after restart, so
  persistence becomes a swizzling pass — every table rewritten from handles to something durable and back —
  and the generation pattern serializes into noise. Missing: a name that survives every layout — placement
  derived, never embedded.
- **The socket** — entity 4117 on machine A names nothing on machine B, so replication mints a second identity
  scheme with bidirectional mapping tables at both ends — the dialect failure, self-inflicted before any
  foreign runtime is even involved. Missing: one canonical, wire-stable name.
- **The foreign store** — a handle cannot be a foreign key, so the database grows its own serials;
  `created_at` columns sprout beside them because insertion order is the only chronology left — the second
  clock; shard keys are invented per table — the routing table; and nothing anywhere checks that the integer
  arriving in the assets table was ever an asset — the silent join, at last, with no compiler in reach.
  Missing: kind in the value and the type; order and placement in the name.

Degrades to this static list.

## §1 · The deaths, named (#deaths)

Source: `content/bcs1.4.md` · What. Three cards, one per death — the save file (the swizzling pass; generations
into noise), the socket (entity 4117; mapping tables at both ends), the foreign store (serials; the second
clock; the routing table; the silent join).

## §2 · The diagnosis, in contract terms (#diagnosis)

A handle is placement and liveness wearing identity's clothes. The index *is* placement, leaked into the name —
which is why the name dies whenever the layout does. The generation counter *is* a liveness check, candidly
*"isn't waterproof"* — detection, not prevention. The contract separates what the handle fused, and two of its
answers are already in the committed transcript:

```text
G4 ordered ok -- page_desc(2000) == byte-sort desc over 2000 minted ids; store holds no clock
G5 placed ok -- placement(USR0KHTOWnGLuC) -> 234878118
```

(Source: `content/echo_data/runtimes/elixir/bcs_rung_1_1_check.out`, G4–G5.)

### Interactive 2 — what the handle fused, separated

Select one of the three contract properties to compare the handle's answer with the contract's:

- **Placement** — handle: the index is the placement, embedded in the name; the name dies with the layout.
  Contract: hash32 derives the slot from the name — `234878118` for the reference id, at `0.9586` nanoseconds
  in pure Go — so the name survives every layout it will ever be stored in.
- **Liveness → uniqueness** — handle: a generation counter detects reuse, probabilistically. Contract: the
  minting law never reuses a name — the substrate paged two thousand mints in exact byte-sort order with no
  allocator and no free list — so the ABA problem the generation bits exist to catch cannot be expressed.
- **Kind** — handle: nothing checks that the integer arriving in the assets table was ever an asset. Contract:
  the kind rides in the value and the type, so the silent join dies at the gate — the measured row reads
  `200 / 400 / 400 / 404`, wrong kind refused before any handler — instead of surviving until an analyst
  notices.

What remains in the name is exactly what a name should carry — kind and instant — at 65 bytes per key on the
measured table, cheaper at rest than the handle's own decimal shadow. Degrades to this static list.

## References (#refs)

Sources: Weissflog — Handles are the better pointers
(`https://floooh.github.io/2018/06/17/handles-vs-pointers.html`) · West — Evolve Your Hierarchy
(`https://cowboyprogramming.com/2007/01/05/evolve-your-heirachy/`) · Wikipedia — Entity component system
(`https://en.wikipedia.org/wiki/Entity_component_system`).
Related: `/bcs/ideas/ecs-to-bcs` (the B1.4 hub) · `/bcs/ideas` (B1 · Ideas Behind) · `/bcs` (course home) ·
`/redis-patterns` (the store-side key patterns, taught applied).

## Pager

Previous: `/bcs/ideas/ecs-to-bcs/the-handle-at-its-best` — The Handle at Its Best. Next:
`/bcs/ideas/ecs-to-bcs/the-translation-table` — The Translation Table.
