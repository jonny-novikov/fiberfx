---
name: right-size-formation-and-write-only-artifacts
description: "Process economy (Operator-demanded) — right-size the lead-team to the change (Director triages at bootstrap; trivial → 1 builder, not the full team), and treat generated build artifacts as WRITE-ONLY (never Read/grep-lines/git-diff a bundle); CANONICALIZED on-disk for all AAW agents at docs/AAW_DEVELOPMENT.md (the pragmatic-delivery charter)"
project: aaw
metadata: 
  node_type: memory
  type: feedback
  originSessionId: ea166460-792a-489c-8261-70a210260059
---

Two cost-discipline rules the Operator demanded after a ~2-line CSS fix burned ~300k tokens (the `prt-3-fix` run, 2026-06-15).

**1. Right-size the formation to the change — the Director triages at bootstrap.** The full x-mode lead-team (Venus → builder ×2 → Director [+Apollo]) is the NORMAL default, **not the floor**. Before standing up the team, the Director MUST classify the change and pick the smallest formation: **trivial / Director-clear** (one file ± its regenerated artifact, mechanical, no behavior/contract/schema change; OR the Director's §0 deep-reason already settles the design + the fix is small/low-risk) → **Director inline brief → ONE builder → ratify + commit** (no separate Venus triad, no Mars-2, no Apollo); **normal** → the full lead-team; **high-risk** → +Apollo. Rigor (the gate ladder + the running-server proof) is **CONSTANT** across tiers — only the FORMATION (ceremony) scales. Record the tier in the T-n trace. LAW-1a still binds (the builder edits production code, never the Director); a faked team is never the answer (LAW-1). **Baked into the supervised ship loop (§0.5 + the §5 quality-gate check).**

**2. Generated build artifacts are WRITE-ONLY.** Never `Read` / grep-lines / `git diff` a committed bundle (`priv/static/assets/js/app.js`, `priv/svelte/server.js`, hashed CSS) — they are opaque + huge (~200 kB minified ≈ 60k tokens per read; a few reads across 3 agents IS the 300k). Verify a build via the **source** + a `grep -c <token>` count + the running-server `curl`. The bundle still ships in the LAW-4 pathspec — committed, just never opened. The structural fix (gitignore the bundles + build at deploy/CI) was **DEFERRED** by the Operator 2026-06-15. Related: [[workflow-heavy-agent-no-schema]].

**Canonicalized on-disk 2026-06-18** at `docs/AAW_DEVELOPMENT.md` — the durable pragmatic-delivery charter for all AAW agents (no longer only a memory). Beyond the two rules above it adds: **code-first for small work** (the code IS the spec — don't author a triad before ~20 lines); **specs are slim + high-level** (the body names the surface + links the detail; a shipped rung's body is ~50 lines not 500 — the code/ledger/design-doc are the authorities, not spec prose); **don't fuse a horizon/model decision into a delivery rung** (settle it standalone or it thrashes the rung); the pathspec commit discipline. Forged this session: the emq.4.2 overbloat retro (a 1-call-site rung run through a full lead-team) → the ewr.1.4 small-solo ship → slimming the ewr.1 spec bodies (~1020 lines cut; 4 bodies → ~50 lines each).
