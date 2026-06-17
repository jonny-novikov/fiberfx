# B2.2.1 · The Only Key — one name, one rendering

> Route: `/bcs/elixir-core/property-stores/the-only-key` (dive 1 of 3, module B2.2). The route-mirror
> source-of-record. Teaches P1–P2 of `content/bcs2.2.md`; every figure verbatim from the committed
> `bcs_rung_2_2_check.out` and the contract vectors. Build stamp: `BCS0NuRyZbIa2K`.

## Hero

Kicker: `B2.2 · DIVE 1 — THE ONLY KEY`. Title: **The branded form is the only key.** Lede — three stores
under one tree hold the desk's rows — `AST` instruments, `PRT` balances, `ORD` orders — and every key in every
table is the 14-byte branded form. The same snowflake rendered as a decimal string is refused at the boundary:
`:invalid`, on read and on write. Heronote — source `content/bcs2.2.md`, quoting `bcs_rung_2_2_check.out`
(lines boot, P1, P2); the store is `property_store.ex`.

### Interactive 1 — the database shape (hero)

The three-store tree drawn as an SVG: one supervisor, three named stores — `ast_store` (AST instruments),
`prt_store` (PRT balances), `ord_store` (ORD orders). Select a store to read what lives behind its boundary:

- `AST` — an instrument with its tick size. Values are private representations: what a row looks like inside
  is not part of any other system's contract.
- `PRT` — a balance with its cash. The balance value carries a positions map for now — interim by declaration,
  superseded when **Chapter 2.5** promotes the portfolio-holds-asset pair to the relations store.
- `ORD` — orders, the chronology dive's subject: three hundred mints across real wall time, paged and windowed
  off the keyspace alone.

The three-store tree is the template a fourth store joins by adding one `{name, namespace}` pair. Degrades to
the static diagram plus this list.

## §1 · The transcript (#transcript)

Lines boot, P1, P2 of the committed output, verbatim:

```text
boot: three system tables under one tree -- AST instruments, PRT balances, ORD orders
P1 shape ok -- instrument and balance rows live behind their own boundaries; values are private representations
P2 key ok -- the branded form is the only key: the same snowflake's decimal rendering refused as :invalid
```

P1 boots the three stores and writes domain rows behind their own boundaries — an instrument with its tick
size, a balance with its cash — and the gate line states the part's quiet rule: values are private
representations. P2 takes the instrument's own snowflake, renders it as the 19-digit decimal, and offers it
back — refused as `:invalid`, on both read and write.

## §2 · The third door closed (#doors)

The key law is now enforced at every layer the series has measured:

- **Door 1 · storage** — the store charges more for the decimal (Chapter 1.3).
- **Door 2 · CPU** — every compiled runtime renders it slower (Appendix 1.1).
- **Door 3 · ingress** — the boundary refuses it outright (here): `:invalid`, read and write.

## §3 · Interactive 2 — the same name, two renderings (#gate)

The contract's canonical vector binds the pair: `encode("USR", 274557032793636864) = "USR0KHTOWnGLuC"` — one
snowflake, two renderings. The model presents both, on both verbs, to a store admitting `USR`, through the
same gate path the real store runs — `handle_call` for `get` and for `put` both pass the id through
`Bcs.gate(id, s.ns)` before the table is touched (`property_store.ex`):

- `get USR0KHTOWnGLuC` → admitted, `{:ok, 274557032793636864}` — the table is touched only now.
- `put USR0KHTOWnGLuC` → admitted — the same gate guards the write path.
- `get 274557032793636864` → `{:error, :invalid}` — 18 characters, not 14; the table is never touched.
- `put 274557032793636864` → `{:error, :invalid}` — the verb does not matter; the gate runs before lookup and
  before insert.

Degrades to this static list.

## §4 · The label on the interim (#interim)

The interim representation is declared. The balance's embedded positions map ships labeled as pre-relational,
with its supersession chapter named — drift is a representation that outlived its label, and this one cannot.
Keep entity-embedded maps only while the pairs they encode have no traversal needs of their own; the moment
*who holds this asset* becomes a question, the pair is a relation, and **Chapter 2.5** owns it.

## References (#refs)

Sources: Erlang/OTP — the ets module (`https://www.erlang.org/doc/apps/stdlib/ets.html`; protection levels,
ordered_set term order) · Erlang/OTP — the supervisor behaviour
(`https://www.erlang.org/doc/apps/stdlib/supervisor.html`; the one tree the three stores run under).
Related: `/bcs/elixir-core/property-stores` (the B2.2 hub) · `/bcs/elixir-core` (B2 · The Elixir BCS Core) ·
`/bcs` (course home) · `/redis-patterns` (the storage economics under the keyspace).

## Pager

Previous: `/bcs/elixir-core/property-stores` — B2.2 · the hub. Next:
`/bcs/elixir-core/property-stores/chronology-without-a-column` — B2.2.2 · Chronology Without a Column.
