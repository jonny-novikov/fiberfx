---
name: apollo-mentoring-loop
description: "Apollo's expanded role in the echo/Portal F6 loop — .operator.md writer + Venus/Mars mentor; the propose-only channel + aim-by-peer rule"
metadata: 
  node_type: memory
  type: project
  originSessionId: c7d5d4e9-d820-4d06-8d25-34dc4a9ea156
---

As of 2026-06-05 the Apollo agent (echo/Portal spec-driven build loop, `.claude/agents/apollo.md`) carries two duties past the single-rung verifier role, both encoded in its definition (calibrated 2026-06-05, ratified in commit 6e4eb79):

1. **Keeper of the `.operator.md` process guide** (e.g. `docs/elixir/specs/phoenix/phoenix.operator.md`) — reconcile it to *shipped process reality*, document-from-evidence, process-not-intent (priorities/rules go to the Director, never into the guide).
2. **Post-build MENTORING feedback loop to Venus + Mars** — fold each rung's craft/contract finding forward so it outlives the stateless spawn.

**The durable mentoring channel is PROPOSE-ONLY, not write.** Editing a peer agent def (`mars.md`/`venus.md`) requires an explicit Operator grant per action — the harness fences peer-def edits, and blocked even the Director's first unilateral `mars.md` attempt. So: Apollo surfaces the EXACT diff in the verdict report; the **Director applies + commits** at rung close. `apollo.md` stays Director-owned too — no Apollo self-edits (the self-mod fence is a brake to respect, and the calibrated def says so).

**Aim the guardrail by the peer whose CONTRACT the finding implicates — not whoever's code shows the symptom.** Worked example (F6.6): the `@courses`-as-assign mechanism drift looked Mars-facing, but Mars correctly *overrode* the brief's assign-language to streams — so the defect was the brief carrying mechanism-words as unverified claims → a **Venus** lesson ("mechanism words are claims too"), filed in `venus.md`. The inert-`doctest Portal.Catalog` finding was genuinely Mars-facing. One durable guardrail per RECURRING finding, not per occurrence.

**Mentor on craft + contract-fidelity ONLY, never intent** — an intent divergence stays a STALE reported to the Director (the Operator owns WHAT-to-build).

F6 retrospectives live in a NEW `docs/elixir/specs/phoenix/f6.progress.md` (F6 is its own ladder), not `f5.progress.md`. Determinism loop is ≥100 (was a stale `seq 1 20` in several durable assets — now fixed across `apollo.md`/`mars.md`/`f6.6.prompt.md`; `phoenix.operator.md` was already 100). Related: [[workflow-heavy-agent-no-schema]].
