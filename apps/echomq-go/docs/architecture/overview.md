# echomq-go Pattern Library — Architecture Overview

> Reader-local integration overview. Scoped for someone reading echomq-go docs directly; NOT the FTR-019-author-side view. For authoring ADRs + wave planning + scaffold structure, see [FTR-019 architecture/overview.md](../../../dev/mcp/features/FTR-019-echomq-pattern-library/architecture/overview.md).

---

## 1. Reader context

If reading this document from inside `apps/echomq-go/docs/`, three things are true:

1. **echomq-go is a BullMQ-protocol Go library.** Version pin: v5.62.0, commit `6a31e0aeab1311d7d089811ede7e11a98b6dd408`. See [`../../CLAUDE.md`](../../CLAUDE.md) for protocol compliance rules (wire-compat with Node.js BullMQ; Lua scripts are authoritative; job hash fields like `returnvalue` are lowercase; Redis key format `bull:queuename:*` or `bull:{queuename}:*` in cluster mode).
2. **This pattern library is docs-only.** Nine canonical Redis patterns, each a standalone markdown under [`../patterns/`](../patterns/). No code changes to `pkg/echomq/*.go` originate here.
3. **The library's ambition is naming, not inventing.** Every pattern cites the [mercury-design corpus](/Users/jonny/dev/mercury-design/redis-patterns/llms.txt) (29-pattern reference) for the primitive definition, and cites existing `pkg/echomq/*.go` or FTR-009 architecture docs for the in-repo use.

---

## 2. Why a pattern library exists in `apps/echomq-go/docs/`

EchoMQ-go is the shared substrate. Four downstream systems depend on it:

| Consumer | Primary pattern(s) consumed | Where documented |
|----------|----------------------------|------------------|
| **FTR-009 cclin-human-bridge** (Rose Tree mailbox + TUI + lifecycle) | streams-consumer-groups, streams-event-sourcing, session-management, atomic-updates, delayed-queue, reliable-queue | [`../../../dev/mcp/features/FTR-009-cclin-human-bridge/architecture/*.md`](../../../dev/mcp/features/FTR-009-cclin-human-bridge/architecture/mailbox-keyspace.md) |
| **FTR-008 pubsub-bridge** (`SendMessageBridge` producer on shared topic) | streams-event-sourcing, reliable-queue | [`../../../dev/mcp/features/FTR-008-cclin-echomq-pubsub/`](../../../dev/mcp/features/FTR-008-cclin-echomq-pubsub/) (W0 pending) |
| **FTR-007 mcp-shim** (MCP tool consumer) | streams-consumer-groups (as consumer) | [`../../../dev/mcp/features/FTR-007-mcp-shim/`](../../../dev/mcp/features/FTR-007-mcp-shim/) |
| **Future FTRs** (FTR-014 multi-team isolation, FTR-016 cluster-safe event store, FTR-018 web dashboard) | hash-tag-colocation, keyspace-notifications, pubsub-fanout | Forward-pointers only at W0 |

Each consumer independently selected these Redis mechanisms. The pattern library writes down the shared taxonomy so future authors cite a canonical name (e.g., "streams-consumer-groups") instead of re-deriving the mechanism from first principles.

---

## 3. Navigation map

```
apps/echomq-go/docs/
├── README.md                                      (reader index stub)
├── llms.yaml                                      (reader-local navigation)
├── architecture/
│   ├── overview.md                                (this file — integration narrative)
│   └── adr-001-pattern-taxonomy.md                (9×4 decision matrix + D-N log)
└── patterns/                                      (W1 Iter-1 deliverables — 9 files)
    ├── streams-consumer-groups.md                 (axis A — supervisor/worker messaging)
    ├── streams-event-sourcing.md                  (axis A)
    ├── pubsub-fanout.md                           (axis C — TUI live-update broadcasting)
    ├── keyspace-notifications.md                  (axis B — human-in-loop signalling)
    ├── reliable-queue.md                          (axis A)
    ├── session-management.md                      (axis D — session-state persist/restore)
    ├── hash-tag-colocation.md                     (axis A+B+D — cluster-mode substrate)
    ├── atomic-updates.md                          (axis A+D — state-machine transitions)
    └── delayed-queue.md                           (axis A)
```

Use-case axes from [`adr-001-pattern-taxonomy.md`](adr-001-pattern-taxonomy.md):

- **A** — supervisor / worker messaging (durable fanout + ACK + recovery)
- **B** — human-in-loop (mailbox / inbox with durable delivery)
- **C** — TUI live-update broadcasting (in-process dispatcher; not cross-process)
- **D** — session-state persist / restore (lifecycle meta + checkpoint)

---

## 4. Echomq-go code anchor cheat-sheet

Quick reference for the code files pattern docs cite most often:

| Code file | Line range | Pattern(s) it anchors |
|-----------|------------|-----------------------|
| [`../../pkg/echomq/keys.go`](../../pkg/echomq/keys.go) | 23-47 (hash-tag auto-detect) | hash-tag-colocation |
| [`../../pkg/echomq/keys.go`](../../pkg/echomq/keys.go) | 42-95 (per-state keys) | streams-consumer-groups, reliable-queue, delayed-queue |
| [`../../pkg/echomq/events.go`](../../pkg/echomq/events.go) | 64-91 (XADD + MAXLEN event emission) | streams-event-sourcing, streams-consumer-groups |
| [`../../pkg/echomq/scripts/scripts.go`](../../pkg/echomq/scripts/scripts.go) | any Lua script (MoveToActive, MoveToFinished, RetryJob, ExtendLock) | atomic-updates |
| [`../../pkg/echomq/heartbeat.go`](../../pkg/echomq/heartbeat.go) | whole file | session-management (lock-refresh analogy) |
| [`../../pkg/echomq/stalled.go`](../../pkg/echomq/stalled.go) | whole file | reliable-queue (stalled-detection as XAUTOCLAIM substitute) |
| [`../../pkg/echomq/worker_impl.go`](../../pkg/echomq/worker_impl.go) | 76-120 (pickupJob) | reliable-queue, atomic-updates |

---

## 5. How the library integrates with FTR-009

FTR-009 is the primary consumer. Its architecture has already chosen Redis mechanisms (fixed contract at W0 close); this library describes those choices instead of redesigning them.

**Fixed FTR-009 contracts** (drift from these is a grading penalty):

- **Keyspace:** `cclin:mbox:<team>:<agent>:{stream,meta,heartbeat}` — per [`mailbox-keyspace.md §2`](../../../dev/mcp/features/FTR-009-cclin-human-bridge/architecture/mailbox-keyspace.md). `streams-consumer-groups` pattern doc explains the XREADGROUP + PEL + XACK behaviour on this keyspace.
- **Consumer group:** one per mailbox stream; name = `<stream-key>:grp`. Consumer name = `<pid>-<boot_ns>`.
- **MAXLEN:** `~ 5000` approximate trim-on-write per `spec.yaml INV-7`. `streams-event-sourcing` pattern doc explains the MAXLEN ~ approximate trimming vs exact.
- **XAUTOCLAIM:** entries idle > 5 min claimable. `reliable-queue` pattern doc explains XAUTOCLAIM as the Streams successor to LMOVE.
- **Iteration events:** 13-field canonical envelope with `kind="iteration_event"` at the outer bridgeEnvelope level. `streams-event-sourcing` pattern doc explains the event-sourcing projection surface.
- **Lifecycle state machine:** 6 states + 12 transitions, `meta.state` as the source of truth. `session-management` + `atomic-updates` pattern docs explain the Hash + ordered-write pattern.
- **TUI dispatcher:** Go-channel-to-tea.Program.Send bridge, NOT Redis pubsub. `pubsub-fanout` pattern doc explains the distinction.
- **Hash-tag for cluster H3:** `cclin:mbox:{<team>}:<agent>:stream` brace-wrapped variant. `hash-tag-colocation` pattern doc explains the placement rule.
- **Staleness:** L1 30m → L2 2h → reap 6h ladder with MCP_STALE_REAP=manual default. `delayed-queue` pattern doc explains the L2 escalation debounce ZSET.

---

## 6. What lands here in future waves

W0 (this document): 4 seed files — `README.md`, `llms.yaml`, `architecture/overview.md` (this file), `architecture/adr-001-pattern-taxonomy.md`. No pattern docs yet.

W1 Iter-1 (Mars): 9 pattern documents at `patterns/*.md` following the 7-section template. Every Redis command citation anchored to mercury-design. Every pattern anchored to either current echomq-go code OR an FTR-009 forward-reference.

W1 Iter-2 (Mars): Remediation + prose polish + expanded `README.md` ToC with 1-paragraph pattern summaries.

W2 (Apollo): Cross-FTR backlink sync — `## Pattern-library references` blocks appended to FTR-007 / FTR-008 / FTR-009 `architecture/*.md` files. Atomic single-pass; no content changes in peer FTRs beyond the backlink block.

---

## 7. Scope fences

- **`pkg/echomq/**/*.go`** — wire-compat fence. Zero edits from this library across W0..W2.
- **Peer FTR dev trees** (FTR-007 / FTR-008 / FTR-009) — scope-fenced against FTR-019 edits except W2 Apollo backlink sync.
- **mercury-design corpus** — read-only reference.

---

## 8. Cross-reference index

| Target | File | Purpose |
|--------|------|---------|
| This library README | [`../README.md`](../README.md) | 9-pattern inventory + 7-section template |
| ILLM-v3 navigation | [`../llms.yaml`](../llms.yaml) | Agent-oriented navigation index |
| 9×4 decision matrix | [`adr-001-pattern-taxonomy.md`](adr-001-pattern-taxonomy.md) | Explicit pattern × use-case-axis table + D-1..D-N decision log |
| FTR-019 authoring overview | [`../../../dev/mcp/features/FTR-019-echomq-pattern-library/architecture/overview.md`](../../../dev/mcp/features/FTR-019-echomq-pattern-library/architecture/overview.md) | ADR-001..010 + Rose Tree ↔ echomq integration map |
| FTR-019 spec | [`../../../dev/mcp/features/FTR-019-echomq-pattern-library/spec.yaml`](../../../dev/mcp/features/FTR-019-echomq-pattern-library/spec.yaml) | R-1..R-10 + INV-1..7 |
| echomq-go BullMQ rules | [`../../CLAUDE.md`](../../CLAUDE.md) | Protocol compliance + v5.62.0 pin |
| FTR-009 mailbox-keyspace | [`../../../dev/mcp/features/FTR-009-cclin-human-bridge/architecture/mailbox-keyspace.md`](../../../dev/mcp/features/FTR-009-cclin-human-bridge/architecture/mailbox-keyspace.md) | Substrate anchor for patterns 1, 2, 5, 7 |
| FTR-009 iteration-events | [`../../../dev/mcp/features/FTR-009-cclin-human-bridge/architecture/iteration-events.md`](../../../dev/mcp/features/FTR-009-cclin-human-bridge/architecture/iteration-events.md) | Substrate anchor for pattern 2 |
| FTR-009 teammate-lifecycle | [`../../../dev/mcp/features/FTR-009-cclin-human-bridge/architecture/teammate-lifecycle.md`](../../../dev/mcp/features/FTR-009-cclin-human-bridge/architecture/teammate-lifecycle.md) | Substrate anchor for patterns 6, 8 |
| FTR-009 tui-panels | [`../../../dev/mcp/features/FTR-009-cclin-human-bridge/architecture/tui-panels.md`](../../../dev/mcp/features/FTR-009-cclin-human-bridge/architecture/tui-panels.md) | Substrate anchor for pattern 3 |
| FTR-009 reader-loop | [`../../../dev/mcp/features/FTR-009-cclin-human-bridge/architecture/reader-loop.md`](../../../dev/mcp/features/FTR-009-cclin-human-bridge/architecture/reader-loop.md) | Substrate anchor for patterns 1, 5 |
| FTR-009 staleness-policy | [`../../../dev/mcp/features/FTR-009-cclin-human-bridge/architecture/staleness-policy.md`](../../../dev/mcp/features/FTR-009-cclin-human-bridge/architecture/staleness-policy.md) | Substrate anchor for patterns 4, 9 |
| Mercury-design manifest | [`/Users/jonny/dev/mercury-design/redis-patterns/llms.txt`](/Users/jonny/dev/mercury-design/redis-patterns/llms.txt) | 29-pattern reference corpus |
