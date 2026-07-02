# C1 — The Game as Branded Systems

> Route `/codemojex/branded-systems` · the chapter hub · stamp `CMX0OSU7SXsSOX`
> Brief: `docs/codemojex/specs/course/course.1.md` · grounding re-found in
> `echo/apps/codemojex` on 2026-07-02.

Every entity in Codemojex is a 14-character branded snowflake — a three-character uppercase
namespace and eleven Base62 characters over `ts(41) | node(10) | seq(12)`, epoch
`1704067200000` — and the id is the only value that crosses a boundary. It keys the row in
Postgres, the entry in Valkey, the job on the bus, and the message that announces a result;
because the id carries its mint time, it doubles as a cache version and an idempotency token.
Fifteen namespaces carry the game today — the founding nine (`PLR ROM GAM GES EMS TXN JOB NOT
CMD`) plus the six their shipped systems added (`SES` cm.4 · `RVL` cm.6 ·
`PKG`/`ORD`/`OTX`/`WHK` cm.7).

## The framing figure — one name, asked at different depths

A brand × tier matrix over four representative namespaces and the three storage tiers. The lit
cells are the tiers the name lives in — and the tiers a name skips are the design:

| brand | Postgres · the floor | Valkey · bus + board | EchoStore · L1 |
|---|---|---|---|
| `PLR` | `players` | lanes · board | — |
| `GAM` | `games` | board · counters · lock | `:cm_games` |
| `TXN` | `transactions` | — | — |
| `SES` | — | `ecc:{sessions}:` | `:cm_sessions` |

`PLR` rests on the floor and races on the bus and the board. `GAM` spans all three tiers —
the row (secret included, server-side), the per-game competitive state, and the immutable
near-cache entry versioned by the id itself. `TXN` is floor-only: an append-only ledger row
written in the same database transaction as the balance change — no cache, no Valkey copy,
because the wallet is the one system where correctness outranks speed. `SES` has no
relational floor at all: it lives in Valkey through a mutable EchoStore table with
`:tracking` coherence, so a revoked session is evicted from every holder's L1 immediately.

Source: design §Identity (the namespace table) · `Codemojex.Tables` · `Codemojex.View`
(the `cm:<GAM>:…` counters) · `Codemojex.Schemas.Transaction`.

## The three dives

- **C1.1 · Branded ids are the keys** — `/codemojex/branded-systems/branded-ids-are-the-keys`.
  The brand *is* the type: `EchoData.BrandedId.generate!/1` validates by shape, not a
  registry; the namespace roster and its real mint sites; the id as primary key in every tier
  (all eleven schemas declare `@primary_key {:id, :string, autogenerate: false}`).
- **C1.2 · The four layers** — `/codemojex/branded-systems/the-four-layers`. Identity beneath
  a Postgres system of record, an EchoStore near-cache, an EchoMQ bus, and a Phoenix surface —
  money, the secret, and the commitment live on the floor; everything in Valkey is derived and
  reconstructable.
- **C1.3 · The privacy boundary** — `/codemojex/branded-systems/the-privacy-boundary`.
  Structural, not a filter at the edge: the secret exists in exactly one place a player can
  never read, no player-facing view selects it, and the live events carry a name and a score —
  never the code or the guess.

## Grounding

`lib/codemojex/wire.ex` (the one adapter onto the owned wire) · the eleven Ecto schemas
(branded primary keys) · `tables.ex` (the EchoStore near-cache tier) · `view.ex` (the
privacy-safe reads) · design §Identity: the branded component law / §Privacy and fairness ·
`stories/privacy.stories.md`.

## References

### Sources

- King — *Announcing Snowflake* (2010) — the time-ordered `ts|node|seq` ids that key every
  branded entity across every tier. https://blog.twitter.com/engineering/en_us/a/2010/announcing-snowflake
- Helland — *Life Beyond Distributed Transactions* (CIDR 2007) — entities behind boundaries,
  the privacy seam, idempotent activities. https://ics.uci.edu/~cs223/papers/cidr07p15.pdf

### Related

- `/bcs` — the architecture law; the identity contract in full.
- `/codemojex/overview/the-architecture-at-a-glance` — C0.3, the four layers at a glance.
- `/codemojex/rooms-and-modes` — C2, the template and the pin, next.
