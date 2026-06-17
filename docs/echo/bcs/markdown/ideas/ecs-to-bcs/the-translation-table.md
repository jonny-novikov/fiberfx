# B1.4 · The Translation Table — the convention of record

> Route: `/bcs/ideas/ecs-to-bcs/the-translation-table` (dive 3 of 3, module B1.4). The route-mirror
> source-of-record. Teaches the Who, When, How, and Decisions of `content/bcs1.4.md`; the code snippets
> verbatim from that chapter's How. Build stamp: `BCS0NtOW9yeOLg`.

## Hero

Kicker: `B1.4 · DIVE — THE TRANSLATION TABLE`. Title: **Both dialects, one convention.** Lede — the series
speaks ECS and BCS deliberately, with the translation table as the Rosetta line: six terms, each mapped so an
entity-systems veteran reads Part II without a glossary. The litmus question names the migration moment;
hybrids stay legitimate strictly behind the boundary. Heronote — source `content/bcs1.4.md` · Who, When, How,
Decisions. The table is the convention of record.

### Interactive 1 — the lookup (hero)

The six ECS terms as an SVG column facing their BCS translations. Select a term to read its translation and
the note:

- **entity** → an identity.
- **component** → a property in some system's table.
- **system** → a system, now with a hard boundary.
- **world** → the supervision tree plus the bus.
- **archetype** → data composition — Part II, Chapter 2.4's subject.
- **query across components** → a message join by identity.

In the trading vocabulary: the order is an `ORD` identity; its fills, its risk checks, and its book position
are properties in three systems; the matching sweep is a system consuming messages about `ORD` names — and
every one of those names is valid in the save file, on the socket, and in the store, because those are no
longer different places to be valid. Degrades to the static table in §1.

## §1 · The table (#table)

Source: `content/bcs1.4.md` · Who. Rendered as a two-column table — ECS term | BCS translation — six rows as
above.

## §2 · The litmus, exercised (#litmus)

Source: `content/bcs1.4.md` · When. Keep classic ECS where it is the right tool: one process, a frame loop,
identities that may die with the run. The litmus is a single question: *must this id outlive the process?* The
first yes — the first save, the first socket, the first row — is the migration moment, and it arrives on day
one for anything trading-shaped.

### Interactive 2 — four cases at the litmus

Select a case; a pure function answers the question from the case's facts (save? socket? row?):

- **A particle in a renderer's frame loop** — no save, no socket, no row → keep the handle. A renderer or an
  inner simulation core gains nothing from a wire-stable name per particle, and this series does not propose
  one.
- **An order on the trading platform** — the first socket arrives on day one → migrate: the order is an `ORD`
  identity.
- **A system's private iteration index** — the index never crosses the boundary → the hybrid: a system may
  keep handles internally as its private indexing business, provided its boundary speaks branded names — not a
  compromise of the law but an application of it.
- **A world that saves** — the first save is the first yes → migrate; an index into an array arrangement gone
  after restart cannot be the durable name.

Degrades to this static list.

## §3 · The migration, in code (#code)

Source: `content/bcs1.4.md` · How. Elixir — the world is a supervision tree and the component array is the
substrate's private ETS table, keyed by the name itself; minting *is* allocation, and reuse is impossible by
law rather than improbable by pattern:

```elixir
# handle era: {index, generation} into a system-private array, valid this run
# name era:   the key is the identity; reuse cannot be expressed
:ok = PropertyStore.put(:positions, EchoData.Snowflake.next_branded("PRT"), position)
```

Go — Weissflog's shape survives nearly verbatim, with two edits from Chapter 1.1: the channel edge replaces
the function boundary as the place the gate lives, and the branded string replaces the index-generation pair:

```go
// handle: uint32(idx) | gen<<20      -> valid in this process, this run
// name:   brandedid.MustEncode("ORD", snow) -> valid everywhere, indefinitely
```

Decisions carried from the chapter: generation counters are rejected **by subsumption** — detection of reuse
is replaced by prevention of reuse, and a probabilistic guard for an impossible event is deleted weight. The
index never rides in the name — placement is hash32's job, derived on demand. Internal handles are permitted
strictly behind the boundary. The ECS vocabulary is adopted with translation.

## References (#refs)

Sources: West — Evolve Your Hierarchy (`https://cowboyprogramming.com/2007/01/05/evolve-your-heirachy/`) ·
Weissflog — Handles are the better pointers (`https://floooh.github.io/2018/06/17/handles-vs-pointers.html`) ·
The Go Project — Share Memory By Communicating (`https://go.dev/doc/codewalk/sharemem/`) · Wikipedia — Entity
component system (`https://en.wikipedia.org/wiki/Entity_component_system`).
Related: `/bcs/ideas/ecs-to-bcs` (the B1.4 hub) · `/bcs/ideas` (B1 · Ideas Behind) · `/bcs` (course home) ·
`/echomq` (the bus the world becomes) · `/elixir` (the umbrella where `echo_data` lives).

## Pager

Previous: `/bcs/ideas/ecs-to-bcs/the-three-deaths` — The Three Deaths. Next: `/bcs/ideas/ecs-to-bcs` — B1.4 ·
back to the hub.
