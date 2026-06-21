---
title: "eg.6 — Ship: cross-compile, CI, shootout"
id: echo-graft-6-ship
rung: eg.6
size: M
risk: NORMAL
status: Draft
stands-on: "eg.1–eg.5"
---

# eg.6 — Ship: cross-compile, CI, shootout { id="echo-graft-6-ship" }

> _Turn the spine into a deployable, measured artifact across the two-box topology, with the durability shootout proving where the transactional+replicated tier lands beside Champ and Oban._

## Summary

Cross-compile the sidecar for the Mac orchestrator and the Windows RTX node, gate releases through CI (lint, the cross-runtime conformance suite, the determinism loop, and the shootout battery), and pin `echo_graft_proto` in lockstep across the BEAM release and the binary.

## Rationale

A spine that only runs on one developer machine is not shipped. The two-box topology (Mac orchestrator + Windows RTX compute) means the sidecar must build and run on both targets, and the cross-runtime contract means the BEAM release and the sidecar binary must carry the same protocol version or refuse to talk. The shootout battery is the proof obligation: an `echo_graft` row, single and batch durable-enqueue, annotated transactional + replicated, recorded next to Champ, Oban, Memory, and BullMQ so the new tier's position is measured, not asserted.

## 5W + H { id="eg6-5wh" }

| | |
|---|---|
| **Who** | Platform; operators run the deployed sidecar. |
| **What** | A cross-compiled, CI-gated release of the sidecar plus a pinned `echo_graft_proto`, and an `echo_graft` row in the shootout. |
| **When** | Last; stands on eg.1–eg.5. |
| **Where** | Build for Mac + Windows; deploy beside Go workers on EchoMQ; CI in the monorepo pipeline. |
| **Why** | Make the engine deployable and its durability tier measured, with no silent protocol skew between release units. |
| **How** | Cargo release profiles + cross-compilation; a CI matrix running lint/conformance/determinism/shootout; a lockstep protocol-version pin with refuse-on-mismatch. |

## Scope { id="eg6-scope" }

### In scope

- Cross-compile the sidecar for the Mac orchestrator and the Windows RTX node; stripped release binaries.
- A CI matrix: clippy/lint, build, the eg.4 cross-runtime conformance suite, the ≥100-iteration determinism loop, and the shootout battery.
- Lockstep versioning: the same `echo_graft_proto` version embedded in the BEAM release and the sidecar binary; connection refused on mismatch (eg.4).
- An operational runbook: start, health check, and feed-cursor recovery.
- The shootout integration: an `echo_graft` row with single + batch durable-enqueue jobs/s, durability annotated transactional + replicated.

### Out of scope

- Further performance passes (PGO/BOLT — a Graft future-work note; defer).
- The async-NIF hot-read optimization (separate spec).

## Specification { id="eg6-spec" }

Build matrix covers both targets, with early verification that the engine's dependency tree (Fjall, the async runtime, the object-storage client) builds on Windows. CI stages run in order: lint → build → conformance → determinism (≥100) → shootout, and the `echo_graft` result is recorded. Release units are pinned: the BEAM release and the sidecar binary embed the same `echo_graft_proto` version, and a version mismatch on connect is refused and logged (no silent skew). The runbook documents starting the sidecar as an EchoMQ participant, its health signal, and recovery via the feed cursor after a restart. The shootout adds `echo_graft` beside the existing engines, reporting single and batch durable-enqueue throughput with the durability column reading transactional + replicated.

## Acceptance criteria { id="eg6-acceptance" }

1. **Given** the release pipeline, **when** invoked, **then** it produces sidecar binaries for both targets, each embedding the same pinned `echo_graft_proto` version as the BEAM release.
2. **Given** CI, **when** it runs, **then** lint, the cross-runtime conformance suite, the ≥100-iteration determinism loop, and the shootout battery all pass, and the `echo_graft` row is recorded.
3. **Given** a BEAM release at a mismatched protocol version, **when** it connects to a deployed sidecar, **then** the connection is refused and the mismatch is logged.
4. **Given** the shootout battery, **when** run, **then** `echo_graft` reports single and batch durable-enqueue jobs/s with durability annotated transactional + replicated, beside Champ, Oban, Memory, and BullMQ.
5. **Given** a sidecar restart under production-shaped load, **when** clients reconnect, **then** they resume from their feed cursor with no lost committed LSNs.
6. **Given** the Windows target, **when** the dependency tree is built, **then** it compiles and the conformance suite passes there as well as on the Mac target.

## Dependencies & risks { id="eg6-risks" }

- **Depends on:** eg.1–eg.5.
- **Risk — Windows cross-compile:** the engine's native deps (Fjall, the async runtime, the object-storage client) must build on the target; verify early rather than at ship time (criterion 6).
- **Risk — protocol skew across release units:** the lockstep pin plus refuse-on-mismatch (criteria 1/3) is the guard.
