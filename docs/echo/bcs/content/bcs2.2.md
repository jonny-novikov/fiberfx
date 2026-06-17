# BCS · Chapter 2.2 — Property stores on ETS

<show-structure depth="2"/>

The substrate becomes the property database. Three system tables under one tree — `AST` instruments, `PRT` balances, `ORD` orders — with the branded id as the only key, chronology as a property of the keyspace rather than a column, and exactly one amendment to the store module: `window/3`, the synthetic cursors of Chapter 1.5 landed on the `ordered_set`. The amendment was performed the way Chapter 2.1's decision requires — as an architecture review with the surface gate as its instrument — and the new rung (`bcs_rung_2_2_check.exs`, committed record ending `PASS 5/5`) gates the database's shape, the only-key law, both chronology reads, and the review itself, while the 2.1 rung re-runs green under the grown surface.

## Why

The trading desk's read patterns are the chapter's requirements written plainly: *what are the latest orders* is a newest-first page, *what happened between 14:30 and 14:32* is a window, *what is this instrument* is a get by name — and a database that needs a timestamp column, an index on it, and a query planner to answer the first two has paid three times for what the keyspace already carries. The part preface's guideline — a table keyed by branded ids is a timeline, add no second clock — is cashed here as working reads on real stores, and the decimal door that Chapters 1.3 and Appendix 1.1 closed from the storage and CPU sides gets closed from the third: the ingress.

## What

**The database shape.** P1 boots the three stores and writes domain rows behind their own boundaries — an instrument with its tick size, a balance with its cash — and the gate line states the part's quiet rule: values are private representations. The balance value carries a positions map for now; that representation is interim by declaration, superseded when Chapter 2.5 promotes the portfolio-holds-asset pair to the relations store, and saying so in advance is what keeps the supersession an amendment rather than a surprise.

**The branded form is the only key.** P2 takes the instrument's own snowflake, renders it as the 19-digit decimal, and offers it back: `the same snowflake's decimal rendering refused as :invalid` — on both read and write. The key law is now enforced at every layer the series has measured: the store charges more for the decimal (Chapter 1.3), every compiled runtime renders it slower (Appendix 1.1), and the boundary refuses it outright (here).

**Chronology without a column.** Three hundred `ORD` mints spread across real wall time, then P3 asks for the newest five: `newest five by byte order equal the last five minted: no timestamp column consulted` — `page_desc/2` walking the table tail, the order theorem as a read path.

**The window, landed in-process.** P4 is the chapter's center: two wall-clock instants captured mid-mint, two synthetic cursors built by the same `min_for` arithmetic every runtime shares, and the new `window/3` answering `returned 100 of 100 expected, ascending by key` — exactly the mints between the instants, by construction and by gate. The bounds are branded ids and are gated like any ingress (a window bound in the wrong namespace is refused before the table is touched), and the ascending order is the `ordered_set`'s term order doing the sorting [1], not a sort call.

**The review, performed.** Chapter 2.1 decided that adding an export is an architecture review with R1 as its gate; P5 is that decision exercised for the first time: `surface grew by exactly one export: window/3` — the full export set re-asserted, domain plus OTP callbacks and nothing else. The previous chapter's committed record stays exactly as it was: evidence outputs are frozen snapshots of their day, scripts evolve with the surface, and the pre-amendment record is now the historical proof of what the surface used to be.

## Who

The desk, whose three questions open the Why and are now three one-call reads. System authors, for whom the three-store tree is the template a fourth store joins by adding one `{name, namespace}` pair. And agents, for whom the window contract is now precise: `window(store, lo, hi)` is `[lo, hi)`, ascending, bounds gated against the store's namespace, cursors synthesized by `min_for` — nothing to remember beyond what Chapter 1.5 already taught.

## When

Reach for `get/2` when the name is known, `page_desc/2` when the question is *latest*, and `window/3` when the question is *between* — and notice that no fourth read has earned an export yet, which is the review bar working. Keep entity-embedded maps (the balance's positions) only while the pairs they encode have no traversal needs of their own; the moment *who holds this asset* becomes a question, the pair is a relation and Chapter 2.5 owns it. And amend the surface only through the review: one export, one gate update, one sentence in the record.

## Where

The store module at `runtimes/elixir/lib/echo_data/bcs/property_store.ex` (grown by `window/3` and its callback), the new rung and its committed record beside the older two, and the amended `bcs_rung_2_1_check.exs` whose frozen output is now the pre-amendment evidence — the freeze policy the agent guides stated for benchmarks, applied to rungs.

## How — the window, in Elixir and in Go

**Elixir.** The implementation is a gated match specification — both bounds through `Bcs.gate/2`, then a select whose guards are the two comparisons and whose result order is the table's:

```elixir
spec = [{{:"$1", :_}, [{:>=, :"$1", {:const, lo}}, {:<, :"$1", {:const, hi}}], [:"$1"]}]
{:reply, {:ok, :ets.select(s.table, spec)}, s}
```

Term order over binaries is byte order [1], so the theorem does the sorting and the guards do the cutting.

**Go.** The owner goroutine from Chapter 1.1 keeps its keys in a sorted slice, and the window is two binary searches and a copy — the same cursor arithmetic shared from Chapter 1.5:

```go
lo := brandedid.MustEncode("ORD", minFor(t0))
hi := brandedid.MustEncode("ORD", minFor(t1))
i := sort.SearchStrings(keys, lo)
j := sort.SearchStrings(keys, hi)
window := append([]string(nil), keys[i:j]...) // [lo, hi), ascending
```

Same grammar, same bytes, same half-open contract on both sides of the bus.

## Decisions

**One export per review, with the gate as the instrument** — decided in 2.1, performed here once, and now precedent: the diff that adds a function carries the gate update that admits it.

**Evidence outputs are frozen.** Scripts evolve with the surface; committed records do not — a record is what was true on its day, and the day is in the file. This generalizes the agent guides' benchmark rule to every rung in the series.

**The interim representation is declared.** The balance's embedded positions map ships labeled as pre-relational, with its supersession chapter named — drift is a representation that outlived its label, and this one cannot.

**Window bounds are ingress.** Synthetic or not, a cursor is an id arriving at a boundary, and it meets the gate like any other.

## Boundaries

Correctness is gated; range *cost* is not — `:ets.select` with comparison guards is not promised to seek to the lower bound, so very large tables earn a seeded `:ets.next/2` walk from `lo` as the optimization lane, carried as a follow-up rather than smuggled into this rung. Values are unversioned snapshots here; history-bearing values are the CHAMP chapter's subject. Single node, as everywhere in this part.

## Companion files

`runtimes/elixir/lib/echo_data/bcs/property_store.ex`; `bcs_rung_2_2_check.exs` and its committed record `bcs_rung_2_2_check.out`; the frozen `bcs_rung_2_1_check.out` as the pre-amendment surface evidence.

## References

1. Erlang/OTP stdlib — `ets` (`ordered_set` term-order traversal; `select/2` and match specifications; table protection levels): [erlang.org/doc/apps/stdlib/ets.html](https://www.erlang.org/doc/apps/stdlib/ets.html)
