# B2.5.1 · The Edge Is the Relation — one relation, one owner

> Route: `/bcs/elixir-core/relations/the-edge-is-the-relation` (dive 1 of B2.5). The route-mirror
> source-of-record. Teaches the `:holds` model from `content/bcs2.5.md` (What · Who); figures verbatim from
> `bcs_rung_2_5_check.out` — this dive reads E1 and E2. Build stamp: `BCS0NuzJLrcPiq`.

## Hero

Kicker: `B2.5 · dive 1 — the edge is the relation`. Title: **One relation, one owner.** Lede — *portfolio
holds asset* is a row keyed by a tuple of names, owned like any other property table, never an id list embedded
in either endpoint. One relation kind is one system: `:holds`, subjects gated `PRT`, objects gated `AST`,
declared at `start_link`. An edge is `{subject, object} → props`, and the pair's facts live on the edge.
Heronote — source: `content/bcs2.5.md`, quoting `bcs_rung_2_5_check.out`; the system is committed at
`runtimes/elixir/lib/echo_data/bcs/edge_store.ex`.

### The surface, exported and not (interactive SVG)

The six verbs drawn as a wall with six openings; behind it the two private indexes — forward and reverse —
never exported. Select an entry to read its exact surface:

- `link` — writes an edge and its props, both ends gated first.
- `unlink` — removes an edge from both directions.
- `props` — reads the pair's facts off the edge.
- `from/2` — the positions blotter: one subject's edges, forward.
- `to/2` — the holders report: one object's subjects, reverse — a verb, not a table.
- `degree/2` — the concentration check: how many edges a name carries.
- never exported — the forward index, the reverse index, any internal shape.

Degrades to a static labelled diagram without JavaScript.

## §1 · The transcript (#transcript)

`bcs_rung_2_5_check.out` · verbatim · this dive reads E1 and E2:

```text
boot: the holds relation is its own system -- PRT subjects, AST objects, indexes private
E1 surface ok -- the relation's surface: link, unlink, props, from, to, degree -- and its indexes are nobody's business
E2 gates ok -- both ends gated: subject must be PRT, object must be AST -- {:error, :namespace} on either violation
E3 retire ok -- the interim representation retired: positions struck out of the balance row and copied down as edges -- the 2.2 label is paid
E4 traverse ok -- forward 200 ascending with a 10-edge page head; reverse finds all 50 holders, ascending
E5 unlink ok -- unlink removes both directions atomically: degree 199; the reverse index no longer lists the subject
PASS 5/5
```

## §2 · E1 — the surface, gated a third time (#e1)

Source: `content/bcs2.5.md` · What. E1 performs the review gate the part now runs by habit: `link, unlink,
props, from, to, degree -- and its indexes are nobody's business`. The reverse index exists — the system
maintains it — and no export names it; reverse traversal is a verb (`to/2`), not a table. Exporting the reverse
table would hand callers a representation and start the coupling clock; the system owns its indexes, and the
boundary stays six verbs wide.

The desk's three joins, by verb (`content/bcs2.5.md` · Who): the positions blotter is `from/2`, the holders
report is `to/2`, the concentration check is `degree/2` — three joins that were a scan, a denormalization, and
a batch job in the embedded world. Risk asks exposure through the boundary instead of reading anyone's rows.
And agents, for whom the contract is six verbs and one rule: a pair's facts go on the edge — the quantity of a
holding belongs to the holding, not to the portfolio and not to the instrument.

## §3 · E2 — both ends gated (#e2)

Source: `content/bcs2.5.md` · What. E2 closes the silent join at *both* doors: an `ORD` subject is refused, a
`PRT` object is refused, each with `{:error, :namespace}` — the first relation in the series where two
namespaces are checked per write, because a relation is the place wrong-kind pairs would otherwise be minted.
The supervisor composes the store like any other: a `{name, relation, subject_ns, object_ns}` child among
children — the two admitted kinds are declared at `start_link` and checked at every `link`.

### The both-ends gate, exercised (interactive)

A pure model of the double gate on the `:holds` store, whose declared pair is `PRT` subjects and `AST` objects.
Select a presented pair; the readout names the verdict:

- subject `PRT` · object `AST` → admitted; the edge is written into both indexes.
- subject `ORD` · object `AST` → `{:error, :namespace}` — the rung's recorded subject refusal.
- subject `PRT` · object `PRT` → `{:error, :namespace}` — the rung's recorded object refusal.
- subject `ORD` · object `PRT` → `{:error, :namespace}` — either violation refuses; the write never reaches a
  table.

## References (#refs)

Sources: Codd, E. F. — A Relational Model of Data for Large Shared Data Banks
(`https://dl.acm.org/doi/10.1145/362384.362685`) · Erlang/OTP — the ets module
(`https://www.erlang.org/doc/apps/stdlib/ets.html`).
Related: `/bcs/elixir-core/relations` (B2.5 — the module hub) · `/bcs/elixir-core` (B2 · The Elixir BCS Core) ·
`/bcs/elixir-core/property-stores` (B2.2 — where the interim representation shipped) · `/elixir` (the umbrella
where `echo_data` lives).

## Pager

Previous: `/bcs/elixir-core/relations` — B2.5 · the hub. Next:
`/bcs/elixir-core/relations/the-supersession-performed` — The Supersession, Performed.
