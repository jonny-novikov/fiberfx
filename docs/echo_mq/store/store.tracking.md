# EchoStore `:tracking` — server-assisted client-side caching

> **Status: BUILT — shipped green, solo (a Normal, single-file, additive rung).** The third L1 coherence
> mode: `coherence: :tracking` arms Valkey **server-assisted client-side caching** (RESP3 `CLIENT TRACKING ON
> BCAST`) over a table's own `ecc:{table}:` key prefix, so any writer's change to a cached key pushes an
> invalidation the L1 owner evicts. This **resolves the `ewr` Movement II seam** (the roadmap's seam 3, the
> "possible wire MAJOR") — and resolves it **without touching the frozen wire**: the connector already carries
> everything required.

## Why this is *not* a wire rung (the settled horizon decision)

The `ewr` roadmap pre-declared server-assisted caching a **wire MAJOR**, on the assumption that re-arming
tracking across a reconnect needs a boot-step inside the frozen `EchoMQ.Connector`. Ground truth refutes that:

- The connector **already** routes RESP3 push frames to a `push_to` pid as `{:emq_push, payload}`
  (`connector.ex` `route_pushes/2`), and **already** peels pushes out of the in-band reply stream
  (`fill/5`) so they never corrupt reply alignment.
- The connector **already** emits `[:emq, :connector, :reconnect]` telemetry after each reconnect.
- `EchoStore.Table` **already** owns a dedicated RESP3 subscriber connection (the `:broadcast` lane) with
  `push_to: self()` and a push-frame `handle_info`, plus the newer-wins L1-drop (`apply_coherence`,
  `Coherence.newer?`).

So the feature is a pure **consumer**: a new `:tracking` mode *beside* `:broadcast`, built from the existing
public wire surface (`Connector.start_link(push_to:)`, `Connector.command/3`, the reconnect telemetry). The
MAJOR boot-step buys only **keeping the cache warm across a reconnect** — an optimization, deferred, maybe
never. Correctness comes instead from **flush-on-reconnect**.

## The surface (what shipped)

A new value for the `:coherence` option on `EchoStore.Table.start_link/1`, parallel to `:none` / `:broadcast`:

| Mode | Lane | Carries | Catches | Use |
|---|---|---|---|---|
| `:broadcast` | app-level `PUBLISH ecc:{table}:coh` | a **version** (precise newer-wins) | only **cooperative** writers (those that call `Coherence.broadcast`) | self-writing caches, cross-instance |
| `:tracking` | server-assisted `CLIENT TRACKING ON BCAST` | a **key** (blunt evict) | **any** writer of `ecc:{table}:`, cooperative or not | read-mostly caches over an externally-written L2 |

`:tracking` setup mirrors `:broadcast`: start the RESP3 `push_to: self()` connection, then issue
`CLIENT TRACKING ON BCAST PREFIX ecc:{table}:` (synchronously, fail-fast) instead of `SUBSCRIBE`. Invalidation
pushes arrive as `{:emq_push, ["invalidate", [keys]]}`; each key strips its `ecc:{table}:` prefix to the id and
`:ets.delete`s the L1 row. **L2 is never touched** — the row is dropped so the next read refills from the
changed L2. A `["invalidate", nil]` flush push drops every row.

## Invariants

- **Zero frozen-wire edit.** `EchoMQ.Connector` / `RESP` / `Script` untouched; no protocol/conformance/fence
  change; the wire version does not move. The change is one file: `echo_store/lib/echo_store/table.ex`.
- **Behaviour-preserving for `:none` / `:broadcast`.** The tracking path is a purely additive block; the
  broadcast block is byte-identical to HEAD. The `stats/1` counter set is unchanged — a tracking evict reuses
  the `:coh_applied` counter rather than adding one.
- **Reconnect survival = flush-then-rearm.** `CLIENT TRACKING` is *not* in the connector's re-issued
  subscription set, so on `[:emq, :connector, :reconnect]` (filtered to this table's `sub` label) the owner
  **flushes L1 then re-arms tracking** — correctness by construction, no missed-invalidation window. The
  telemetry handler is detached on `terminate`.
- **L1-only eviction.** The blunt evict drops the L1 row; it never writes L2 (which is the writer's truth).

## The documented trade (`:tracking` vs `:broadcast`)

BCAST notifies on *any* write to the prefix — **including the table's own** (writes go via the table's main
connection, tracking via a separate one, so per-connection `NOLOOP` cannot suppress them). A cache that *writes*
its own keys therefore churns (evict → refill) under `:tracking`; the mode is meant for caches whose L2 is
authored **elsewhere**, where there is no self-write. A self-writing cache uses `:broadcast` (it already knows
its own writes and carries the version). The two lanes are **complements, not alternatives**.

## Gate

Per-app from `echo/apps/echo_store`: `valkey-cli -p 6390 ping` → `PONG`;
`TMPDIR=/tmp mix compile --warnings-as-errors`; `TMPDIR=/tmp mix test --include valkey`. The proof is a
**cross-connection invalidation**: a row held in L1, an external `SET` to its `ecc:{table}:` key on a *second*
connection, the L1 row gone — plus the deterministic `nil`-flush and reconnect-flush+re-arm paths. Determinism
posture: a new process (the tracking lane) + push handlers, no id-mint/lease — a multi-seed sweep, not the ≥100
loop.

---

Edit set: `echo/apps/echo_store/lib/echo_store/table.ex` · `echo/apps/echo_store/test/table_test.exs` · this
doc · the `ewr` seam-3 resolution note. Resolves: [`../wire/ewr.roadmap.md`](../wire/ewr.roadmap.md) seam 3.
Design context: [`design/store.design.md`](design/store.design.md) · the valkey-go peer:
[`../../valkey/valkey.proposals.md`](../../valkey/valkey.proposals.md) (Tier 2).
