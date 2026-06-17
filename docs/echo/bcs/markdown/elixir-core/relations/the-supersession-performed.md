# B2.5.2 · The Supersession, Performed — Codd's procedure, on stage

> Route: `/bcs/elixir-core/relations/the-supersession-performed` (dive 2 of B2.5). The route-mirror
> source-of-record. Teaches E3 from `content/bcs2.5.md` (Why · What · When · Decisions); figures verbatim from
> `bcs_rung_2_5_check.out`. Build stamp: `BCS0NuzJLxIOK8`.

## Hero

Kicker: `B2.5 · dive 2 — the supersession, performed`. Title: **Codd's procedure, on stage.** Lede — Chapter
2.2 shipped the balance's embedded positions map labeled *interim, superseded by 2.5*; gate E3 strikes it out
and copies the keys down, and the label is paid. The rung does something no previous rung has done: it executes
a supersession on stage. Heronote — source: `content/bcs2.5.md`, quoting `bcs_rung_2_5_check.out`; the
superseded representation's receipt is split across two documents — Chapter 2.2's label, this rung's E3.

### The supersession, step by step (interactive SVG)

E3's procedure over the fixed 2.2-shaped balance row, performed one step at a time. Select a step; the readout
shows the row and the relation after it:

1. **read** — E3 reads the 2.2-shaped balance row: cash, plus a positions map — the nonsimple domain inside
   the parent relation.
2. **link** — each `{asset, qty}` is linked as an edge: the parent's key copied down, the pair's facts now on
   the edge.
3. **strike** — `:positions` is deleted from the row; the balance keeps its cash.
4. **gate** — the result is gated: `positions struck out of the balance row and copied down as edges -- the
   2.2 label is paid`; the forward read returns exactly the promoted pairs, sorted.

Degrades to a static labelled diagram without JavaScript.

## §1 · The transcript (#transcript)

`bcs_rung_2_5_check.out` · verbatim · this dive reads E3:

```text
boot: the holds relation is its own system -- PRT subjects, AST objects, indexes private
E1 surface ok -- the relation's surface: link, unlink, props, from, to, degree -- and its indexes are nobody's business
E2 gates ok -- both ends gated: subject must be PRT, object must be AST -- {:error, :namespace} on either violation
E3 retire ok -- the interim representation retired: positions struck out of the balance row and copied down as edges -- the 2.2 label is paid
E4 traverse ok -- forward 200 ascending with a 10-edge page head; reverse finds all 50 holders, ascending
E5 unlink ok -- unlink removes both directions atomically: degree 199; the reverse index no longer lists the subject
PASS 5/5
```

## §2 · The procedure is his, step for step (#codd)

Source: `content/bcs2.5.md` · Why. The lineage of the fix is the oldest citation in this series: Codd's 1970
model treats a data bank as "a collection of time-varying relations", and his normalization procedure is
literally the E3 gate — strike the nonsimple domain out of the parent relation, copy the parent's key down into
the promoted one. Fifty-six years later the parent is a balance row, the nonsimple domain is a positions map,
and the promoted relation is a supervised process — but the procedure is his, step for step.

Why the embedded form had to go: *who holds ESZ6* is the desk's most-asked join, and a positions map inside
each balance row makes the forward read free and the reverse read a scan of every portfolio in the store — the
reach-through wearing a convenience's clothes, exactly as the part preface warned. E3 reads the 2.2-shaped
balance row, links each `{asset, qty}` as an edge, deletes `:positions` from the row, and gates the result. The
balance keeps its cash; the holdings became a relation; and the forward read returns exactly the promoted
pairs, sorted. The superseded representation shipped in **Property Stores on ETS** (B2.2) — the label this
rung pays.

## §3 · The decision, generalized (#when)

Source: `content/bcs2.5.md` · When · Decisions. Interim labels are debts, and this part pays them on stage:
a representation shipped as *interim* names its chapter, and that chapter performs the migration in a rung, not
a footnote. The migration runs in one callback's worth of writes — E3 is the template.

When to promote a pair to a relation: the moment either condition holds — the pair has facts of its own (a
quantity, a weight, a since-date), or the reverse question exists anywhere in the product. Before both, a plain
property field is fine and a relation is ceremony. Many-to-many is the native case; one-to-one may stay a field
until the reverse question arrives, and the arrival is the migration trigger. Symmetric relations
(*pairs-with*, *offsets*) are a design lane this rung does not build: model them as a normalized key order or
as two directed stores, and say which in the system's doc.

### Promote, or stay a field (interactive)

A pure model of the When rules over four fixed pairs. Select a pair; the readout runs the two conditions and
names the verdict:

- *portfolio holds asset*, with a quantity → facts of its own → promote: the facts go on the edge.
- a pair with no facts, but *who holds X* is asked → the reverse question exists → promote.
- a one-to-one pair, no facts, no reverse question → stay a field; a relation is ceremony.
- the same one-to-one pair, the reverse question arrives → the arrival is the migration trigger — E3 the
  template, one callback's worth of writes.

## References (#refs)

Sources: Codd, E. F. — A Relational Model of Data for Large Shared Data Banks
(`https://dl.acm.org/doi/10.1145/362384.362685`) · Erlang/OTP — the ets module
(`https://www.erlang.org/doc/apps/stdlib/ets.html`).
Related: `/bcs/elixir-core/relations` (B2.5 — the module hub) · `/bcs/elixir-core/property-stores` (B2.2 — the
chapter that shipped the interim label) · `/bcs/elixir-core` (B2 · The Elixir BCS Core) · `/elixir` (the
umbrella where `echo_data` lives).

## Pager

Previous: `/bcs/elixir-core/relations/the-edge-is-the-relation` — The Edge Is the Relation. Next:
`/bcs/elixir-core/relations/traversal-and-coherence` — Traversal and Coherence.
