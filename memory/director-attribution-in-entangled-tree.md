---
name: director-attribution-in-entangled-tree
description: "FEEDBACK — in the entangled jonnify tree, `git diff` vs HEAD shows the NET delta from ALL concurrent sources, not the spawned builder's edits; attribute against the builder's pre-spawn baseline"
project: aaw
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 8c85ea96-925f-41ca-80a2-7859620110e6
---

In the `jonnify` root the working tree is chronically entangled — the Operator pre-stages out-of-band AND concurrent agents edit the SAME files mid-run (branch commits land alongside yours). So `git diff HEAD` on a builder's touched files shows the **net delta from every source**, NOT just the builder you spawned.

**The miss (shipping liveview-boot coverage, 2026-07-01):** I credited a `vitest` add + a `typescript ^5.5.4 → ~5.9.3` pin to `mars-lvboot` because the diff-vs-HEAD showed them. But my own PRE-SPAWN grounding-read of `package.json` showed `^5.5.4` + no vitest — so those lines appeared between my read and the builder's first read = **concurrent, not the builder's edits**. Mars ran no git (couldn't tell uncommitted-vs-HEAD) and had only added jsdom + scripts + the tests + 2 exports. I over-attributed; it flagged it fairly.

**Why:** false attribution corrupts the ledger + unfairly faults a careful builder; a builder's specific "I edited only X" beats my diff-inference in an entangled tree.

**How to apply:** before crediting/faulting a builder for a hunk, compare against its ACTUAL starting baseline (your pre-spawn grounding-read, or a snapshot/`git stash` marker), or trust its reported change-list over raw diff-vs-HEAD. The commit still captures the correct final file state either way — this is about attribution/narration, not the bytes. [[spawn-resilience-effective-messaging]] [[right-size-formation-and-write-only-artifacts]]
