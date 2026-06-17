# B2.5 · Relations Are Systems — the join, given an owner

> Route: `/bcs/elixir-core/relations` (module hub, B2.5). The route-mirror source-of-record. Teaches
> `content/bcs2.5.md`; every figure verbatim from the committed `bcs_rung_2_5_check.out` (`PASS 5/5`).
> Build stamp: `BCS0NuzJLmE2Fc`.

## Hero

Kicker: `B2.5 · RELATIONS ARE SYSTEMS — manuscript chapter 2.5`. Title: **The join, given an owner.** Lede —
*portfolio holds asset* is a row keyed by a tuple of names, owned like any other property table, never an id
list embedded in either endpoint. The `EdgeStore` is one relation as one process — both ends gated, forward and
reverse indexes private to the owner, six verbs exported and nothing else. Heronote — the chapter is
`content/bcs2.5.md`; the rung behind it is bcs2.5, and its committed transcript closes `PASS 5/5`. The rung
does something no previous rung has done: it executes a supersession on stage — Chapter 2.2 shipped the
balance's embedded positions map labeled *interim, superseded by 2.5*; gate E3 strikes it out and copies the
keys down, and the label is paid.

### The five gates, mapped to the dives (interactive SVG)

Five gates over the relation store, drawn in transcript order (E1–E5). Select a gate to read its verbatim line
and the dive that teaches it:

- **E1** — `the relation's surface: link, unlink, props, from, to, degree -- and its indexes are nobody's
  business` → dive 1, The Edge Is the Relation.
- **E2** — `both ends gated: subject must be PRT, object must be AST -- {:error, :namespace} on either
  violation` → dive 1.
- **E3** — `the interim representation retired: positions struck out of the balance row and copied down as
  edges -- the 2.2 label is paid` → dive 2, The Supersession, Performed.
- **E4** — `forward 200 ascending with a 10-edge page head; reverse finds all 50 holders, ascending` → dive 3,
  Traversal and Coherence.
- **E5** — `unlink removes both directions atomically: degree 199; the reverse index no longer lists the
  subject` → dive 3.

Degrades to a static labelled diagram without JavaScript.

## §1 · Why — the most-asked join (#why)

Source: `content/bcs2.5.md` · Why. *Who holds ESZ6* is the desk's most-asked join, and the embedded
representation cannot answer it: a positions map inside each balance row makes the forward read free and the
reverse read a scan of every portfolio in the store — the reach-through wearing a convenience's clothes,
exactly as the part preface warned. The lineage of the fix is the oldest citation in this series: Codd's 1970
model treats a data bank as "a collection of time-varying relations", and his normalization procedure is
literally the E3 gate — strike the nonsimple domain out of the parent relation, copy the parent's key down into
the promoted one. Fifty-six years later the parent is a balance row, the nonsimple domain is a positions map,
and the promoted relation is a supervised process — but the procedure is his, step for step.

Four written rules: one relation kind is one system (`:holds`, subjects gated `PRT`, objects gated `AST`,
declared at `start_link`) · a pair's facts live on the edge (`{subject, object} → props` — quantity belongs to
the holding, not to the portfolio and not to the instrument) · the system owns its indexes (the reverse table
is maintenance, not surface) · interim labels are debts, paid on stage (E3 the template).

## §2 · The proof (#proof)

The full committed transcript (`content/bcs2.5.md`, quoting `bcs_rung_2_5_check.out`), verbatim:

```text
boot: the holds relation is its own system -- PRT subjects, AST objects, indexes private
E1 surface ok -- the relation's surface: link, unlink, props, from, to, degree -- and its indexes are nobody's business
E2 gates ok -- both ends gated: subject must be PRT, object must be AST -- {:error, :namespace} on either violation
E3 retire ok -- the interim representation retired: positions struck out of the balance row and copied down as edges -- the 2.2 label is paid
E4 traverse ok -- forward 200 ascending with a 10-edge page head; reverse finds all 50 holders, ascending
E5 unlink ok -- unlink removes both directions atomically: degree 199; the reverse index no longer lists the subject
PASS 5/5
```

The system lives at `runtimes/elixir/lib/echo_data/bcs/edge_store.ex`; the supervisor composes it like any
store: a `{name, relation, subject_ns, object_ns}` child among children. The boot line states the shape: `the
holds relation is its own system -- PRT subjects, AST objects, indexes private`. For the desk, the contract is
six verbs and one rule — a pair's facts go on the edge: the positions blotter is `from/2`, the holders report
is `to/2`, the concentration check is `degree/2` — three joins that were a scan, a denormalization, and a batch
job in the embedded world.

## §3 · The dives (#dives)

- **The Edge Is the Relation** (`the-edge-is-the-relation`) — the `:holds` model: one relation kind is one
  system, subjects gated `PRT`, objects gated `AST`, declared at `start_link`; an edge is
  `{subject, object} → props`. E1 — six verbs, indexes nobody's business; reverse traversal is a verb
  (`to/2`), not a table. E2 — both ends gated: an `ORD` subject refused, a `PRT` object refused, each
  `{:error, :namespace}`.
- **The Supersession, Performed** (`the-supersession-performed`) — E3, Codd's normalization on stage: positions
  struck out of the balance row and copied down as edges; the 2.2 label is paid. The decision generalized: a
  representation shipped as *interim* names its chapter, and that chapter performs the migration in a rung, not
  a footnote.
- **Traversal and Coherence** (`traversal-and-coherence`) — E4: forward 200 ascending with a 10-edge page head;
  reverse finds all 50 holders, ascending — tuple keys compare element-wise in term order, so a portfolio's
  forward traversal is its acquisition timeline, free. E5: degree 199; the reverse index no longer lists the
  subject — dual indexes coherent because exactly one process writes them, in one callback.

## Boundaries (taught across the dives)

One relation kind per store — a second relation is a second system, not a `kind` column. Edge windows wait for
their review gate. No cardinality limits are enforced. Single node, one writer, as the part prescribes.
Symmetric relations (*pairs-with*, *offsets*) are a design lane this rung does not build. Siblings: **The CHAMP
Property Database** (B2.3) and **Archetypes and Composition** (B2.4) stand beside this module in Part II.

## References (#refs)

Sources: Codd, E. F. — A Relational Model of Data for Large Shared Data Banks
(`https://dl.acm.org/doi/10.1145/362384.362685`) · Erlang/OTP — the ets module
(`https://www.erlang.org/doc/apps/stdlib/ets.html`).
Related: `/bcs/elixir-core` (B2 · The Elixir BCS Core) · `/bcs/elixir-core/property-stores` (B2.2 — the
superseded interim representation) · `/bcs/elixir-core/champ` (B2.3 — the forest that keeps edge history the
day it is asked for) · `/bcs/elixir-core/archetypes` (B2.4 — the module before this one in the Part II arc) ·
`/bcs/ideas` (B1 — the order theorem the traversal rides) · `/elixir` (the umbrella where `echo_data` lives).

## Pager

Previous: `/bcs/elixir-core` — B2 · The Elixir BCS Core. Next:
`/bcs/elixir-core/relations/the-edge-is-the-relation` — The Edge Is the Relation.
