# ADR-001 — Pattern Taxonomy (9 × 4 Decision Matrix)

> **Status:** ACCEPTED (W0) · Horizon H1-H3
> **Owned by:** Venus (this document) · Mars (W1 Iter-1 pattern-doc author)
> **Cross-refs:** [`../../../dev/mcp/features/FTR-019-echomq-pattern-library/architecture/overview.md`](../../../dev/mcp/features/FTR-019-echomq-pattern-library/architecture/overview.md) (authoring-side ADRs), [`overview.md`](overview.md) (reader-local navigation), [`../README.md`](../README.md) (pattern inventory)

---

## 1. Context

FTR-019 selects 9 canonical Redis patterns from mercury-design's 29-pattern corpus to ship as the echomq-go pattern library. Selection criteria:

1. **Carries a concrete Rose Tree / FTR-009 concern** (the primitive is in use today OR forward-pointed to an H2/H3 FTR).
2. **Named in mercury-design** (no speculative or invented primitives).
3. **Non-redundant** (no two patterns cover the same mechanism).

This ADR records the selection + classifies each along four orthogonal use-case axes + logs the decision for each (D-1..D-10) with citations.

---

## 2. The four use-case axes

| Axis | Name | Description | Representative FTR-009 consumer |
|------|------|-------------|--------------------------------|
| **A** | supervisor / worker messaging | durable fanout with ACK tracking + crash recovery | mailbox stream per agent; reader-loop XREADGROUP |
| **B** | human-in-loop (mailbox/inbox) | durable delivery of messages addressed to a human-operator identity | TUI Inbox tab (direct messages); L0 inbox mirror for important/actionable |
| **C** | TUI live-update broadcasting | in-process dispatcher fanout from Redis event stream to TUI renderer | tui-panels.md §7 Go-chan → tea.Program.Send bridge |
| **D** | session-state persist / restore | durable state with TTL-based sliding expiration; multi-instance coordination | teammate-lifecycle.md meta Hash + heartbeat TTL |

Axis-orthogonality is intentional: most patterns PRIMARY one axis and SECONDARY one or two others. A pattern that primaries every axis is a red flag (likely too broad to document usefully).

---

## 3. The 9 × 4 decision matrix

Cells use classification tokens:
- **PRIMARY** — the pattern is the go-to choice for this axis; `## Rose Tree + FTR-009 Application` section in the pattern doc leads with this use.
- **SECONDARY** — the pattern contributes to this axis but is not the lead; cited as "also useful for ..." in the pattern doc.
- **N/A** — the pattern does not apply to this axis; the pattern doc omits mention.

| Pattern | Axis A (supervisor/worker) | Axis B (human-in-loop) | Axis C (TUI broadcast) | Axis D (session state) |
|---------|---------------------------|------------------------|------------------------|-----------------------|
| `streams-consumer-groups` | **PRIMARY** — XREADGROUP + PEL + XACK is the durable fanout backbone | SECONDARY — same primitive carries human-addressed mailbox messages | SECONDARY — TUI subscribes to mailbox stream via Go-chan bridge | N/A — state lives in Hash + TTL, not stream |
| `streams-event-sourcing` | **PRIMARY** — iteration-events audit trail | SECONDARY — important/actionable events mirror to operator inbox | SECONDARY — TUI Iterations tab projects from event stream | N/A — state is derived from events, not state IS events |
| `pubsub-fanout` | N/A — fire-and-forget unsuitable for supervisor messaging | N/A — fire-and-forget unsuitable for human inbox | **PRIMARY** — Go-chan variant (NOT Redis pubsub) carries TUI live updates | N/A — pubsub is stateless |
| `keyspace-notifications` | SECONDARY — reactive alternative to polling, rarely chosen | **PRIMARY** — TTL-expired reactivity for liveness signals (heartbeat) | SECONDARY — future cross-process TUI dashboards may consume | N/A — signals on state, does not persist state |
| `reliable-queue` | **PRIMARY** — at-least-once delivery with processing-list recovery | SECONDARY — human-addressed work items (e.g., draft-approval backlog in FTR-010) | N/A — queue semantics are not live-broadcast | N/A — queue is ephemeral, not session state |
| `session-management` | SECONDARY — workers' own lifecycle state (heartbeat + active TTL) | SECONDARY — operator identity tracking (multi-device session aspirations) | N/A — session state is polled, not broadcast | **PRIMARY** — Hash + sliding TTL + multi-entity roster Set |
| `hash-tag-colocation` | **PRIMARY** — cluster-mode atomic multi-key operations on per-team keyspace | **PRIMARY** — per-team mailbox co-location | SECONDARY — TUI keys typically don't need co-location | **PRIMARY** — per-entity session keys must co-locate for atomic ops |
| `atomic-updates` | **PRIMARY** — Lua scripts for state transitions (BullMQ MoveToActive); ordered-write for retirement | SECONDARY — inbox ACK + state flip must be atomic-ish | N/A — TUI is reader, not writer of this substrate | **PRIMARY** — session-state transitions (bootstrap→idle→active→retired) |
| `delayed-queue` | **PRIMARY** — debounced escalation (stale L2 ZSET); scheduled retries | SECONDARY — deferred operator notifications (future) | N/A — queue-based, not broadcast | N/A — queue is ephemeral, not session state |

**Distribution check:**
- Axis A primaries: 5 of 9 patterns (55%) — supervisor/worker messaging is the core domain; expected concentration.
- Axis B primaries: 2 of 9 (22%) — human-in-loop is a subset.
- Axis C primaries: 1 of 9 (11%) — TUI broadcast is a specialty; pubsub-fanout owns it.
- Axis D primaries: 3 of 9 (33%) — session state is cross-cutting; hash-tag-colocation, session-management, atomic-updates share.

No pattern primaries 4/4 axes (none is too-broad); no pattern is N/A on 4/4 (none is irrelevant). Distribution passes the orthogonality sanity-check.

---

## 4. D-N decision log

Each D-N records one decision — why this pattern was selected, how it maps to mercury-design, and which FTR-009 anchor validates its inclusion. Every decision cites at least one mercury-design source file AND at least one FTR-009 anchor (enforced by FTR-019 `spec.yaml R-8`).

---

### D-1 — Include `streams-consumer-groups`

**Decision:** Include as pattern #1 with PRIMARY axis A, SECONDARY axes B + C.

**Rationale:** Rose Tree mailbox substrate requires per-logical-consumer durable delivery with ACK tracking and crash-recovery. [`mercury-design fundamental/streams-consumer-patterns.md`](/Users/jonny/dev/mercury-design/redis-patterns/fundamental/streams-consumer-patterns.md.txt) enumerates the failure-mode checklist (two-phase startup reading PEL history with ID `0` then switching to `>`, janitor goroutine running XAUTOCLAIM, dedup via LRU cache, deadletter escalation at > 10 delivery attempts). [FTR-009 reader-loop.md §2-§4](../../../dev/mcp/features/FTR-009-cclin-human-bridge/architecture/reader-loop.md) adopts this shape directly — XREADGROUP BLOCK 5000 COUNT 32, XAUTOCLAIM idle 5min, deadletter at 10 attempts.

**Code anchor:** [`pkg/echomq/events.go:64-91`](../../pkg/echomq/events.go) (XADD MAXLEN producer side) + [`pkg/echomq/worker_impl.go:76-120`](../../pkg/echomq/worker_impl.go) (consumer pickup). [`pkg/echomq/scripts/scripts.go` MoveToActive](../../pkg/echomq/scripts/scripts.go) encodes BullMQ's consumer-group equivalent.

**Consequences:** Future FTRs citing `streams-consumer-groups` inherit the failure-mode checklist without re-deriving. Any new consumer-group use that skips the two-phase startup or the janitor is reviewable deviation.

---

### D-2 — Include `streams-event-sourcing`

**Decision:** Include as pattern #2 with PRIMARY axis A, SECONDARY axes B + C.

**Rationale:** [`mercury-design fundamental/streams-event-sourcing.md`](/Users/jonny/dev/mercury-design/redis-patterns/fundamental/streams-event-sourcing.md.txt) frames the pattern as append-only log + projections derive state. [FTR-009 iteration-events.md §2](../../../dev/mcp/features/FTR-009-cclin-human-bridge/architecture/iteration-events.md) directly implements this — 13-field canonical envelope (`team, kind, agent, archetype, iteration_id, phase, grade, grade_rubric, artifacts, trace_id, ts, notify_class, notify_text`) + `extensions` additive map + dedup via `extensions.event_id` UUID v4 ([`§8`](../../../dev/mcp/features/FTR-009-cclin-human-bridge/architecture/iteration-events.md)). Consumers (TUI Iterations tab, Pluto supervise cron, lifecycle router) are projections.

**Code anchor:** [`pkg/echomq/events.go:64-91`](../../pkg/echomq/events.go) (XADD + MAXLEN ~ approximate trim pattern — the same primitive that FTR-009 uses, just with BullMQ job-lifecycle semantics instead of iteration-event semantics).

**Consequences:** Rose Tree audit semantics are standardized. Future replay requirements (TUI-boot XRANGE most-recent-100 per [`iteration-events.md §6`](../../../dev/mcp/features/FTR-009-cclin-human-bridge/architecture/iteration-events.md)) cite the retention window (MAXLEN ~ 5000 = ~14h at 0.1 msg/s sustained) as canonical bound.

---

### D-3 — Include `pubsub-fanout`

**Decision:** Include as pattern #3 with PRIMARY axis C only; explicitly N/A on axes A + B + D.

**Rationale:** [`mercury-design community/pubsub.md`](/Users/jonny/dev/mercury-design/redis-patterns/community/pubsub.md.txt) is clear that Redis pubsub is fire-and-forget (no persistence, no delivery guarantee). [FTR-009 tui-panels.md §7](../../../dev/mcp/features/FTR-009-cclin-human-bridge/architecture/tui-panels.md) dispatches via Go-channel + `tea.Program.Send` — NOT Redis pubsub. The pattern doc must name BOTH variants (Redis PUBLISH/SUBSCRIBE AND Go-channel bridge) and make the distinction explicit: use Redis pubsub when publishers and subscribers are separate processes AND message loss is acceptable; use Go-channel bridge when both sides are in-process.

**Code anchor:** FORWARD-REF: FTR-009 (Go-channel dispatcher lands in W1-Iter-2 of FTR-009; current echomq-go code does not use cross-process pubsub).

**Consequences:** Pattern doc explicitly calls out the anti-pattern "use Redis pubsub for durable mailbox delivery". H2/H3 legitimate pubsub use cases (cache invalidation, session revocation, cross-process TUI-web broadcast in FTR-018) cite this pattern as the sanctioned surface.

---

### D-4 — Include `keyspace-notifications`

**Decision:** Include as pattern #4 with PRIMARY axis B, SECONDARY axes A + C. NOT-USED in CCLIN today (documented as trade-off).

**Rationale:** [`mercury-design commands/content/develop/pubsub/keyspace-notifications.md`](/Users/jonny/dev/mercury-design/redis-patterns/commands/content/develop/pubsub/keyspace-notifications.md.txt) lists every event type + configuration flag. [FTR-009 staleness-policy.md §3](../../../dev/mcp/features/FTR-009-cclin-human-bridge/architecture/staleness-policy.md) currently POLLS heartbeat-key age (2-minute supervise cron reading `meta.heartbeat_last_refresh_ms`) rather than subscribing to `__keyevent@0__:expired` — because CCLIN needs age-in-ms (continuous) not binary expired (discrete) + fire-and-forget pubsub loses events during reader reconnect. Documenting this as an explicit pattern with the trade-off rationale prevents future authors from reaching for it without considering the polling alternative.

**Code anchor:** FORWARD-REF: FTR-016 (Redis Cluster multi-node subscription fanout would need per-node design; not active today).

**Consequences:** Pattern doc carries a "when to use" + "when NOT to use" table. Future FTRs requiring sub-second TTL reactivity (rare in Rose Tree) have a named pattern to cite.

---

### D-5 — Include `reliable-queue`

**Decision:** Include as pattern #5 with PRIMARY axis A, SECONDARY axis B. NOT the Streams-era replacement — documents BOTH the LMOVE-based legacy pattern AND the XAUTOCLAIM-based Streams successor.

**Rationale:** [`mercury-design fundamental/reliable-queue.md`](/Users/jonny/dev/mercury-design/redis-patterns/fundamental/reliable-queue.md.txt) describes LMOVE-based at-least-once with a separate processing list + reaper cron. [FTR-009 reader-loop.md §4](../../../dev/mcp/features/FTR-009-cclin-human-bridge/architecture/reader-loop.md) achieves the same guarantee via XAUTOCLAIM (entries pending > 5 min re-claimed) + deadletter stream (> 10 delivery attempts). echomq-go achieves it via `stalled.go` (lock-expiry detection + LRem + LPush back to wait queue).

**Code anchor:** [`pkg/echomq/stalled.go`](../../pkg/echomq/stalled.go) whole file — BullMQ's stalled-detection is functionally equivalent to mercury-design's "monitor-process reaper" pattern. [`pkg/echomq/worker_impl.go:76-120`](../../pkg/echomq/worker_impl.go) pickupJob is the atomic dequeue analogue.

**Consequences:** Pattern doc explicitly flags "use streams-consumer-groups unless you specifically need List-only semantics". Prevents future authors from reaching for LMOVE when Streams is better.

---

### D-6 — Include `session-management`

**Decision:** Include as pattern #6 with PRIMARY axis D, SECONDARY axes A + B.

**Rationale:** [`mercury-design community/session-management.md`](/Users/jonny/dev/mercury-design/redis-patterns/community/session-management.md.txt) describes Hash-based session storage + sliding TTL expiration + multi-device tracking via Sets. [FTR-009 teammate-lifecycle.md §3](../../../dev/mcp/features/FTR-009-cclin-human-bridge/architecture/teammate-lifecycle.md) uses this directly — `cclin:mbox:<team>:<agent>:meta` Hash for state/archetype/heartbeat_last_refresh_ms, `cclin:team:<team>:roster` Hash for agent→role (analogue of the multi-device Set), `cclin:team:<team>:active` ZSET for last-activity. Heartbeat TTL refresh every 15s is the sliding-expiration shape.

**Code anchor:** [`pkg/echomq/heartbeat.go`](../../pkg/echomq/heartbeat.go) whole file — BullMQ's lock-heartbeat is a sliding-TTL pattern on the lock key; the session-management pattern is the same shape applied to session identity instead of job ownership.

**Consequences:** Future Rose Tree authors implementing new lifecycle-like substrates (e.g., FTR-010 draft-approval sessions) have a named pattern + canonical shape. Prevents re-inventing the Hash+TTL sliding-window pattern.

---

### D-7 — Include `hash-tag-colocation`

**Decision:** Include as pattern #7 with PRIMARY axes A + B + D, SECONDARY axis C. Highest axis-count pattern in the library — fundamentally cross-cutting for cluster-safe design.

**Rationale:** [`mercury-design fundamental/hash-tag-colocation.md`](/Users/jonny/dev/mercury-design/redis-patterns/fundamental/hash-tag-colocation.md.txt) gives the shape (`{entity-id}` hash-tag placement, first-tag-wins rule, cluster-mode atomic multi-key operations, hot-slot mitigation). echomq-go [`pkg/echomq/keys.go:23-47`](../../pkg/echomq/keys.go) is a canonical auto-detect implementation: `useHashTags` flag set via `IsRedisCluster(client)` type assertion, applied across every key builder (Wait, Active, Delayed, Events, Stalled, Lock, Job, Logs, PriorityCounter, RateLimiter, Paused, Marker, Metrics, Meta). [FTR-009 mailbox-keyspace.md §8.6](../../../dev/mcp/features/FTR-009-cclin-human-bridge/architecture/mailbox-keyspace.md) forward-points H3 cluster deployment with `cclin:mbox:{<team>}:<agent>:stream` brace-wrapped variant.

**Code anchor:** [`pkg/echomq/keys.go:23-47`](../../pkg/echomq/keys.go) (auto-detect constructor + explicit-override helper) + [`pkg/echomq/keys.go:42-197`](../../pkg/echomq/keys.go) (every Key*() method applies the conditional).

**Consequences:** Rose Tree cluster evolution (FTR-016) cites this pattern as the substrate. Future authors implementing cluster-safe Redis mechanisms have a canonical placement rule + auto-detect idiom.

---

### D-8 — Include `atomic-updates`

**Decision:** Include as pattern #8 with PRIMARY axes A + D, SECONDARY axis B. Covers the FULL spectrum: WATCH/MULTI/EXEC → Lua scripts → shadow-key+RENAME → idempotency keys → ordered-writes-for-crash-safety.

**Rationale:** [`mercury-design fundamental/atomic-updates.md`](/Users/jonny/dev/mercury-design/redis-patterns/fundamental/atomic-updates.md.txt) enumerates all 7 atomic-update patterns (optimistic locking via WATCH, Lua scripts, shadow-key+RENAME, idempotency keys, increment-with-bounds, GETSET/GETDEL/GETEX, LMOVE). echomq-go [`pkg/echomq/scripts/scripts.go`](../../pkg/echomq/scripts/scripts.go) encodes BullMQ's Lua scripts (MoveToActive, MoveToFinished, RetryJob, ExtendLock) for strict atomic state transitions. [FTR-009 teammate-lifecycle.md §6](../../../dev/mcp/features/FTR-009-cclin-human-bridge/architecture/teammate-lifecycle.md) describes a DIFFERENT atomicity shape — atomic-enough-via-ordering (not MULTI because cross-key DEL is too broad for transaction). Pattern doc must describe both points on the spectrum (Lua for strict atomic; ordered-writes for crash-safe).

**Code anchor:** [`pkg/echomq/scripts/scripts.go`](../../pkg/echomq/scripts/scripts.go) any Lua script — MoveToActive is the canonical example. [FTR-009 teammate-lifecycle.md §6](../../../dev/mcp/features/FTR-009-cclin-human-bridge/architecture/teammate-lifecycle.md) retirement sequence documents the ordered-write pattern.

**Consequences:** Rose Tree state-machine transitions (FTR-009 6-state lifecycle, future FTR-010 draft-approval state) have a named pattern + crash-safety idiom. Apollo Pillar-2 audits can cite this pattern when reviewing atomicity claims.

---

### D-9 — Include `delayed-queue`

**Decision:** Include as pattern #9 with PRIMARY axis A, N/A other axes.

**Rationale:** [`mercury-design fundamental/delayed-queue.md`](/Users/jonny/dev/mercury-design/redis-patterns/fundamental/delayed-queue.md.txt) gives the canonical shape: ZSET member = task-id, score = unix-timestamp-of-execution; ZRANGEBYSCORE polls; ZREM atomic-claims; retry-with-backoff via re-ZADD. echomq-go uses it for BullMQ delayed jobs ([`pkg/echomq/keys.go:58-63`](../../pkg/echomq/keys.go) Delayed key + [`pkg/echomq/scripts/scripts.go` moveToActive](../../pkg/echomq/scripts/scripts.go) promotes delayed → active when current time crosses ZSET score). [FTR-009 staleness-policy.md §5](../../../dev/mcp/features/FTR-009-cclin-human-bridge/architecture/staleness-policy.md) uses the shape for debounce — `cclin:stale:level2` ZSET with score = unix-ms of L2 crossing enables batch queries to find escalation candidates.

**Code anchor:** [`pkg/echomq/keys.go:58-63`](../../pkg/echomq/keys.go) Delayed key + [`pkg/echomq/scripts/scripts.go`](../../pkg/echomq/scripts/scripts.go) (moveToActive promotes delayed-to-active). [FTR-009 staleness-policy.md §5](../../../dev/mcp/features/FTR-009-cclin-human-bridge/architecture/staleness-policy.md) for the debounce application.

**Consequences:** Future Rose Tree FTRs needing time-based reschedule (retries, batched ops, cron-like triggers) have a named pattern. Prevents re-inventing the ZSET-by-unix-ms idiom.

---

### D-10 — Scope-fence posture (cross-cutting)

**Decision:** All 9 patterns ship docs-only. No `apps/echomq-go/**/*.go` edits across FTR-019 waves W0..W2. Peer FTR trees (FTR-007 / FTR-008 / FTR-009) scope-fenced against FTR-019 edits except W2 Apollo narrow-append backlink sync.

**Rationale:** Wire-compat preservation is paramount for echomq-go (BullMQ v5.62.0 pinned, commit `6a31e0aeab1311d7d089811ede7e11a98b6dd408`, Go ↔ Node.js cross-language compat per [`../../CLAUDE.md`](../../CLAUDE.md)). Peer-FTR work is in-flight (FTR-009 Venus Path-A ~70% uncommitted per README). Separation of concerns across FTR trees keeps review surfaces scoped to one team's gate discipline at a time.

**Code anchor:** N/A (scope-fence is about absence of anchors, not their content). `go build ./...` round-trip in `apps/echomq-go/` before and after every FTR-019 turn is the enforcement probe (Pluto continuous-tooling; [FTR-019 spec.yaml R-6](../../../dev/mcp/features/FTR-019-echomq-pattern-library/spec.yaml)).

**Consequences:** Apollo Pillar-1 gate shifts toward docs-quality heuristics (prose precision, 7-section completeness, cross-ref integrity, primitive-accuracy) for FTR-019. Go-code regression checks become scope-fence audit, not quality axis. W2 backlink sync is a narrow append, not a redesign.

---

## 5. Revisit triggers

Revisit this taxonomy if any of the following happens:

- **New pattern proposal** — a proposed 10th pattern requires a formal scope-expansion blocker per [FTR-019 spec.yaml INV-nine-patterns-fixed](../../../dev/mcp/features/FTR-019-echomq-pattern-library/spec.yaml) + Director directive.
- **Axis redefinition** — if multi-team (FTR-014) or multi-workspace (future) use cases reveal that 4 axes are insufficient, a 5th axis may be added in an ADR amendment. Current 4 axes cover H1-H2; H3 may require axes like "cross-workspace cache invalidation" or "federated event replay".
- **Mercury-design corpus update** — new reference patterns added to `/Users/jonny/dev/mercury-design/redis-patterns/` may surface better substrate choices; revisit individual D-N entries when mercury upgrades.
- **BullMQ protocol upgrade** — v6.x (or beyond v5.62.0) may change the atomic-update scripts; `atomic-updates` pattern doc must sync in a follow-up FTR (FTR-019-R2 scope expansion).
- **Cluster deployment (FTR-016)** — `hash-tag-colocation` gains cluster-specific sections (cross-slot consistency); `keyspace-notifications` gains multi-node fanout design.
- **Web dashboard (FTR-018)** — `pubsub-fanout` gains cross-process broadcast subsection; `streams-event-sourcing` gains long-term archive sink design.

---

## 6. Consequences

- Pattern-doc authors (Mars W1 Iter-1) have a fixed 7-section template + a pre-selected axis classification + a pre-validated mercury-design citation per pattern. Authoring work is populate-the-template, not design-the-pattern.
- Apollo graders (W0 and W1 gates) have a fixed rubric surface: grep for the 7 section headers, grep for mercury-design citations, grep for echomq-go code anchors, compare axis classifications against this matrix.
- Rose Tree future feature architects have a named taxonomy to cite. "Use streams-consumer-groups here" is a vocabulary-level statement, not a design-level one.
- Scope-fence posture is first-class (D-10), not buried. Wire-compat violations produce an auditable diff, not a silent drift.

---

## 7. Cross-references

| Target | File | Purpose |
|--------|------|---------|
| Reader-local navigation | [`overview.md`](overview.md) | Integration narrative for someone reading echomq-go docs directly |
| Reader-local README | [`../README.md`](../README.md) | 9-pattern inventory + ToC placeholder |
| Reader-local agent index | [`../llms.yaml`](../llms.yaml) | ILLM-v3 navigation for all 11 files |
| FTR-019 authoring overview | [`../../../dev/mcp/features/FTR-019-echomq-pattern-library/architecture/overview.md`](../../../dev/mcp/features/FTR-019-echomq-pattern-library/architecture/overview.md) | ADR-001..010 (this taxonomy is referenced as the 9×4 matrix surface) |
| FTR-019 spec | [`../../../dev/mcp/features/FTR-019-echomq-pattern-library/spec.yaml`](../../../dev/mcp/features/FTR-019-echomq-pattern-library/spec.yaml) | R-8 (9×4 matrix requirement); R-1..R-7 (per-pattern contracts) |
| echomq-go BullMQ rules | [`../../CLAUDE.md`](../../CLAUDE.md) | v5.62.0 pin + wire-compat + Lua scripts authoritative |
| Mercury-design manifest | [`/Users/jonny/dev/mercury-design/redis-patterns/llms.txt`](/Users/jonny/dev/mercury-design/redis-patterns/llms.txt) | 29-pattern reference corpus |
