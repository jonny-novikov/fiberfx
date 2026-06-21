---
title: "eg.5 — Low-latency write tier"
id: echo-graft-5-low-latency
rung: eg.5
size: M
risk: NORMAL+
status: Draft
stands-on: "eg.4"
---

# eg.5 — Low-latency write tier { id="echo-graft-5-low-latency" }

> _Put a local-fsync group-commit buffer in front of the object-storage commit, and let each call choose async (return on local fsync) or sync (await the durable, replicated remote commit)._

## Summary

Graft's remote commit is high-latency and low-cost; for hot paths, accept writes into a durable local buffer with one fsync per batch and roll the batch up into a remote commit. A per-call durability mode lets callers trade the loss window for latency explicitly.

## Rationale

Object-storage commits are slow by design, and Graft's own future-work calls for buffering writes in a lower-latency durable layer in front of object storage. That buffer is the platform's balance point across performance, durability, and CPU: a local fsync amortized over a batch gives low-latency durability and few syscalls, while the async rollup gives replication. Exposing the choice per call — async returns at local-fsync speed with the loss window bounded by the open batch; sync awaits the remote conditional-write commit — keeps the durability guarantee a declared decision rather than a hidden default.

## 5W + H { id="eg5-5wh" }

| | |
|---|---|
| **Who** | Platform; the mode is a request field used by EchoStore callers. |
| **What** | A bounded local-fsync write buffer with group commit, a per-call `:async`/`:sync` durability mode, and a pure shaping core (min_size OR timeout, injected clock). |
| **When** | After eg.4. |
| **Where** | Sidecar-side, in front of the eg.2 remote commit; the mode rides the eg.4 protocol. |
| **Why** | Low-latency durable writes and fewer fsyncs under load, without giving up replication or hiding the loss window. |
| **How** | Accept into the buffer; flush on min_size or timeout; one fsync per batch; roll up into one remote commit; ack per the chosen mode. |

## Scope { id="eg5-scope" }

### In scope

- A bounded, durable local buffer: accept → batch → one fsync per batch → one remote commit/rollup (eg.2).
- A pure shaping core: accumulate and flush when a batch reaches `min_size` or ages past `timeout`, with an injected clock (no real time in tests).
- A per-call durability mode: `:async` acks on local fsync (loss window = the open batch); `:sync` acks only after the remote conditional-write commit (durable + replicated before ack).
- Telemetry: batch size, flush latency, fsync count per Volume.
- Within-Volume order preserved: commit order equals accept order.

### Out of scope

- Cross-compile, CI, packaging (eg.6).
- Tuning policy automation (a controller is a later, separate concern).

## Specification { id="eg5-spec" }

Two tiers: a local durable buffer (disk fsync) feeding the eg.2 remote commit. The shaping core is pure and clock-injected so flush triggers are deterministic under test. `:async` returns once the batch is fsync'd locally; its loss window is exactly the records in the open (not-yet-remotely-committed) batch, and that bound is surfaced per Volume. `:sync` returns only after the remote conditional-write commit acks, so on return the write is durable and replicated. The buffer lives sidecar-side; the mode is a field on the eg.4 commit request. Order within a Volume is preserved across the batch.

## Acceptance criteria { id="eg5-acceptance" }

1. **Given** a stream of `:async` writes arriving faster than the remote commit, **when** they are accepted, **then** they ack at local-fsync latency and one remote commit rolls up the batch — the async throughput exceeds the per-call `:sync` rate, and both numbers are recorded.
2. **Given** a `:sync` write, **when** it acks, **then** the remote conditional-write commit has already succeeded (durable and replicated before ack).
3. **Given** the shaping core with an injected clock, **when** either `min_size` or `timeout` is reached first, **then** it flushes deterministically at that trigger, with no dependence on real time.
4. **Given** a crash after a local fsync but before the remote commit in `:async` mode, **when** the sidecar restarts, **then** at most the open batch is unaccounted, and all previously remotely-committed LSNs are intact and replicated.
5. **Given** writes to one Volume, **when** a batch flushes, **then** the committed order equals the accept order.
6. **Given** a Volume configured for `:async`, **when** queried, **then** its loss-window bound (the max open-batch size or age) is reported, not implicit.

## Dependencies & risks { id="eg5-risks" }

- **Depends on:** eg.4.
- **Risk — hidden loss window:** the async bound must be a declared, queryable per-Volume policy (criterion 6).
- **Risk — buffer medium:** the local buffer is bounded-loss until rollup; document that it is disk-fsync durability, not replicated, until the remote commit.
