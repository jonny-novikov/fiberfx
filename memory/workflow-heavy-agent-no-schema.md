---
name: workflow-heavy-agent-no-schema
description: "a long-running edit/build Workflow agent given a large required-field schema can finish WITHOUT calling StructuredOutput → the whole workflow aborts; give edit-heavy agents no schema (prose), reserve small schemas for short read-only passes; the build survives in the tree so recover by resuming from the next stage"
project: aaw
metadata: 
  node_type: memory
  type: feedback
  originSessionId: c7d5d4e9-d820-4d06-8d25-34dc4a9ea156
---

A Workflow `agent(..., {schema})` call **fails the entire workflow** if the subagent ends without calling the `StructuredOutput` tool ("subagent completed without calling StructuredOutput after 2 nudges"). This fires most on **long-running edit/build agents** (dozens of tool calls, large final context) handed a **big required-field schema** (e.g. a nested 7-box DoD checklist + ~11 required fields): the model "feels done" after the work and skips the closing tool call. Observed on the f6.2 build (Mars, 71 tool uses) — the build completed correctly but the report was lost and the workflow aborted before the downstream stages.

**Why:** the failure is in *reporting*, not the work. Workflow agents edit the **real working tree**, so a build survives the abort intact — only the structured return is gone.

**How to apply:**
1. **Edit-heavy agents (build / harden / remediate) → NO schema.** Have them return a plain-text REPORT block (end the final message with "VERDICT / compile / test counts / what changed"). A prose return cannot fail the StructuredOutput check. Read the prose; pass it into the next agent's prompt.
2. **Schemas only on short read-only analytical passes (review / reconcile),** and keep them small — ~3-5 flat fields, minimal nesting — so they reliably emit. Branch the workflow on those (e.g. `review.verdict`).
3. **Recovery after this abort = resume from the NEXT stage, not rebuild.** Probe the tree (`git status`, `mix compile`, `mix test`); the heavy agent's files are already there. Launch a fresh lighter pipeline (or resume the script after editing schemas) starting at the stage after the one that produced the work. Re-running the heavy agent wastes the completed build.

Validated shipping the F6.2 rung (wf wuapcpyv0 aborted at Mars report-time; wg1824894 recovered from Mars-2 over the intact tree).
