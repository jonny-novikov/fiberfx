# BCS · Chapter 2.5 — Relations are systems

<show-structure depth="2"/>

The part preface's sharpest guideline gets its system: *portfolio holds asset* is a row keyed by a tuple of names, owned like any other property table, never an id list embedded in either endpoint. The `EdgeStore` (`runtimes/elixir/lib/echo_data/bcs/edge_store.ex`) is one relation as one process — both ends gated, forward and reverse indexes private to the owner, six verbs exported and nothing else — and the rung (`bcs_rung_2_5_check.exs`, committed record ending `PASS 5/5`) does something no previous rung has done: it executes a supersession on stage. Chapter 2.2 shipped the balance's embedded positions map labeled *interim, superseded by 2.5*; gate E3 strikes it out and copies the keys down, and the label is paid.

## Why

*Who holds ESZ6* is the desk's most-asked join, and the embedded representation cannot answer it: a positions map inside each balance row makes the forward read free and the reverse read a scan of every portfolio in the store — the reach-through wearing a convenience's clothes, exactly as the preface warned. The lineage of the fix is the oldest citation in this series: Codd's 1970 model treats a data bank as "a collection of time-varying relations" [1], and his normalization procedure is literally the E3 gate — strike the nonsimple domain out of the parent relation, copy the parent's key down into the promoted one. Fifty-six years later the parent is a balance row, the nonsimple domain is a positions map, and the promoted relation is a supervised process — but the procedure is his, step for step.

## What

**The model.** One relation kind is one system: `:holds`, subjects gated `PRT`, objects gated `AST`, declared at `start_link`. An edge is `{subject, object} → props`, and the pair's facts live *on the edge* — the quantity of a holding belongs to the holding, not to the portfolio and not to the instrument. The boot line states the shape: `the holds relation is its own system -- PRT subjects, AST objects, indexes private`.

**The surface, gated a third time.** E1 performs the review gate the part now runs by habit: `link, unlink, props, from, to, degree -- and its indexes are nobody's business`. The reverse index exists — the system maintains it — and no export names it; reverse traversal is a verb (`to/2`), not a table.

**Both ends gated.** E2 closes the silent join at *both* doors: an `ORD` subject is refused, a `PRT` object is refused, each with `{:error, :namespace}` — the first relation in the series where two namespaces are checked per write, because a relation is the place wrong-kind pairs would otherwise be minted.

**The supersession, performed.** E3 reads the 2.2-shaped balance row, links each `{asset, qty}` as an edge, deletes `:positions` from the row, and gates the result: `positions struck out of the balance row and copied down as edges -- the 2.2 label is paid`. The balance keeps its cash; the holdings became a relation; and the forward read returns exactly the promoted pairs, sorted.

**Traversal rides the order theorem into relations.** E4's two hundred edges come back `forward 200 ascending with a 10-edge page head; reverse finds all 50 holders, ascending` — and the ascending order is worth a sentence beyond correctness. Tuple keys compare element-wise in term order [2], so within one subject the objects sort by their own bytes — which, by Chapter 1.2's theorem, is *mint order*. A portfolio's forward traversal is its acquisition timeline, free, because the keys never stopped being chronology.

**Coherence under one owner.** E5 unlinks one edge and gates both directions at once: `degree 199; the reverse index no longer lists the subject`. The dual indexes stay coherent because exactly one process writes them, in one callback — the part's ownership law doing consistency work that would otherwise need a transaction.

## Who

The desk: the positions blotter is `from/2`, the holders report is `to/2`, the concentration check is `degree/2` — three joins that were a scan, a denormalization, and a batch job in the embedded world. Risk, which asks exposure through the boundary instead of reading anyone's rows. And agents, for whom the contract is six verbs and one rule: a pair's facts go on the edge.

## When

Promote a pair to a relation the moment either condition holds: the pair has facts of its own (a quantity, a weight, a since-date), or the reverse question exists anywhere in the product. Before both, a plain property field is fine and a relation is ceremony. Many-to-many is the native case; one-to-one may stay a field until the reverse question arrives, and the arrival is the migration trigger — E3 is the template, and it runs in one callback's worth of writes. Symmetric relations (*pairs-with*, *offsets*) are a design lane this rung does not build: model them as a normalized key order or as two directed stores, and say which in the system's doc.

## Where

The system at `runtimes/elixir/lib/echo_data/bcs/edge_store.ex`; the rung and its committed record beside the others; the retired representation's receipt split across two documents — Chapter 2.2's label, this rung's E3. The supervisor composes it like any store: a `{name, relation, subject_ns, object_ns}` child among children.

## How — the key is the join, in Elixir and in Go

**Elixir.** Forward traversal is a three-line match spec over the tuple keyspace, ascending by the table's own term order [2]:

```elixir
spec = [{{{s, :"$1"}, :"$2"}, [], [{{:"$1", :"$2"}}]}]
{:reply, {:ok, take(st.fwd, spec, limit)}, st}
```

One design trade is made explicitly: props are written into both indexes, so a reverse read is one hop. Two writes per link, atomic enough because one process performs both; if edge props ever grow heavy, the reverse index drops to keys-only and the owner joins internally — the alternative is stated here so the future diff is a decision, not a discovery.

**Go.** Fixed width pays again: a composite key is the two names concatenated — twenty-eight bytes, always — and a subject's range is a prefix scan over a sorted slice:

```go
key := subj + obj                       // 28 fixed bytes, no separator needed
i := sort.SearchStrings(fwd, subj)      // first edge of the subject
j := sort.SearchStrings(fwd, subj+"\xff")
edges := fwd[i:j]                       // ascending objects: the acquisition timeline
```

The reverse slice mirrors it with `obj + subj`, both owned by the one goroutine from Chapter 1.1, both invisible outside the package.

## Decisions

**A pair's facts live on the edge.** Quantity belongs to the holding; putting it on either endpoint re-embeds the relation one field at a time.

**The system owns its indexes.** The reverse table is maintenance, not surface — exporting it would hand callers a representation and start the coupling clock.

**Dual-write duplication is the chosen trade.** Props in both indexes, one writer, one callback; the keys-only alternative is pre-stated for the day props grow heavy.

**Interim labels are debts, and this part pays them on stage.** Chapter 2.2 declared the embedded map interim and named its supersessor; the supersessor executed the retirement as a gate. The generalization is now the rule: a representation shipped as *interim* names its chapter, and that chapter performs the migration in a rung, not a footnote.

## Boundaries

One relation kind per store — a second relation is a second system, not a `kind` column. Edge windows (object-id cursors over one subject's range) are the natural next export and wait for their review gate rather than riding in here. No cardinality limits are enforced; a million-edge subject pages but its `from/2, :all` is a million-tuple reply, which is the caller's choice to make. Single node, one writer, as the part prescribes.

## Companion files

`runtimes/elixir/lib/echo_data/bcs/edge_store.ex`; `bcs_rung_2_5_check.exs` and its committed record `bcs_rung_2_5_check.out`; the superseded representation's label in [`bcs2.2.md`](bcs2.2.md).

## References

1. Codd, E. F. — A Relational Model of Data for Large Shared Data Banks. Communications of the ACM, vol. 13 no. 6, June 1970, pp. 377–387 (relations as first-class; the normalization procedure gate E3 performs): [dl.acm.org/doi/10.1145/362384.362685](https://dl.acm.org/doi/10.1145/362384.362685)
2. Erlang/OTP stdlib — `ets` (`ordered_set` term-order traversal over tuple keys; `select/2,3` and match specifications): [erlang.org/doc/apps/stdlib/ets.html](https://www.erlang.org/doc/apps/stdlib/ets.html)
