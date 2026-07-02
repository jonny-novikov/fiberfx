---
name: spawn-resilience-effective-messaging
description: "Agent-tool subagents die to ECONNRESET on long read-heavy single-shot runs (the main loop survives; files written survive, the final report is lost) — the fix is the write-ready dispatch: pre-ground the brief, short waves, write-first/heartbeat, recover-from-tree. Calibrated into x.md §5 LAW-1b + the venus/mars/apollo charters + mercury-ship; Apollo mentors it forward."
project: aaw
metadata:
  node_type: memory
  type: feedback
  originSessionId: 04aedc27-8416-46f7-9caa-737abf6c5adc
---

**The pattern.** Subagents spawned via the `Agent` tool die to `ECONNRESET` / "connection closed mid-response"
on **long, read-heavy, single-shot runs**. The Director's **main loop is resilient** because it checkpoints to
the Operator between turns; a subagent runs one long uninterrupted session and is exposed the whole time.
**Files written to disk SURVIVE the drop; the agent's final `SendMessage` report does NOT.** The build-agent
specifically kept dying because a correct build required a long *read-to-understand* phase (reading an intricate
existing surface to compose it) BEFORE any write — and the connection died mid-read, so nothing landed.
(mx.7.3.1 DateField: Venus died once mid re-scope; **Mars died 3×** — the last ran 14 min / 16 tool-uses, all
reads, wrote zero bytes. The earlier related finding: [[workflow-heavy-agent-no-schema]] — heavy agents are
fragile, recover from the tree.)

**The fix — the write-ready dispatch (effective messaging), now `x.md` §5 LAW-1b:**
1. **Pre-ground the dispatch.** Front-load EVERY fact the peer needs into the spawn prompt (or the Venus brief
   it reads) — exact signatures, file paths, the import convention, a usage sketch, the gate commands — so the
   peer's FIRST actions are writes, not a read-to-understand phase; cap its required reading at ≤2–3 named files.
   The grounding burden shifts to the resilient main loop: the Director (or Venus) pre-reads the intricate
   surface and hands a write-ready map. **This does NOT relax LAW-1a — the peer still writes the code.**
2. **Short waves, write-first, heartbeat.** Split a heavy build into sequential waves (the mx.7.2 "two waves"
   precedent; a date component = wave 1 the `@mercury/core` composable, wave 2 the `@mercury/ui` home). The peer
   writes a typed skeleton early, fills it in passes, `agent_heartbeat`s after each file + the gate.
3. **Recover from the tree, never the message.** When a spawn dies, read the on-disk tree (files survive) —
   never assume zero progress, never trust the lost report.
4. **Message-dedup + single-writer (the fold corollary).** A follow-up message that RESEMBLES a task the peer
   believes it finished gets DEDUPED as a stale echo ("nothing to do") — when reassigning, frame the NEW content
   as a **delta**, not a re-issue, and **restate the decision explicitly** (restating unsticks the dedup). During
   a multi-actor fold of the SAME file, hold **one writer per file**: the orchestrator assigns the file and HOLDS
   OFF co-editing — never races (a concurrent edit is a lost-update / `modified-since-read` collision). Recover a
   stuck peer by restating + reassigning, not by co-editing. (admin.5 Wave-2: venus deduped the rulings-fold as an
   echo → the Director restated the rulings, venus folded correctly, and the shared-triad collision was avoided by
   the single-writer hand-off.)

**Why:** the REAL-teammate (aaw Trio) model is correct and Operator-mandated; the deaths were a *process/messaging*
failure, not a reason to abandon the formation or to let the Director write the code (which would forfeit
verify-independence). The write-ready dispatch keeps the formation AND survives the infra.

**How to apply:** on any `Agent`-tool spawn for a non-trivial build, pre-ground the dispatch and keep each spawn
a short wave; recover from the tree on death. Calibrated 2026-06-30 into `x.md` §5 LAW-1b, the
`.claude/agents/{venus,mars,apollo}.md` charters, and `.claude/skills/mercury-ship/SKILL.md`; the **message-dedup + single-writer** corollary folded 2026-07-01 into `.claude/skills/cm-program.md` (Process locks) on admin.5. **Apollo is now the
team's STANDING mentor** (Operator-directed): it folds craft + contract + **spawn-resilience** findings forward
into the peer charters every rung (one guardrail per recurring finding, Director-ratified — the harness fences a
peer's self-edit, so Apollo proposes and the Director applies). See [[apollo-mentoring-loop]]
[[right-size-formation-and-write-only-artifacts]] [[mercury-design-system]].
