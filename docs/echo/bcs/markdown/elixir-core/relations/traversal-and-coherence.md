# B2.5.3 · Traversal and Coherence — chronology, still free

> Route: `/bcs/elixir-core/relations/traversal-and-coherence` (dive 3 of B2.5). The route-mirror
> source-of-record. Teaches E4 and E5 from `content/bcs2.5.md` (What · How · Decisions · Boundaries); figures
> verbatim from `bcs_rung_2_5_check.out`. Build stamp: `BCS0NuzJM2glnM`.

## Hero

Kicker: `B2.5 · dive 3 — traversal and coherence`. Title: **Chronology, still free.** Lede — E4's two hundred
edges come back `forward 200 ascending with a 10-edge page head; reverse finds all 50 holders, ascending` —
and the ascending order is worth a sentence beyond correctness: tuple keys compare element-wise in term order,
so within one subject the objects sort by their own bytes — which, by Chapter 1.2's theorem, is mint order. A
portfolio's forward traversal is its acquisition timeline, free. Heronote — source: `content/bcs2.5.md`,
quoting `bcs_rung_2_5_check.out`; the system is committed at
`runtimes/elixir/lib/echo_data/bcs/edge_store.ex`.

### The rung's reads, re-run as a model (interactive SVG)

A pure counter model of E4 and E5 over the rung's own figures — one subject, its edges, the reverse index.
Select a verb; the readout performs it on the model and quotes the recorded figure:

- `from/2` — forward: `200` edge tuples, ascending — the acquisition timeline.
- `from/2` with a limit — the `10-edge page head`, ascending.
- `to/2` — reverse: `all 50 holders, ascending`.
- `unlink` — one edge removed from both directions; the model's degree drops to `199`.
- `degree/2` — `200` before the unlink, `199` after; after the unlink of a subject's last edge toward an
  object, `the reverse index no longer lists the subject`.

Degrades to a static labelled diagram without JavaScript.

## §1 · The transcript (#transcript)

`bcs_rung_2_5_check.out` · verbatim · this dive reads E4 and E5:

```text
boot: the holds relation is its own system -- PRT subjects, AST objects, indexes private
E1 surface ok -- the relation's surface: link, unlink, props, from, to, degree -- and its indexes are nobody's business
E2 gates ok -- both ends gated: subject must be PRT, object must be AST -- {:error, :namespace} on either violation
E3 retire ok -- the interim representation retired: positions struck out of the balance row and copied down as edges -- the 2.2 label is paid
E4 traverse ok -- forward 200 ascending with a 10-edge page head; reverse finds all 50 holders, ascending
E5 unlink ok -- unlink removes both directions atomically: degree 199; the reverse index no longer lists the subject
PASS 5/5
```

## §2 · E4 — traversal rides the order theorem (#e4)

Source: `content/bcs2.5.md` · What · How. Forward traversal is a three-line match spec over the tuple keyspace,
ascending by the table's own term order:

```elixir
spec = [{{{s, :"$1"}, :"$2"}, [], [{{:"$1", :"$2"}}]}]
{:reply, {:ok, take(st.fwd, spec, limit)}, st}
```

Tuple keys compare element-wise in term order, so within one subject the objects sort by their own bytes —
which, by Chapter 1.2's theorem, is mint order. A portfolio's forward traversal is its acquisition timeline,
free, because the keys never stopped being chronology. The theorem itself is Part I's — B1, *Ideas Behind the
System* — and this rung rides it into relations without adding a column or a clock.

In Go, fixed width pays again: a composite key is the two names concatenated — twenty-eight bytes, always —
and a subject's range is a prefix scan over a sorted slice:

```go
key := subj + obj                       // 28 fixed bytes, no separator needed
i := sort.SearchStrings(fwd, subj)      // first edge of the subject
j := sort.SearchStrings(fwd, subj+"\xff")
edges := fwd[i:j]                       // ascending objects: the acquisition timeline
```

The reverse slice mirrors it with `obj + subj`, both owned by the one goroutine from Chapter 1.1, both
invisible outside the package.

## §3 · E5 — coherence under one owner (#e5)

Source: `content/bcs2.5.md` · What · Decisions · Boundaries. E5 unlinks one edge and gates both directions at
once: `degree 199; the reverse index no longer lists the subject`. The dual indexes stay coherent because
exactly one process writes them, in one callback — the part's ownership law doing consistency work that would
otherwise need a transaction.

One design trade is made explicitly: props are written into both indexes, so a reverse read is one hop. Two
writes per link, atomic enough because one process performs both; if edge props ever grow heavy, the reverse
index drops to keys-only and the owner joins internally — the alternative is stated here so the future diff is
a decision, not a discovery.

### The dual write, in one callback (interactive)

A step model of `link` and `unlink` against the two private indexes. Select an operation; the readout shows
both indexes after the callback returns:

- `link` — the forward index gains `{subject, object} → props` and the reverse index gains
  `{object, subject} → props`: two writes, one owner, one callback.
- `unlink` — both entries leave in the same callback: `unlink removes both directions atomically`.
- keys-only alternative — the reverse index holds keys without props; a reverse read joins internally through
  the owner — the pre-stated trade for the day props grow heavy.

Boundaries, taught honestly: one relation kind per store — a second relation is a second system, not a `kind`
column. Edge windows (object-id cursors over one subject's range) are the natural next export and wait for
their review gate rather than riding in here. No cardinality limits are enforced; a million-edge subject pages
but its `from/2, :all` is a million-tuple reply, which is the caller's choice to make. Single node, one writer,
as the part prescribes.

## References (#refs)

Sources: Codd, E. F. — A Relational Model of Data for Large Shared Data Banks
(`https://dl.acm.org/doi/10.1145/362384.362685`) · Erlang/OTP — the ets module
(`https://www.erlang.org/doc/apps/stdlib/ets.html`).
Related: `/bcs/elixir-core/relations` (B2.5 — the module hub) · `/bcs/ideas` (B1 — the order theorem the
traversal rides) · `/bcs/elixir-core` (B2 · The Elixir BCS Core) · `/elixir` (the umbrella where `echo_data`
lives).

## Pager

Previous: `/bcs/elixir-core/relations/the-supersession-performed` — The Supersession, Performed. Next:
`/bcs/elixir-core/relations` — B2.5 · the hub.
