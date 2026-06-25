---
name: director-commits-every-rung
description: "As Director, commit the rung's files every rung — a rung is not done until committed (standing Operator ask; overrides the \"commit only when asked\" default for rung work)"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 874ee9ef-331a-49fc-82d7-80158cd7f6d8
---

The Operator's standing directive: **"As a Director, you must commit rung files every rung."** A rung — including a **Director-solo docs / reorg / program rung**, not only a full x-mode team rung — is **not done until its files are committed**. Do not default to "leave it in the working tree for the Operator's out-of-band commit" for rung work; that leave-it default is for ad-hoc non-rung edits, not for a completed rung.

**Why:** corrected after a codemojex docs-consolidation + program-creation rung was completed + verified but left uncommitted (I reported done and *offered* to commit rather than committing as the closing step). The LAW-4 "Director is the sole committer of the rung" duty applies to **every** rung, not just the team-pipeline ones.

**How to apply:** when a rung's work is complete + verified, the Director's closing step **is** the commit — LAW-4 discipline: pathspec only (never `git add -A` / never a bare commit), re-verify `git diff --cached --name-only` is purely the rung boundary, guard on `.git/rebase-merge`/`rebase-apply`, branch off the default first if on it, one scoped commit per concern, `git mv` so renames stay `R100` (records-freeze proof). The standing "commit rung files every rung" ask satisfies the global "commit only when asked" rule **for rung work**; still ask before **pushing** and before committing ad-hoc non-rung changes. Related: [[right-size-formation-and-write-only-artifacts]] (the Director triages the formation at bootstrap).
