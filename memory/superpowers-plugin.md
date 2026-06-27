---
name: superpowers-plugin
description: obra/superpowers skills plugin enabled at PROJECT scope for jonnify; integration doc + the conflicts where CLAUDE.md wins
metadata: 
  node_type: memory
  type: project
  originSessionId: a038183c-ad2d-4615-9a53-6b094766bd56
---

The **superpowers** plugin (`obra/superpowers`, official Claude skills library) is enabled at **`project` scope** for `/Users/jonny/dev/jonnify` — pinned in `.claude/settings.json` → `enabledPlugins."superpowers@claude-plugins-official": true` (v6.0.3, installed 2026-06-27). Ships **14 skills + one `SessionStart` hook** (matcher `startup|clear|compact`) that injects the `using-superpowers` bootstrap so skills auto-trigger; **no** slash-commands / agents / MCP of its own. Skills load via the `Skill` tool as `superpowers:<name>`.

**Integration doc = `docs/aaw/aaw.superpowers.md`** (authored 2026-06-27): the install fact, the 14-skill catalog, the canonical chain (brainstorming → writing-plans → worktrees → SDD/executing-plans w/ TDD+debugging+verify → finishing-a-branch), the superpowers↔AAW crosswalk, and prioritized opportunities.

**Why it matters / how to apply** — superpowers is a SECOND full methodology beside AAW. Its own priority ladder says **user CLAUDE.md wins**, so the integration is mostly making it defer:
- **Commit/merge/push**: TDD's "Commit" step + `finishing-a-development-branch` (merge/PR/discard) are OVERRIDDEN by root CLAUDE.md — commit only when asked, LAW-4 pathspec, never `git add -A`, Operator pre-stages, don't push, Operator runs deploys. Take superpowers' TDD discipline, NOT its auto-commit cadence on rung work.
- **"Tests pass" = the gate ladder** (TMPDIR=/tmp · Valkey 6390 · warnings-as-errors · conformance · ≥100 determinism loop), not a bare `mix test`.
- **Doc-path collision**: superpowers writes to `docs/superpowers/specs|plans/*` + `.superpowers/sdd/progress.md` (didn't exist as of authoring) — for rung work redirect to the AAW tree (`docs/<program>/specs/`, `specs/progress/`).
- **`<SUBAGENT-STOP>` carve-out**: dispatched fan-out peers (Venus/Mars/Apollo, `*-expert`) do NOT inherit the bootstrap — fold wanted disciplines into their charters/`*-ship` skills.
- **Gap-fillers AAW lacks** (no conflict, pure addition): `test-driven-development`, `systematic-debugging`, `verification-before-completion`.

Companion reference, not an AAW rung (no triad/dashboard). [[aaw-memory]]
