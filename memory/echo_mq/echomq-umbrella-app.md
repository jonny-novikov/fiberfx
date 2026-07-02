---
name: echomq-umbrella-app
description: "apps/echomq is REMOVED — its surface was rewritten fresh into echo_mq under the v2 laws, then deleted. Tombstone of the former 5th umbrella app."
project: echo_mq
metadata:
  node_type: memory
  type: project
  originSessionId: 115257c9-0f9f-4c20-8429-887322132a0e
---

**Residual facts still true:**
- `echo/apps/echo_mq`'s mix project module is `EchoMq.MixProject` — it dodged the old `EchoMQ.MixProject`
  collision with the v1 app (the umbrella loads every child mix.exs into one VM). The name persists though the
  collision is now moot.
- The v1→v2 parity record lives in `docs/echo_mq/emq.features.md` + the command registry
  (`docs/echo_mq/specs/emq.commands/`, now rung-mapped). Any doc still citing `apps/echomq` as a live reference
  is STALE — see the audit `docs/echo_mq/audit/emq.audit.2026-06-17.md` P3 (CLAUDE.md + `.claude/skills/echo-mq-surface.md`).

Related: [[echo-mq-three-movements]].
