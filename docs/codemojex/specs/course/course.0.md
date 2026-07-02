# Codemojex course · C0 — Overview

> **Route** `/codemojex/overview` · **stub shipped** — this manuscript is the chapter brief; the C0
> authoring rung deepens both.
> **Sources** roadmap §The game, and the family it belongs to / §The engine and its policies ·
> design §The engine / §The game in one paragraph / §The architecture at a glance.

Codemojex is a real-time, multiplayer code-breaking competition that runs as a Telegram Mini App —
Mastermind played with an emoji keyboard, for money. The chapter opens the course the way the design
opens the system: the game placed in its family, the engine that treats every mode as policy on the
same branded entities, and the four-layer architecture one glance can hold. It is the shipped game
(cm.1–cm.7) taught as-built; the reader leaves knowing why a radical new game mode needs no new code.

## C0.1 · The game and the family

A game hides a secret of six emoji drawn from a themed set; a player submits a sequence and the game
reports how close it was. That places Codemojex in the Mastermind family, where the defining element
is the **feedback function** — what a guess reveals about the secret — over a code space of positions
and symbols. The classic mode reveals a linear score; the blind `golden`-type mode reveals nothing
until close; a Golden Room is a live tournament on the classic base. Dive route:
`/codemojex/overview/the-game-and-the-family` (planned).

## C0.2 · The engine and its policies

The Game system is a generic Mastermind engine: a game (`GAM`) carries a type and the four policies
the type selects — feedback, scoring, settlement, economy — and the secret, the guess, and the
distance math are one code path shared by every type. One `games` table with a type discriminator,
not a table per type: in BCS the brand *is* the type. Dive route:
`/codemojex/overview/the-engine-and-its-policies` (planned).

## C0.3 · The architecture at a glance

Four layers, each owning its tier: a thin Phoenix surface behind privacy-safe views; the `Codemojex`
facade and the domain systems; the EchoMQ bus on Valkey carrying guesses on fair lanes; and the
storage tiers — Postgres the system of record, Valkey the derived real-time state, EchoStore the
immutable near-cache. Money and the secret live on the floor. Dive route:
`/codemojex/overview/the-architecture-at-a-glance` (planned).

## Grounding

- `echo/apps/codemojex/lib/codemojex/game.ex` — the `Codemojex` facade the surface calls.
- [`codemojex.design.md`](../../codemojex.design.md) §The engine / §The game in one paragraph /
  §The architecture at a glance; [`codemojex.roadmap.md`](../../codemojex.roadmap.md) §The game, and
  the family it belongs to.
- [`stories/rooms-and-games.stories.md`](../../stories/rooms-and-games.stories.md) — the lifecycle
  acceptance catalog.

## Doors

[/bcs](/bcs) — the identity law · [/echomq](/echomq) — the bus · the next chapter,
[`C1`](course.1.md).
