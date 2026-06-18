# EMQ · EchoMQ 2.x — The Line Specification

<show-structure depth="2"/>

Status: **ACTIVE — the BCS-side specification of the line in active development.** The binding design canon and the
ratified program live with the production tree (the Operator's `emq.design.md` and program roadmap, 2026-06-12 frame);
this file is their specification mirror inside the BCS documentation set — it defines the 2.x line's laws and
surfaces for every document here that stands on them, and it never redesigns what the canon owns. The delivery view
is the single consolidated [`emq.roadmap.md`](../emq.roadmap.md); the next major is specified in [`emq3.specs.md`](emq.3.specs.md).

## What the 2.x line is

EchoMQ 2.x is the Valkey-native bus that the Branded Component System re-derived from first principles and shipped as
measured, rung-gated code — born braced, born branded, born declared — converging in one production app
(`echo/apps/echo_mq`) above an extracted wire layer (`echo/apps/echo_wire`), beside the store
(`echo/apps/echo_store`) and the canon (`echo/apps/echo_data`).

## The laws (binding, carried whole from the canon)

**The key universe is grammar-total.** Every key the bus touches is braced `emq:{q}:` with the first-byte-disjoint
`{emq}:` reserve; the branded `job:` position is gated at the key builder — a `JOB` id or a typed refusal, never
interpolation. Every Lua key is declared in `KEYS[]` or grammar-derived; an operand key built from an `ARGV` prefix
inside a script body — the v1 flaw that forced the fork — is structurally impossible here.

**The version record fences the wire.** `{emq}:version` (`echomq:2.0.0`) is monotone behind the five-code fence;
additive registration is a protocol minor; a wire break or computed-floor raise is a major. Claims are phrased
against Valkey, current stable line, and enforced as gates with truthful-row reporting.

**The operational laws.** Server-clock time wherever leases are touched; at-least-once stays at-least-once with
idempotent handlers; one Lua script per transition, atomic on the truth row; opt-in families; every process a
supervised or caller-started child with stated restart semantics over a pure decision core.

## The as-built surface (Movement 0, landed and re-proven)

The wire: `EchoMQ.{RESP, Connector, Script}` frozen-named under the `EchoWire` facade — dependency-free, refereed
on its own traffic ([`bcsH.md`](../../echo/bcs/content/bcsH.md)), with reconnect/backoff, unix transport, no-reply and transaction
pipelines, and telemetry spans. The bus: the six `EchoMQ.*` modules over it — the three-field row, the four sets,
attempts-as-token `EMQSTALE`, completion-deletes, server-clock reap, REV BYLEX browse — with `EchoMQ.Jobs`,
`EchoMQ.Lanes` (fair per-group rotation: pause, resume, limit, depth — Chapter 3.4's record), and
`EchoMQ.Consumer`. The store: `EchoStore.{Table, Coherence, Ring, Journal}` — Chapters 4.1–4.5 are the records;
durable replication is the `EchoStore.Graft` engine streamed to Tigris (the `EchoStore.Shadow` behaviour is retired,
`store.design.md` §2). The canon:
`EchoData.*` with branded Snowflake ids as sequence, key, sort, claim, and cache key in one paid form (Appendix F).

## The capability families (Movements I–II, specified, shipping by rung)

Movement I pushes the v1 capability surface to state of the art inside `echo_mq`: **the scheduler and retry
vocabulary** (scheduled/repeatable jobs as a visibility fence on the schedule set; attempts-with-backoff; the
poison-job drill; connector auto-resubscribe) — ratified first, with codemoji's work surface as the
worked consumer; **the v1→v2 migration path** re-proven against `echo_mq` (drain-and-switch, order-preserving
branding of numeric ids, typed refusal of unmigratable ones, the v1 terminal fence-only patch); and **the
parent/flow family**, design-first. Movement II adds the pattern depth a multi-tenant bus needs: **groups
deepened** (control plane, group-aware recovery, park-don't-poll metronome, weighted/deficit rotation), **batches**
(bulk consumption, `min_size`/`timeout` shaping, affinity, the partitioned finish), **lifecycle controls** (TTL per
worker/name, distributed cancel, checkpoints), **the cache deepened** (BCAST tracking, absorbed-fills compaction,
`synchronous=FULL` per group, the invalidation-transport evaluation), and **the proof stack** (conformance,
telemetry contract, the engine matrix, the benchmark gate with the rival's strengths recorded beside).

Nothing in this list invents a surface: every family traces to the canon's sections or the drop's roadmap rows, and
each ships as one rung under the program's loop, designed under the v2 laws.

## Consumers, recorded

codemoji ([`echo/apps/codemoji`](../../../echo/apps/codemoji)) is the worked consumer of the line — a
six-emoji code-breaking game whose guesses ride per-player `EchoMQ.Lanes` as branded `JOB` work, drained by
two `EchoMQ.Consumer` instances (a single scoring authority, then prize settlement on a second queue), with
its leaderboard and first-mover races held in Valkey and its lifecycle published through `EchoMQ.Events`.
Forward, echo_bot ([`echo/apps/echo_bot`](../../../echo/apps/echo_bot)) is the headline-planned consumer:
Telegram-bot notifications at scale through the bus (today a direct synchronous `sendMessage` at
`EchoBot.Platform.Telegram.send_reply/3`, with no bus coupling yet). The 3.x stream tier
([`emq3.specs.md`](emq.3.specs.md)) stands on this line's wire and the store's durable `Graft` engine. The courses teach from the rungs'
specifications and re-ground when rungs ship — the course teaches, the rungs ship.

## Seams (owned by the program, mirrored here)

The in-place v2→v2 migration treatment (settled with the Operator before any such build); `apps/echomq` dissolution
timing; the carried family knobs (limiter window mode, batch contract, eviction beyond TTL, scheduler dogfooding of
EchoStore, cross-runtime adoption order, benchmark numbers, `{emq}:queues` with its coherence probe, `{emq}:locks`
reserved-by-name); and the unslotted proposals held at the program's seam — the transport rung (unix and TLS priced
against committed loopback rows), FLAME ephemeral consumers (the journal-beside-consumer pattern makes a consumer
disposable), the Go conformance harness and ports, and the MCP surface over bus, cache, and journal.

## Map

Delivery: the single consolidated [`emq.roadmap.md`](../emq.roadmap.md). The next major:
[`emq3.specs.md`](emq.3.specs.md) · [`emq.roadmap.md` §EchoMQ 3.x](../emq.roadmap.md). The records this line carries: [`bcs.toc.md`](../../echo/bcs/bcs.toc.md) — the lanes, the
cache and its shadow, the wire referee ([`bcsH.md`](../../echo/bcs/content/bcsH.md)) and its forward rungs
([`bcsH.specs.md`](../../echo/bcs/content/bcsH.specs.md)). The worked consumer: [`echo/apps/codemoji`](../../../echo/apps/codemoji).
