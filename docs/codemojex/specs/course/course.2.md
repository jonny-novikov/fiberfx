# Codemojex course · C2 — Rooms, Modes, and the Secret

> **Route** `/codemojex/rooms-and-modes` · **stub shipped** — this manuscript is the chapter brief;
> the C2 authoring rung deepens both.
> **Sources** B7.2 · cm.1 + cm.3 (commit-reveal, the reduced set) · design §The engine /
> §The data model / §The provably-fair secret.

A room is a template and a container; a game is one playthrough inside it. When the first player
joins a waiting room, the room's emoji set and properties are snapshotted onto a fresh game, a secret
of six distinct codes is drawn from the game's own keyboard, and the timer begins. The chapter
teaches the template/instance split, the keyboard as data, and the two golden surfaces that share a
word but not a mechanism: the blind `golden` **type** (commit-reveal, sealed settlement) and the
Golden Room **marker** (a live tournament on the classic base, shipped via cm.5).

## C2.1 · Room as template and mode

A `ROM` holds duration, emoji set, fee, paid or free, seed pool, and a mode with its four policies;
the game snapshots all of it at start, immutable for the game's life. The mode split at the policy
level: `classic` (feedback `score`, settlement `live`) · the blind `golden` type (feedback `none`,
settlement `sealed`) · the Golden Room marker selecting `settlement: "live_split"` /
`economy: "proportional"`. Dive route: `/codemojex/rooms-and-modes/room-as-template-and-mode`
(planned).

## C2.2 · The emoji set

An `EMS` set is the cells a room exposes and their `XXYY` codes (column-then-row), backed by an `RSC`
sprite sheet; the two seeded sets are measured from the real sheets under
[`emoji-sets/`](../../emoji-sets/) at cell size 72. A golden game draws from a per-game randomized
reduced subset (`cell_count`/`cell_codes`) so the blind space stays tractable without hints. Dive
route: `/codemojex/rooms-and-modes/the-emoji-set` (planned).

## C2.3 · The secret and its commitment

A `GAM` draws six distinct codes; the secret is server-side and selected by no player-facing query.
In blind mode the game publishes `commitment = SHA-256(secret ‖ nonce)` (lowercase hex, canonical
UTF-8 encoding) at open and reveals the secret and nonce at close, so any player recomputes and
verifies — a server the player must trust becomes a server the player can check. Dive route:
`/codemojex/rooms-and-modes/the-secret-and-its-commitment` (planned).

## Grounding

- `echo/apps/codemojex/lib/codemojex/rooms.ex` · `emoji_set.ex` ·
  `schemas/{room,emoji_set,game}.ex`.
- [`codemojex.design.md`](../../codemojex.design.md) §The engine / §The data model /
  §The provably-fair secret (golden).
- [`stories/emoji-codes.stories.md`](../../stories/emoji-codes.stories.md) ·
  [`stories/golden-blind.stories.md`](../../stories/golden-blind.stories.md) ·
  [`stories/rooms-and-games.stories.md`](../../stories/rooms-and-games.stories.md).

## Doors

[/bcs](/bcs) — archetypes compose by fold · [`C1`](course.1.md) ← · → [`C3`](course.3.md).
