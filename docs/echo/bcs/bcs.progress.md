# BCS course — progress
<show-structure depth="2"/>

Status of the served course at `/bcs`. The shape is **Landing → Chapters (B0–B8) → 3 Dives each**. Each chapter ships an HTML chapter page, three HTML dive pages, and one Writerside transcript `bcs.<N>.md`. Every HTML page passes `course_lint` (slug · svg · no-dump · doors · grounding · balance, exit 0); every transcript passes the voice `sweep` (exit 0).

The chapter map was re-derived from the fiberfx repo (`echo/apps`, `docs/echo_mq/emq.roadmap.md`): the apps are `echo_data`, `echo_mq`, `echo_store`, `echo_graft`, `echo_wire`, `echo_bot`, `codemojex` — there is **no `echo_cache` app** (the cache is an EchoMQ family, `emq.7`), so the durable-store chapter is **EchoStore**, and the integration, game, and deployment chapters land on **codemojex**.

## Summary

- **Landing**: built.
- **Chapters complete** (page + 3 dives + transcript): **2 of 9** — B0, B1.
- **Chapters part-built** (chapter page only): B2.
- **Dives written**: **6 of 27** — B0.1–0.3, B1.1–1.3.
- **Transcripts**: `bcs.0.md`, `bcs.1.md`.
- **Next**: B2 dives (2.1 `otp-application`, 2.2 `property-stores`, 2.3 `relations`) + `bcs.2.md`.

## Chapters

| chapter | route | source | chapter page | dives | transcript |
|---|---|---|---|---|---|
| Landing | `/bcs` | — | done | — | — |
| B0 · Overview | `/bcs/overview` | — | done | 3 / 3 done | `bcs.0.md` done |
| B1 · Ideas Behind | `/bcs/ideas` | — | done | 3 / 3 done | `bcs.1.md` done |
| B2 · The Elixir BCS Core | `/bcs/elixir-core` | `echo_data/bcs` | done | 0 / 3 pending | pending |
| B3 · The Bus | `/bcs/bus` | `echo_mq` | pending | 0 / 3 | pending |
| B4 · EchoStore | `/bcs/store` | `echo_store` | pending | 0 / 3 | pending |
| B5 · The Persistence Floor | `/bcs/persistence` | `echo_store/graft`, `echo_graft` | pending | 0 / 3 | pending |
| B6 · Putting It All Together | `/bcs/together` | the umbrella | pending | 0 / 3 | pending |
| B7 · Codemojex BCS | `/bcs/codemojex` | `echo/apps/codemojex` | pending | 0 / 3 | pending |
| B8 · Production on Fly | `/bcs/fly` | `fly.toml`, Docker, Valkey | pending | 0 / 3 | pending |

Routes and dive slugs for B3–B8 are provisional until those chapters are authored.

## Chapter intent (from the repo analysis)

- **B3 · The Bus** — `echo_mq` v2.6.3, the Valkey-native bus: the braced/branded keyspace, `Jobs`/`Lanes`/`Flows`/`Consumer`, and the 3.0 Stream Tier (`EchoMQ.Stream`/`StreamConsumer`, emq3.1–3.4 shipped).
- **B4 · EchoStore** — `echo_store`: the durable store and the durability dial (`EchoStore.Table`, `EchoStore.Coherence` keyed by the id, `EchoStore.Durability` with Memory/SQLite/Postgres/Graft adapters).
- **B5 · The Persistence Floor** — the Graft engine beneath the dial: `EchoStore.Graft` (the append-only LSN page log) and the Rust `echo_graft`, streamed to Tigris via `Graft.Remote.Tigris`.
- **B6 · Putting It All Together** — the umbrella as one running system: BCS systems over the bus over the store, end to end (replaces the former B6 Go and B7 Node).
- **B7 · Codemojex BCS** — a forward future-vision: the multiplayer Telegram game re-seen on BCS, on the real skeleton in `echo/apps/codemojex` (workers draining `EchoMQ.Lanes`, entities as branded ids, state in stores).
- **B8 · Production on Fly** — Codemojex in production: the container, Valkey, and the `fly.toml`, on the deployment patterns under `go/` and `docs/valkey/valkey.fly.md`.

## Dives — written

| dive | route | figure (the idea it draws) | grounded figure |
|---|---|---|---|
| B0.1 · The one relocation | `/bcs/overview/the-relocation` | the boundary moving from the object to the system | — |
| B0.2 · Identity as a contract | `/bcs/overview/identity-as-contract` | the name with its four guarantees | `234878118` |
| B0.3 · The stack and the floor | `/bcs/overview/stack-and-floor` | `echo_data`/`echo_mq`/`echo_store` over the durable floor | — |
| B1.1 · The system substrate | `/bcs/ideas/the-substrate` | a process owning a private table that is a timeline | — |
| B1.2 · The identity contract | `/bcs/ideas/the-contract` | four integer failures, each retired by a property | `234878118` |
| B1.3 · From ECS to BCS | `/bcs/ideas/ecs-to-bcs` | an index dying at three walls; the name crossing | — |

## Dives — planned next (B2)

| dive | route | figure (intended) |
|---|---|---|
| B2.1 · A system is an OTP application | `/bcs/elixir-core/otp-application` | a supervision tree of per-namespace stores |
| B2.2 · Property stores on ETS | `/bcs/elixir-core/property-stores` | an ordered keyspace read by `:ets.last` / `:ets.prev` |
| B2.3 · Relations are systems | `/bcs/elixir-core/relations` | an edge as a row keyed by the pair of names |

## Standing rules in force

- **Structure**: a chapter is exactly three dives; no module layer; B0 is Overview; the course runs B0–B8.
- **Figures**: one interactive `.anat` figure per page; it draws the idea from `rect`/`path` shapes with word labels — never a numbered node-arc.
- **Grounding**: a number appears only if a committed `.out` or source asserts it; the only figures used so far are the `self_check!` contract vectors.
- **Transcript**: every chapter ships `bcs.<N>.md` with the full prose of the chapter and its three dives, generated from the same prose as the pages.

## Legend

- **done** — built, gated, present in outputs.
- **pending** — not yet authored.
