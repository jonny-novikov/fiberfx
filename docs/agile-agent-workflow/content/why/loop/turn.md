# A1.03.2 — One turn of the loop

- **Route:** `/course/agile-agent-workflow/why/loop/turn`
- **File:** `html/agile-agent-workflow/why/loop/turn.html`
- **Place in the module:** the second dive of A1.03 — *how it turns*. One rung's journey through the six stages
  and the handoffs between the roles.
- **Accent word (`.ex`):** "turn".

## Lead

One rung runs as one turn of the loop: six stages, each with a clear owner and a clear output, handed back and
forth across the line. Sharpen, demo, review, and feedback are the Operator's; build and ship are the Author's.
Each stage exists to prevent a specific failure — drop one and a named failure from A1.01 returns.

## The six stages (ground in A0.2.3 — do not renumber or reassign)

1. **sharpen** (Operator) — scope the next rung to a thin slice and fix what "done" means. Output: a sharpened
   intent the Author can spec from.
2. **build** (Author) — turn the sharpened rung into a spec, then build the increment from the spec and brief.
3. **ship** (Author) — ship the increment so it can be exercised for real.
4. **demo** (Operator) — exercise what returned; see it run on something real.
5. **review** (Operator) — judge the increment against the spec; accept it or send it round again.
6. **feedback** (Operator) — record what to change; this edits the spec, and the loop runs again (adapt).

## Why each stage earns its place

The loop is not ceremony; each stage removes the property that makes a known failure possible. Skip `sharpen` and
the Author builds with no spec — **vibe coding** (A1.01.1). Skip `review` and unaccepted work ships — vibe
coding's unaccountable diff again. Skip `feedback` and the spec never adapts, drifting toward the **big-bang spec**
(A1.01.2). The stages are the slice's acceptance, distributed across one turn.

## Worked Portal example

One turn for the rung "one branded id": the Operator sharpens ("a 14-char id that decodes to its type, unique
within a node-ms — that is done"); the Author specs it and builds `Portal.ID.generate/1`; ships it; the Operator
demos (the id decodes), reviews (against the contract), and gives feedback ("also keep them sortable by time").
The feedback edits the spec, and the next turn begins on an accepted rung. Use only the established API.

## The two interactives (different teaching moves)

- **Hero figure — step through the turn (the SHAPE).** A stepper: a `.solid-select` of the six stage names
  `#tnStep` (sharpen / build / ship / demo / review / feedback), with sharpen active. The SVG is the six-stage
  loop; the selected stage's node highlights (gold if Operator-owned, blue if Author-owned), the others dim.
  Readout `#tnOut` names the stage, its owner, and its output. Pure: a fixed array
  `STAGES = [{k:'sharpen',role:'Operator',out:'a sharpened rung'}, …]`; no computation beyond highlight. Initial
  static state = sharpen. element ids: `#tnStep`, node group `#s-sharpen`…`#s-feedback`, `#tnOut`.
- **Content figure — skip a stage (the CONSEQUENCE).** A `.solid-select` `#tnSkip`: "loop intact" (data-k="none",
  data-c="sage", active) / "skip sharpen" (data-k="sharpen", data-c="burg") / "skip review" (data-k="review",
  data-c="burg") / "skip feedback" (data-k="feedback", data-c="burg"). The SVG dims the skipped node and marks the
  break. Pure map `BREAKS = { none:'the loop holds: every rung is specified, accepted, and adapts', sharpen:'the
  Author builds with no spec → vibe coding (A1.01.1)', review:'unaccepted work ships → the unaccountable diff
  (A1.01.1)', feedback:'the spec never adapts → drift toward the big-bang spec (A1.01.2)' }`. Readout `#tnBreak`
  names the returning failure. Initial static state = "loop intact". element ids: `#tnSkip`, the same node group
  reused or a second small loop `#k-*`, `#tnBreak`.

## Bridge / recap / references

- **bridge:** principle — six owned stages, each preventing a known failure → Portal — one turn mints one accepted
  branded id: sharpen the contract, build `generate/1`, ship, demo, review, feed back.
- **take:** the loop is the slice's acceptance spread across one turn — each stage the answer to a failure, so
  dropping one lets that failure back in.
- **sources (real):** Beck, *Extreme Programming Explained* (the cycle and short feedback); Schwaber & Sutherland,
  *The Scrum Guide* (sprint → review → retrospective); Hunt & Thomas, *The Pragmatic Programmer* (feedback).
- **related:** A1.03.1 roles, A1.03.3 adapt, the A1.03 hub, A1.01.1 vibe-coding, A1.01.2 big-bang-specs, A1.

## Wiring

- route-tag `/course/agile-agent-workflow/why/loop/turn`; crumbs jonnify / AAW / A1 (`/why`) / A1.03 (`/why/loop`)
  / here. Pager: prev → A1.03.1 roles (`/why/loop/roles`); next → A1.03.3 adapt (`/why/loop/adapt`).
- `.hero-split`: hero text beside the step-through interactive. Copy head/header/footer/scripts from
  `html/agile-agent-workflow/why/loop/roles.html` (same module — exact design-system parity).
