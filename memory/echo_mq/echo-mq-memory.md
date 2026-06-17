---
name: echo-mq-memory
description: "EchoMQ v3 Program - . This memory index = slim pointers + frontier (de-bloated to disk 2026-06-15)."
metadata:
  node_type: memory
  type: project
  originSessionId: 0be564f9-9bb6-42f9-8196-f11e99620607
---

This memory is a **slim pointer, not the source of truth**. The operating manual, the agent calibrations, the
footguns, and the gate ladder are a committed on-disk doc:
- **`docs/echo_mq/program/emq.program.md`** — THE operating manual: the AAW pipeline, the roster + the
  per-agent calibrations (`emq.{venus,mars,apollo}.md`, same folder), the boundary, the gate ladder, the durable
  footguns, the live frontier.
- `docs/echo_mq/emq.design.md` (canon, S-1..S-7) · `emq.roadmap.md` (plan + ladder) · `emq.progress.md`
  (as-built dashboard) · `emq.features.md` (catalog + **Part C** forward-features) · `emq.testing.md`.
- Run-ledgers (per-rung audit trails): `docs/echo_mq/specs/progress/emq-N-M.progress.md`.

Related: [[echo-mq-stories-generator]], [[echo-mq-three-movements]]
