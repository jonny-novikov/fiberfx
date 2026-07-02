# C0 — Overview

`/codemojex/overview` · the course home for the game placed in its family, the engine that
treats every mode as policy, and the four-layer architecture one glance can hold.

Codemojex is a real-time, multiplayer code-breaking competition that runs as a Telegram Mini
App — Mastermind played with an emoji keyboard, for money. This chapter opens the course the way
the design opens the system: the game placed in its family, the engine that treats every mode as
policy on the same branded entities, and the four-layer architecture one glance can hold. It is
the shipped game (cm.1–cm.7) taught as-built; the reader leaves knowing why a radical new game
mode needs no new code.

## Modes are policy, not code

A game (`GAM`) carries a **type** and the four policies that type selects — **feedback**,
**scoring**, **settlement**, **economy** — and the secret, the guess, and the distance math are
one code path shared by every type. `Codemojex.Rooms.policies_for/2` is the whole fork
(`echo/apps/codemojex/lib/codemojex/rooms.ex`):

| Mode | feedback | scoring | settlement | economy |
|---|---|---|---|---|
| Classic (ordinary) | `score` | `linear` | `live` | `winner_take_all` |
| Golden Room (classic + `golden:true`) | `score` | `linear` | `live_split` | `proportional` |
| Blind Golden (type `golden`) | `none` | `linear` | `sealed` | `winner_take_all` |

**Scoring is `linear` in every row.** The distance math is the invariant; only the policies
around it change. A new mode is a new set of policy values on the same entities — not a table per
type, not a class hierarchy. In BCS the brand *is* the type.

## The chapter in three dives

- **C0.1 · The game and the family** — `/codemojex/overview/the-game-and-the-family`. The
  Mastermind family, the feedback function as the defining element, the code space of positions
  and symbols, and the six-emoji secret.
- **C0.2 · The engine and its policies** — `/codemojex/overview/the-engine-and-its-policies`. The
  generic engine, `policies_for/2` verbatim, the one shared code path, and why a new mode needs no
  new code.
- **C0.3 · The architecture at a glance** — `/codemojex/overview/the-architecture-at-a-glance`.
  The four layers — the thin Phoenix surface, the `Codemojex` facade and domain systems, the
  EchoMQ bus on Valkey, and the storage tiers — with the secret and the money on the floor.

## Grounding

- `echo/apps/codemojex/lib/codemojex/game.ex` — the `Codemojex` facade the surface calls
  (`Codemojex.Guesses`, `Codemojex.ScoreWorker`, `Codemojex.Settle`).
- `echo/apps/codemojex/lib/codemojex/rooms.ex` — `policies_for/2`, the type→policy fork.
- `codemojex.design.md` §The engine / §The game in one paragraph / §The architecture at a glance.
- `stories/rooms-and-games.stories.md` — the lifecycle acceptance catalog.

## References

### Sources
- Mastermind (the board game) — the guess-against-a-hidden-code loop Codemojex plays with emoji.
  https://en.wikipedia.org/wiki/Mastermind_(board_game)
- King — Announcing Snowflake (2010) — the time-ordered ids that key every entity across every
  tier. https://blog.twitter.com/engineering/en_us/a/2010/announcing-snowflake

### Related
- `/bcs` — the architecture law · `/bcs/codemojex` — this game taught inside the BCS course.
- `/codemojex/branded-systems` — C1, the identity law, next.
