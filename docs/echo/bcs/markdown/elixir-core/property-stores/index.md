# B2.2 · Property Stores on ETS — the substrate becomes the property database

> Route: `/bcs/elixir-core/property-stores` (module hub, B2.2). The route-mirror source-of-record. Teaches
> `content/bcs2.2.md`; every figure verbatim from the committed `bcs_rung_2_2_check.out` (`PASS 5/5`) and the
> real `property_store.ex`. Build stamp: `BCS0NuRyZVcbR2`.

## Hero

Kicker: `B2.2 · PROPERTY STORES ON ETS — MANUSCRIPT CHAPTER 2.2`. Title: **The substrate becomes the
database.** Lede — three system tables under one tree — `AST` instruments, `PRT` balances, `ORD` orders — with
the branded id as the only key, chronology as a property of the keyspace rather than a column, and exactly one
amendment to the store module: `window/3`. Heronote — the chapter is `content/bcs2.2.md`; the rung behind it is
bcs2.2 (`bcs_rung_2_2_check.exs`), its committed transcript closes `PASS 5/5`, and the 2.1 rung re-runs green
under the grown surface.

### Interactive 1 — the gate stepper (hero)

Six cells — the boot line plus P1–P5 — drawn as an SVG strip. Select a line to read its verbatim transcript
text in the readout, plus a one-sentence reading. Degrades to the static transcript in §2.

## §1 · The desk's three questions (#why)

The trading desk's read patterns are the chapter's requirements written plainly:

- **Latest** — *what are the latest orders* is a newest-first page: `page_desc/2` walking the table tail, no
  timestamp column consulted.
- **Between** — *what happened between 14:30 and 14:32* is a window: two synthetic cursors, one half-open
  select — `window/3`.
- **Known name** — *what is this instrument* is a get by name: `get/2`, the only key.

A database that needs a timestamp column, an index on it, and a query planner to answer the first two has paid
three times for what the keyspace already carries. The part preface's guideline — a table keyed by branded ids
is a timeline, add no second clock — is cashed here as working reads on real stores.

## §2 · The proof (#proof)

The full committed output, verbatim (seven lines):

```text
boot: three system tables under one tree -- AST instruments, PRT balances, ORD orders
P1 shape ok -- instrument and balance rows live behind their own boundaries; values are private representations
P2 key ok -- the branded form is the only key: the same snowflake's decimal rendering refused as :invalid
P3 order ok -- newest five by byte order equal the last five minted: no timestamp column consulted
P4 window ok -- window [tA,tB) by synthetic cursors returned 100 of 100 expected, ascending by key
P5 review ok -- surface grew by exactly one export: window/3 -- the review Chapter 2.1's decision required, performed
PASS 5/5
```

Five gates: the database's shape, the only-key law, both chronology reads, and the review itself — while the
2.1 rung re-runs green under the grown surface. A gate line is a recording of what the store refused or
returned on stage, committed beside the script that produced it.

## §3 · The dives (#dives)

- **B2.2.1 · The Only Key** (`the-only-key`) — P1 the database shape, values as private representations; P2 the
  decimal rendering refused `:invalid` — the third door closed at the ingress, after storage (Chapter 1.3) and
  CPU (Appendix 1.1).
- **B2.2.2 · Chronology Without a Column** (`chronology-without-a-column`) — P3 the newest five by byte order;
  P4 `window/3`, `[lo, hi)` half-open, `100 of 100 expected, ascending by key` — the order theorem as a read
  path, with the real match spec and its Go counterpart.
- **B2.2.3 · The Review, Performed** (`the-review-performed`) — P5 the surface grew by exactly one export; the
  three desk reads; the frozen-record ethic, with the 2.1 transcript as the pre-amendment surface evidence.

Reach for `get/2` when the name is known, `page_desc/2` when the question is *latest*, `window/3` when the
question is *between* — and no fourth read has earned an export yet, which is the review bar working. The
moment *who holds this asset* becomes a question, the pair is a relation, and **Chapter 2.5** owns it.

## References (#refs)

Sources: Erlang/OTP — the ets module (`https://www.erlang.org/doc/apps/stdlib/ets.html`; ordered_set term
order, select/2 and match specifications, protection levels) · Erlang/OTP — the supervisor behaviour
(`https://www.erlang.org/doc/apps/stdlib/supervisor.html`; the one tree the three stores run under).
Related: `/bcs/elixir-core` (B2 · The Elixir BCS Core) · `/bcs` (course home) · `/redis-patterns` (the storage
economics under the keyspace) · `/elixir` (the umbrella where echo_data lives).

## Pager

Previous: `/bcs/elixir-core` — B2 · The Elixir BCS Core. Next:
`/bcs/elixir-core/property-stores/the-only-key` — B2.2.1 · The Only Key.
