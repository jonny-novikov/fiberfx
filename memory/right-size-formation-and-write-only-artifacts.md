---
name: right-size-formation-and-write-only-artifacts
description: "Process economy (Operator-demanded) — right-size the lead-team to the change (Director triages at bootstrap; trivial → 1 builder, not the full team), and treat generated build artifacts as WRITE-ONLY (never Read/grep-lines/git-diff a bundle)"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: ea166460-792a-489c-8261-70a210260059
---

Two cost-discipline rules the Operator demanded after a ~2-line CSS fix burned ~300k tokens (the `prt-3-fix` run, 2026-06-15).

**1. Right-size the formation to the change — the Director triages at bootstrap.** The full x-mode lead-team (Venus → builder ×2 → Director [+Apollo]) is the NORMAL default, **not the floor**. Before standing up the team, the Director MUST classify the change and pick the smallest formation: **trivial / Director-clear** (one file ± its regenerated artifact, mechanical, no behavior/contract/schema change; OR the Director's §0 deep-reason already settles the design + the fix is small/low-risk) → **Director inline brief → ONE builder → ratify + commit** (no separate Venus triad, no Mars-2, no Apollo); **normal** → the full lead-team; **high-risk** → +Apollo. Rigor (the gate ladder + the running-server proof) is **CONSTANT** across tiers — only the FORMATION (ceremony) scales. Record the tier in the T-n trace. LAW-1a still binds (the builder edits production code, never the Director); a faked team is never the answer (LAW-1). **Baked into the supervised ship loop (§0.5 + the §5 quality-gate check).**

**2. Generated build artifacts are WRITE-ONLY.** Never `Read` / grep-lines / `git diff` a committed bundle (`priv/static/assets/js/app.js`, `priv/svelte/server.js`, hashed CSS) — they are opaque + huge (~200 kB minified ≈ 60k tokens per read; a few reads across 3 agents IS the 300k). Verify a build via the **source** + a `grep -c <token>` count + the running-server `curl`. The bundle still ships in the LAW-4 pathspec — committed, just never opened. The structural fix (gitignore the bundles + build at deploy/CI) was **DEFERRED** by the Operator 2026-06-15. Related: [[workflow-heavy-agent-no-schema]].
