---
name: reorg-link-rebase-verification
description: "Craft lesson on verifying relative-link re-bases after a docs folder reorg — a \"0 broken\" claim is only as good as the checker's coverage"
project: echo_mq
metadata: 
  node_type: memory
  type: feedback
  originSessionId: cf9d923d-49af-48b8-b3d5-3a7e946c231a
---

When moving files into a new subfolder (a docs reorg — e.g. `specs/emq.N.*` → `specs/emq.N/`) and re-basing their relative links, two verification gaps bite, and a "0 broken" report that misses them is the failure mode the Director called out (echo_mq specs/ reorg, committed cbba4517).

**The gap that fired:** I re-based the cross-folder `./emq.2.4.*` links but MISSED `./emq.2.prompt.md` in `emq.3.1.prompt.md` — both point into `emq.2/`, but my re-base rule anchored on the literal `emq.2.4` (the links I'd *noticed*) instead of a general rule. The Director's independent sweep caught it; I had reported "0 broken."

**Why:** **The re-base rule was an enumeration, not a generalization.** A correct rule is "every `](./emq.N.X)` where emq.N.X now lives in `emq.N/` → `](../emq.N/emq.N.X)`" — covering chapter prompts/designs/tooling AND sub-rungs, not just the sub-rung family I spotted. **And the resolution sweep ran against a moving target** (the Operator was concurrently editing the file), so the snapshot my checker read differed from the snapshot the Director committed against — the "0 broken" was true for my read, false at commit.

**Why:** A reorg re-base is **non-idempotent** (re-running `../→../../` double-breaks), so you can't "just re-run to be safe" — the verification has to be RIGHT the first time, which makes checker coverage the whole game.

**How to apply:** After a folder reorg, before claiming links resolve:
1. **Generalize the re-base rule**, don't enumerate: for EVERY `](./X)` / `](../specs/X)` where X moved, rewrite to the new path — derive the set from the move map (every moved filename), not from the links you happen to see in a grep.
2. **Run a REPRODUCIBLE full sweep on a STABLE tree**: extract every relative target from each file and resolve it `( cd "$(dirname f)" && [ -e "$target" ] )` from that file's NEW directory — and re-run it once more after any concurrent edits settle (if the Operator is editing in the same tree, the first sweep's snapshot is stale). Cross-folder `emq.N/...` refs are the easy miss — check them explicitly.
3. The check counts only if it RUNS against what ships: a "0 broken" claim is only as good as (a) the rule's coverage and (b) the tree's stability at check time. Related: [[echo-mq-three-movements]] (the spec-home convention: `specs/` = chapter triads, decomposition → `specs/emq.N/`, ledgers → `specs/progress/`).
