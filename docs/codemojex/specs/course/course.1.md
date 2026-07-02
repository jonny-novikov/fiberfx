# Codemojex course · C1 — The Game as Branded Systems

> **Route** `/codemojex/branded-systems` · **stub shipped** — this manuscript is the chapter brief;
> the C1 authoring rung deepens both.
> **Sources** B7.1 · cm.1 · design §Identity: the branded component law.

Every entity in Codemojex is a 14-character branded snowflake — a three-character uppercase namespace
and eleven Base62 characters over `ts(41) | node(10) | seq(12)`, epoch `1704067200000` — and the id
is the only value that crosses a boundary. The chapter teaches the identity law on the running game:
the id keys the row in Postgres, the entry in Valkey, the job on the bus, and the message that
announces a result; because the id carries its mint time, it doubles as a cache version and an
idempotency token. Fifteen namespaces carry the game today — the founding nine
(`PLR ROM GAM GES EMS TXN JOB NOT CMD`) plus the six their shipped systems added
(`SES` cm.4 · `RVL` cm.6 · `PKG`/`ORD`/`OTX`/`WHK` cm.7).

## C1.1 · Branded ids are the keys

The brand *is* the type: `EchoData.BrandedId.generate!/1` validates by shape, not a registry, so the
brand carried on a value is what gets checked at every boundary. The namespace table, the mint, and
the id as primary key in every tier. Dive route:
`/codemojex/branded-systems/branded-ids-are-the-keys` (planned).

## C1.2 · The four layers

Identity beneath a Postgres system of record, an EchoStore near-cache, an EchoMQ bus, and a Phoenix
surface — who owns what, and why money, the secret, and the commitment live on the floor while
everything in Valkey is derived and reconstructable. Dive route:
`/codemojex/branded-systems/the-four-layers` (planned).

## C1.3 · The privacy boundary

The boundary is structural, not a filter at the edge: the secret exists in exactly one place a player
can never read, no player-facing view selects it, and the live events carry a name and a score —
never the code or the guess. A player sees their own attempt history and no one else's. Dive route:
`/codemojex/branded-systems/the-privacy-boundary` (planned).

## Grounding

- `echo/apps/codemojex/lib/codemojex/wire.ex` · the eleven `schemas/*.ex` (branded primary keys) ·
  `tables.ex` (the EchoStore tier) · `view.ex` (the privacy-safe views).
- [`codemojex.design.md`](../../codemojex.design.md) §Identity: the branded component law /
  §Privacy and fairness.
- [`stories/privacy.stories.md`](../../stories/privacy.stories.md).

## Doors

[/bcs](/bcs) — the id contract in full · [`C0`](course.0.md) ← · → [`C2`](course.2.md).
