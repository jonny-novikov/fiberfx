---
name: elixir-content-fanout-drift
description: "Content-authoring fan-out agents reliably invent/redefine the established Portal API even when told 'reuse exactly'; the cms gates can't catch it; the 3-part guard that does"
metadata:
  node_type: memory
  type: feedback
  originSessionId: 73b81fc7-ffef-4d6d-ac38-349cafb4dda9
---

When fanning out subagents to AUTHOR /elixir course content that must use the established Portal model (technique sections, heroes, worked examples), builder agents reliably **invent or redefine established API surface even when the prompt says "reuse the established names exactly."** Observed 2026-06 extending F5 (9 modules): only 3/9 passed first round; the other 6 each drifted.

**Why:** the 9 cms gates (containers/svg/no-future/voice/storage/motion/degrade/links/pager) check **structure, not semantic truth** — they never check whether code compiles, whether arities/arg-orders/struct-names match the model, or whether a cited reference actually contains the technique. So a structurally-perfect page citing the wrong source or calling a non-existent function gets **grade: A+ / STATUS: PASS**. The drift is invisible to gates and only an independent reader catches it.

**Concrete drift modes seen (all passed cms):** wrong arity (`append/1` vs established `append/2`); reversed arg order (state-first `evolve(state, event)` → `Enum.reduce(events, acc, &evolve/2)` raises FunctionClauseError; established is event-first); two sections EACH `defmodule Portal.Progress` with incompatible fields (no canonical one existed — both invented); wrong event name (`%Enrolled{}` vs established `Portal.Events.LearnerEnrolled`); mis-grounded citation (attributing `mod:`/`use Application`/`start/2` to the "Introduction to Mix" guide when that material lives in the separate "Supervisor and Application" guide — caught by the verifier's own doc-fetch).

**The guard — bake all three into every content fan-out:**
1. **Ground the model facts yourself first** (grep + READ the canonical pages for the exact struct/function/arity/arg-order/event names; confirm each cited URL actually documents the claimed technique) and pass them VERBATIM into the build prompts. Note: course code is syntax-highlighted HTML, so identifiers split across `<span>` tags — raw grep misses `%Enrolled{`; instruct agents to READ sibling pages, not just grep.
2. **Hard "no-invent" constraint** in the prompt: do NOT `defmodule`/`defstruct` anything that exists elsewhere; reference established names; update EVERY touchpoint together (prose, `# =>` outputs, SVG `<text>`, comments).
3. **Independent adversarial verify stage** (Sonnet is adequate) that re-runs `cms check` + `cms audit` AND judges `portal_correct` / `elixir_idiomatic` / `technique_grounded` / `no_duplication`, told to construct a counter-example before passing.

**Remediation that converged 6/6 in one pass:** director grounds the true facts, bakes the per-failure verifier verdict + fix + facts into tightly-scoped fix prompts ("the section is ALREADY there — FIX in place, don't add a second"), then re-verifies. Relates to [[elixir-hero-svg-fanout]], [[jonnify-cms-toolchain]], [[elixir-references-bibliography]].
