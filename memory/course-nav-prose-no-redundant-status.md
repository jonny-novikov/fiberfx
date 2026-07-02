---
name: course-nav-prose-no-redundant-status
description: "In /elixir nav prose don't announce completion/status (\"chapter is complete\", \"all built\", \"every chapter is live\") — the module cards' pills already show it"
project: elixir
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 73b81fc7-ffef-4d6d-ac38-349cafb4dda9
---

On the /elixir course-root index and every chapter hub, the "Module navigation" prose must describe **structure + the build-order arc**, never announce status. The user flagged "The chapter is complete" as **redundant to write** (2026-06-02) — and by extension "All nine modules are built" / "Every chapter is live". The module cards already carry `built`/`planned` pills, so prose that restates status is filler.

**Why:** the pills are the status source of truth; repeating them in prose adds nothing and reads as noise — same spirit as the technical-writer rule "lead with what's useful, no filler".

**How to apply:** when a chapter finishes, write the nav prose to say what's there and how to move through it, then delete any "is complete / are built / is live" clause. Good: *"Each of the nine modules links to its hub and three deep dives. The arc is the build order — start at F6.01, the request lifecycle, and end at F6.09, the live dashboard."* Course-root intro: *"The whole course, chapter by chapter. Open any one."* (not "every chapter is live"). This is presentational drift's twin — see [[elixir-content-fanout-drift]] for the status-vs-manifest drift on the same pages, and [[f5-f6-page-bugs]] for other hand-authored-page defects the cms gates don't catch.
