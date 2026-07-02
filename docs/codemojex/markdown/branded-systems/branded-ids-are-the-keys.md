# C1.1 — Branded ids are the keys

> Route `/codemojex/branded-systems/branded-ids-are-the-keys` · dive of C1 · stamp `CMX0OSU7SXsSOY`
> Grounding re-found in `echo/apps` on 2026-07-02.

The brand *is* the type. A Codemojex id is 14 bytes — a three-character uppercase namespace and
eleven Base62 characters over a 63-bit snowflake — and it is validated by shape, not by a
registry, so the brand carried on a value is what gets checked at every boundary. The id is the
primary key in every relational schema, the key on every Valkey structure, and the id on every
bus job. Because it carries its mint time it doubles as a cache version and an idempotency token.

## The contract — `EchoData.BrandedId`

One module owns the codec (`echo/apps/echo_data/lib/echo_data/branded_id.ex`):

- `@type t :: <<_::112>>` — 112 bits, exactly 14 bytes.
- `defguard is_branded(id) when is_binary(id) and byte_size(id) == 14` — the shape is the guard.
- `def generate!(ns), do: encode!(ns, EchoData.Snowflake.next())` — mint a fresh id for a namespace.
- `def parse(id)` → `{:ok, namespace, snowflake}` or `:error`.
- `def valid?(id), do: parse(id) != :error` — validation is a parse, not a lookup.

The codec's own moduledoc doctest, verbatim:

```
iex> EchoData.BrandedId.encode!("USR", 274557032793636864)
"USR0KHTOWnGLuC"
iex> EchoData.BrandedId.parse("USR0KHTOWnGLuC")
{:ok, "USR", 274557032793636864}
iex> EchoData.BrandedId.hash32(274557032793636864)
234878118
```

(`USR` is the codec's example namespace, not a Codemojex brand.) The 11 Base62 characters encode
a `ts(41) | node(10) | seq(12)` snowflake, epoch `1704067200000`: the high 41 bits are
milliseconds since the epoch (so ids sort by creation), 10 bits are the minting node (0–1023,
coordination-free), and 12 bits are the per-millisecond counter (0–4095 — 4096 ids per node per
millisecond).

## The fifteen-namespace roster

Fifteen namespaces carry the game today (design §Identity). The founding nine — `PLR ROM GAM GES
EMS TXN JOB NOT CMD` — and the six their shipped systems added — `SES` (cm.4), `RVL` (cm.6),
`PKG`/`ORD`/`OTX`/`WHK` (cm.7). The distinction that matters is roster vs live mint. Thirteen have
a live `generate!("…")` call site in `echo/apps/codemojex`:

| brand | entity | live mint site |
|---|---|---|
| `PLR` | player | `wallet.ex:26` |
| `ROM` | room (template) | `rooms.ex:24` |
| `GAM` | game | `rooms.ex:90` |
| `GES` | guess | `game.ex:109` |
| `EMS` | emoji set | `emoji_set.ex:35` |
| `TXN` | wallet transaction | `wallet.ex:464` |
| `JOB` | a unit of work on the bus | `game.ex:180` (and `notifier.ex`, `echo_bot.ex`) |
| `NOT` | an outbound notification | `notification_worker.ex:85` |
| `SES` | session | `session.ex:36` |
| `RVL` | revenue-ledger row | `wallet.ex:521` |
| `PKG` | key package (catalog) | `migrations/…create_key_shop.exs:108` |
| `ORD` | order | `key_shop.ex:142` |
| `OTX` | order transaction | `key_shop.ex:264` |

Two of the fifteen have no live mint. `CMD` is a designed namespace for an inbound bot command,
but the shipped bridge (`echo_bot.ex`) mints a `JOB` id — each command rides its own JOB-id lane,
so `CMD` names the concept while `JOB` keys the work. `WHK` is a forward schema for the first
push rail (on-chain TON); its `webhooks` table is not created this rung and it has no live call
site — it is the designed shape the first push-rail rung adds cleanly. Roster: 15 · live mints:
13 · CMD folds onto a JOB id · WHK reserved forward.

## The id as the primary key

Every one of the eleven Ecto schemas (`lib/codemojex/schemas/*.ex`) declares the same primary
key: `@primary_key {:id, :string, autogenerate: false}`. The id is a string minted by the
application, not a serial the database generates — `autogenerate: false` — because the id is
minted before the row exists, on any node, with no coordination. The same 14-byte value then keys
the Valkey lane, the leaderboard entry, and the bus job. One name, asked at different depths.

## References

### Sources

- King — *Announcing Snowflake* (2010) — the time-ordered `ts|node|seq` ids that key every branded
  entity across every tier. https://blog.twitter.com/engineering/en_us/a/2010/announcing-snowflake
- Helland — *Life Beyond Distributed Transactions* (CIDR 2007) — entities behind boundaries,
  idempotent activities keyed by a stable name. https://ics.uci.edu/~cs223/papers/cidr07p15.pdf

### Related

- `/bcs` — the branded-id contract in full.
- `/codemojex/branded-systems` — the chapter hub.
- `/codemojex/branded-systems/the-four-layers` — C1.2, the tiers the id threads, next.
