---
name: user-commits-elixir-batches
description: "The user commits elixir course work himself, out-of-band, batch by batch — so the working tree goes clean unexpectedly"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 73b81fc7-ffef-4d6d-ac38-349cafb4dda9
---

When fanning out elixir course work, the user (Ivan Novikov) commits each completed batch **himself, out-of-band** (in his own terminal), with clean one-line messages like `elixir: cqrs`, `elixir: functional hero`, `elixir continuation`. The whole repo working tree can go from dirty to `total dirty paths: 0` between my turns without me committing anything.

**Why:** he reviews each batch as it lands and commits it — a single commit often spans all files in a batch (e.g. one `elixir: functional hero` commit touching all 6 F2 hubs), which no per-hub subagent could have produced. This is his prerogative; my commit-only-when-asked rule binds only me.

**How to apply:** don't assume my changes stay "staged for your review" — by the next turn they may already be committed. Before claiming work is uncommitted, check `git log --oneline` + `git status`. Don't re-commit or offer to commit work he's already committed. A clean tree mid-session is normal, not a sign of lost work. Verify with `git log -- <path>` that a batch landed in a commit rather than assuming it's still dirty. Relates to [[elixir-course-update-pipeline]] and [[elixir-hero-svg-fanout]].

⚠️ **His batches are often PRE-STAGED in the index** (not just unstaged-modified). So a plain `git commit` of *your own* work **bundles his staged batch into your commit** — `git commit` commits the whole index, not just the files you `git add`. This bit a Director commit on 2026-06-03: an F5.9 commit swept **313 staged `html/` site-restructuring renames** into it (316 files instead of 3). **Before any commit, run `git diff --cached --name-only`**; if it shows his files already staged, commit ONLY your paths with a **pathspec commit** — `git commit -F msg -- <your exact paths>` — which captures just those and leaves his staged batch intact. Recover a botched bundle with `git reset --soft HEAD~1` then the pathspec commit (preserves his staging). This is the LAW-4 "only changes attributable to this task" invariant in a shared-tree reality.
