# EchoMQ Pattern Library

> Reader-local entry point for the echomq-go pattern library. Nine canonical Redis patterns naming the substrate primitives carrying Rose Tree + FTR-009 + FTR-008 + FTR-007 in production.

**Status:** W1 Iter-2 (Mars production polish). W0 seed (Venus-authored: scaffold + 9 pattern documents) shipped at parent `1198bd7`; W1 Iter-1 verified R-1..R-7 acceptance — Mars-019 found zero gaps; commit limited to scaffold-staleness polish at parent `14f3d68` (Apollo-019-I1 PASS 97/100 at `d9cb5bd2`).

**Scope:** docs-only. Zero Go-code edits to `apps/echomq-go/**/*.go`. See `architecture/overview.md` for the reader-local integration narrative; see [FTR-019 architecture/overview.md](../../dev/mcp/features/FTR-019-echomq-pattern-library/architecture/overview.md) for the authoring-side ADRs.

---

## Purpose

EchoMQ-go ships a mature BullMQ v5.62.0 Go implementation of Redis-backed job queues. Its internals encode several canonical patterns — hash-tag co-location, atomic Lua-scripted state transitions, XADD+MAXLEN event emission, heartbeat + stalled detection — that are independently re-used by the CCLIN Rose Tree mailbox substrate in FTR-009. This pattern library names those patterns so future Rose Tree work cites a canonical vocabulary instead of re-discovering.

**Read-me-first:** [`architecture/overview.md`](architecture/overview.md) — integration narrative for someone reading echomq-go docs directly (not an FTR-019 author).

---

## Pattern inventory (9 files — populated)

Each pattern follows the 7-section template (Title+Summary / Primitive / Rose Tree+FTR-009 Application / echomq-go code anchor / Antipatterns avoided / Cross-references / Worked example) per FTR-019 `spec.yaml INV-doc-structure`.

| # | Pattern | File | Primary use-case axis |
|---|---------|------|-----------------------|
| 1 | streams-consumer-groups | [`patterns/streams-consumer-groups.md`](patterns/streams-consumer-groups.md) | A — supervisor/worker messaging |
| 2 | streams-event-sourcing | [`patterns/streams-event-sourcing.md`](patterns/streams-event-sourcing.md) | A — supervisor/worker messaging |
| 3 | pubsub-fanout | [`patterns/pubsub-fanout.md`](patterns/pubsub-fanout.md) | C — TUI live-update broadcasting |
| 4 | keyspace-notifications | [`patterns/keyspace-notifications.md`](patterns/keyspace-notifications.md) | B — human-in-loop signalling |
| 5 | reliable-queue | [`patterns/reliable-queue.md`](patterns/reliable-queue.md) | A — supervisor/worker messaging |
| 6 | session-management | [`patterns/session-management.md`](patterns/session-management.md) | D — session-state persist/restore |
| 7 | hash-tag-colocation | [`patterns/hash-tag-colocation.md`](patterns/hash-tag-colocation.md) | A+B+D — cluster-mode substrate |
| 8 | atomic-updates | [`patterns/atomic-updates.md`](patterns/atomic-updates.md) | A+D — state-machine transitions |
| 9 | delayed-queue | [`patterns/delayed-queue.md`](patterns/delayed-queue.md) | A — supervisor debounce / reschedule |

Axes defined in [`architecture/adr-001-pattern-taxonomy.md`](architecture/adr-001-pattern-taxonomy.md) (9×4 decision matrix).

### Per-pattern summaries

- **streams-consumer-groups** — `XREADGROUP` + Pending Entries List + `XACK` + `XAUTOCLAIM` substrate for per-mailbox durable delivery with crash recovery; FTR-009 mailbox reader-loop + iteration-event consumer-groups consume this. See [`patterns/streams-consumer-groups.md`](patterns/streams-consumer-groups.md).
- **streams-event-sourcing** — `XADD` + `MAXLEN ~ N` append-only log with `XRANGE`/`XREAD` projections; immutable audit trail substrate for FTR-009 13-field iteration-event envelope and BullMQ job-lifecycle events. See [`patterns/streams-event-sourcing.md`](patterns/streams-event-sourcing.md).
- **pubsub-fanout** — `PUBLISH`/`SUBSCRIBE` fire-and-forget broadcast; documents the in-process Go-channel dispatcher bridge variant FTR-009 TUI uses (NOT Redis pubsub) and explicitly contrasts when each variant is appropriate. See [`patterns/pubsub-fanout.md`](patterns/pubsub-fanout.md).
- **keyspace-notifications** — `notify-keyspace-events` + `__keyevent@<db>__:*` reactive substrate; FTR-009 explicitly rejects this pattern in favor of polling + age-meta because expiry is binary while the L1/L2/reap ladder needs continuous age. See [`patterns/keyspace-notifications.md`](patterns/keyspace-notifications.md).
- **reliable-queue** — `LMOVE` legacy variant + Streams-based successor (`XREADGROUP` + `XAUTOCLAIM`); at-least-once delivery substrate; FTR-009 adopts the Streams successor; echomq-go ships a hybrid List-based variant with lock-token ownership. See [`patterns/reliable-queue.md`](patterns/reliable-queue.md).
- **session-management** — Hash-based identity + sliding-TTL heartbeat + multi-principal roster + invalidation broadcast; FTR-009 teammate-lifecycle 6-state machine + heartbeat 15s refresh apply this shape to agent presence. See [`patterns/session-management.md`](patterns/session-management.md).
- **hash-tag-colocation** — `bull:{queue}:*` + `cclin:mbox:{team}:*` cluster-slot co-location; sole mechanism enabling multi-key Lua + `MULTI`/`EXEC` in cluster mode; echomq-go auto-detects cluster client and pre-wires hash tags. See [`patterns/hash-tag-colocation.md`](patterns/hash-tag-colocation.md).
- **atomic-updates** — Five variants (`WATCH`/`MULTI`/`EXEC`, Lua scripts, `RENAME` shadow-key swap, idempotency-key gating, ordered-writes-for-crash-safety); echomq-go uses Lua + lock-CAS; FTR-009 retirement uses ordered-writes. See [`patterns/atomic-updates.md`](patterns/atomic-updates.md).
- **delayed-queue** — `ZADD` timestamp-score ZSET + `ZRANGEBYSCORE`/`ZREM` atomic claim; FTR-009 staleness L2 escalation debounce + echomq-go BullMQ delayed-job promotion via `MoveToActive` Lua. See [`patterns/delayed-queue.md`](patterns/delayed-queue.md).

---

## Navigation

- **`llms.yaml`** — ILLM-v3 agent-oriented navigation index. Consumed by `llms_parse` + `llms_expand`.
- **`architecture/overview.md`** — reader-local integration overview.
- **`architecture/adr-001-pattern-taxonomy.md`** — explicit 9×4 pattern × use-case-axis decision matrix + D-1..D-N decision log.
- **`patterns/*.md`** — 9 canonical pattern documents (populated; W1 Iter-1 verify+polish phase).

---

## Per-pattern 7-section template

Every pattern doc MUST carry these 7 sections in this order (enforced by FTR-019 `spec.yaml INV-doc-structure`):

1. `# <Pattern name>` + opening summary paragraph
2. `## Primitive` — Redis command surface + mercury-design citation
3. `## Rose Tree + FTR-009 Application` — how CCLIN stack consumes the primitive
4. `## echomq-go code anchor` — `file:line` in `apps/echomq-go/pkg/echomq/*.go` OR `FORWARD-REF: FTR-NNN`
5. `## Antipatterns avoided` — ≥2 concrete antipatterns with explanation
6. `## Cross-references` — FTR-NNN consumer backlinks + sibling-pattern links
7. `## Worked example` — concrete code snippet OR keyspace+command transcript

---

## Upstream references

- **BullMQ protocol** — v5.62.0 pinned, commit `6a31e0aeab1311d7d089811ede7e11a98b6dd408`. See [`../CLAUDE.md`](../CLAUDE.md).
- **Mercury-design corpus** — `/Users/jonny/dev/mercury-design/redis-patterns/` — 29-pattern reference library this work cites.
- **FTR-009 architecture** — `../../dev/mcp/features/FTR-009-cclin-human-bridge/architecture/*.md` — mailbox-keyspace, iteration-events, teammate-lifecycle, tui-panels, reader-loop, staleness-policy.
- **FTR-019 authoring tree** — `../../dev/mcp/features/FTR-019-echomq-pattern-library/` — scaffold, spec, plan, state, blockers, architecture/overview.md.
