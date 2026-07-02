# Codemojex course · C8 — Production Deployment

> **Route** `/codemojex/production` · **stub shipped** — this manuscript is the chapter brief; the C8
> authoring rung deepens both. An **extension chapter**: B7.6.3 ("Production on Fly") promoted to a
> full chapter over the design's production canon.
> **Sources** design §Fault tolerance and correctness / §Production deployment / §The pragmatic
> Valkey node / §Configuration.

The game ships as one supervised release beside one small, sharply-sized Valkey machine. The chapter
teaches production the way the design records it: a dependency-ordered supervision tree where
delivery is at-least-once and every handler is idempotent; a pinned release image; and a
single-thread datastore sized for a steady latency tail, private on the 6PN, with an upgrade ladder
that moves only on evidence.

## C8.1 · The release

`mix release codemojex`, built from the umbrella root in the pinned Elixir 1.18.4 / OTP 28 image: the
multi-stage Dockerfile compiles the app over `echo_mq` · `echo_data` · `echo_wire` · `echo_store`,
builds the native branded-id codec and the SQLite C-NIF, and assembles a self-contained release
(`echo_bot` and `echo_graft` stay out). A health check at `/api/health` takes a silent machine out of
rotation; the endpoint stays up across a rolling deploy so a live channel is not dropped under a
player. Dive route: `/codemojex/production/the-release` (planned).

## C8.2 · The pragmatic Valkey node

Valkey runs commands on one thread, so the machine is sized for the latency tail: **Valkey 9.1** on a
Fly `shared-cpu-2x`, one gigabyte, eviction off. `io-threads` stays at 1; `maxmemory` is a loud
512-megabyte guardrail under `noeviction`; durability is AOF alone (`everysec`, one fork source);
the node answers only on the org's 6PN at `codemojex-valkey.internal:6390`. The upgrade ladder, each
step on evidence: a replica in region → split web/worker process groups → a performance machine for
Phoenix → hash-tag sharding only when the one command thread is finally the bottleneck. Dive route:
`/codemojex/production/the-pragmatic-valkey-node` (planned).

## C8.3 · Fault tolerance and correctness

One `one_for_one` tree in dependency order — Repo, PubSub, the Bus, the `rest_for_one` cache tier
(Directory before its Tables), the rate limiter, the bot gateway, the four consumers, the CHAMP
leaderboard projection, the optional Graft committer, the Endpoint. Delivery is at-least-once and
harmless: scoring is pure, settlement is guarded by the one-shot `SET NX`, the sealed pass re-runs
identically, the wallet is a CHECK-backed transaction; each consumer leases its job so a crash makes
the work visible again rather than lost; cache writes are best-effort and can never fail the writer.
Dive route: `/codemojex/production/fault-tolerance-and-correctness` (planned).

## Grounding

- `echo/apps/codemojex/lib/codemojex/application.ex` (the supervision tree, quoted in design
  §Fault tolerance and correctness).
- [`codemojex.design.md`](../../codemojex.design.md) §Fault tolerance and correctness /
  §Production deployment / §The pragmatic Valkey node / §Configuration.

## Doors

[/mesh](/mesh) — the CAP weave over the same substrate · [/echomq](/echomq) — the bus's leases ·
[`C7`](course.7.md) ← · the course home, [`/codemojex`](course.landing.md).
