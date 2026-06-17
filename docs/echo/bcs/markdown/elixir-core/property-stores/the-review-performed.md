# B2.2.3 · The Review, Performed — one export, one gate update, one sentence in the record

> Route: `/bcs/elixir-core/property-stores/the-review-performed` (dive 3 of 3, module B2.2). The route-mirror
> source-of-record. Teaches P5 of `content/bcs2.2.md` and the frozen-record ethic; every figure verbatim from
> the committed `bcs_rung_2_2_check.out` and the frozen `bcs_rung_2_1_check.out`. Build stamp:
> `BCS0NuRyZmMw6q`.

## Hero

Kicker: `B2.2 · DIVE 3 — THE REVIEW, PERFORMED`. Title: **One export, one review.** Lede — Chapter 2.1 decided
that adding an export is an architecture review with the surface gate as its instrument. P5 is that decision
exercised for the first time: the surface grew by exactly one export — `window/3` — and the full export set
re-asserted, domain plus OTP callbacks and nothing else. Heronote — source `content/bcs2.2.md`, quoting
`bcs_rung_2_2_check.out` (line P5) and the frozen `bcs_rung_2_1_check.out` as the pre-amendment surface
evidence.

### Interactive 1 — the surface diff (hero)

The store's export surface before and after the review, drawn as two SVG panels. The 2.1 surface: six domain
functions plus OTP callbacks, nothing else — `start_link/1`, `put/3`, `get/2`, `page_desc/2`,
`record_entity/2`, `placement/1`. The 2.2 surface: the same six plus `window/3`. Select *2.1 surface*, *2.2
surface*, or *the diff*: the readout quotes the matching transcript line, and the diff is computed as a set
difference over the two fixed export lists — added `window/3`, removed nothing. Degrades to the static panels
plus this paragraph.

## §1 · The transcript (#transcript)

Line P5 and the tally of the committed output, verbatim:

```text
P5 review ok -- surface grew by exactly one export: window/3 -- the review Chapter 2.1's decision required, performed
PASS 5/5
```

The review procedure, now precedent: the diff that adds a function carries the gate update that admits it —
one export, one gate update, one sentence in the record. No fourth read has earned an export yet, which is the
review bar working.

## §2 · The pre-amendment record (#before)

Evidence outputs are frozen snapshots of their day; scripts evolve with the surface, committed records do not.
The amended `bcs_rung_2_1_check.exs` re-runs green under the grown surface, while its committed output stays
exactly as it was — the historical proof of what the surface used to be. The full 2.1 record, verbatim:

```text
boot: two stores under one_for_one; native codec self-check passed at each init
R1 surface ok -- exports: six domain functions plus OTP callbacks, nothing else -- no table, no pid, no internals
R2 existence ok -- existence restored, data not: fresh table after kill -- durability is a different chapter's job
R4 radius ok -- sibling untouched (one_for_one): ord_store pid stable, row intact through prt_store's crash
R3 checkpoint ok -- recovered through the boundary, not the heap: re-put from a read-back row
R5 gate ok -- prt_store refuses an ORD name with {:error, :namespace} -- admitted kinds are per-boundary
PASS 5/5
```

R1's "six domain functions plus OTP callbacks, nothing else" is the line the amendment was measured against.
This generalizes the agent guides' benchmark rule to every rung in the series: a record is what was true on
its day, and the day is in the file.

## §3 · The desk reads (#reads)

Three one-call reads, and a review bar that has admitted no fourth:

- **`get/2`** — when the name is known: *what is this instrument*.
- **`page_desc/2`** — when the question is *latest*: *what are the latest orders* — a `prev` walk from the
  table's end.
- **`window/3`** — when the question is *between*: *what happened between 14:30 and 14:32*. The contract is
  precise: `window(store, lo, hi)` is `[lo, hi)`, ascending, bounds gated against the store's namespace,
  cursors synthesized by `min_for`. Window bounds are ingress — synthetic or not, a cursor is an id arriving
  at a boundary, and it meets the gate like any other.

### Interactive 2 — the read chooser

Four desk questions as buttons; the readout names the read and its contract:

- *what is this instrument* → `get/2`.
- *what are the latest orders* → `page_desc/2`.
- *what happened between 14:30 and 14:32* → `window/3`, `[lo, hi)`, ascending, bounds gated.
- *who holds this asset* → no read here, and none should be added: the pair is a relation, and **Chapter 2.5**
  owns it.

Degrades to the static list above.

## References (#refs)

Sources: Erlang/OTP — the ets module (`https://www.erlang.org/doc/apps/stdlib/ets.html`; ordered_set term
order, select/2) · Erlang/OTP — the supervisor behaviour
(`https://www.erlang.org/doc/apps/stdlib/supervisor.html`; the one_for_one tree the 2.1 record speaks in).
Related: `/bcs/elixir-core/property-stores` (the B2.2 hub) · `/bcs/elixir-core` (B2 · The Elixir BCS Core) ·
`/bcs` (course home) · `/elixir` (the umbrella where echo_data lives).

## Pager

Previous: `/bcs/elixir-core/property-stores/chronology-without-a-column` — B2.2.2 · Chronology Without a
Column. Next: `/bcs/elixir-core/property-stores` — B2.2 · Property Stores on ETS (the hub).
