# A0 — Foundations (chapter landing / module overview)

- **Route (served):** `/course/agile-agent-workflow/what`
- **File:** `html/agile-agent-workflow/what/index.html`
- **Place in the chapter:** the A0 chapter landing — the "A0 · chapter overview". It frames the three
  foundational modules (A0.1 Why it works, A0.2 What we are building, A0.3 Who does the work) and routes the
  reader to the one built module, A0.2. (A0's landing was consolidated from the former `/intro` page into
  `/what`; the old `/intro` route is retired, and this page is now the A0 chapter landing.)
- **Accent word (`.ex`):** "workflow" (`<span class="ex">workflow</span>` in `<h1>Why an agile agent workflow</h1>`).

## Lead

The foundations, in three questions. **Why** a pragmatic, story-led, agent-driven workflow beats both vibe coding
and big-bang specs. **What** we are building — the framework the course runs on, in two layers, four artifacts,
and one loop. And **who** does the work — the two roles that drive every rung. Select a question to see its module.

(Hero lede, verbatim. Eyebrow: "A0 · chapter overview". The kicker slot is not present on this landing — the hero
has crumbs → eyebrow → h1 → lede → `.toc-mini`, no separate `.kicker` line.)

## What the landing frames (the chapter map it presents)

The page presents the A0 chapter as three modules, each holding three subpages. In the `#modules` section prose
(verbatim): "Three modules carry the foundations. **A0.2 — What we are building** is written now; it lays out the
framework every later chapter applies. **A0.1 — Why it works** and **A0.3 — Who does the work** are on the way.
Each module holds three subpages."

The hero figure (the `wwSel` interactive) restates the same three-tile map: **Why it works** (A0.1) · **What we
are building** (A0.2) · **Who does the work** (A0.3).

## The `.mods` card list (each module + its subpages)

The `.mods` grid holds three `<div class="mod">` cards (none is an `<a>` — the module cards themselves are not
linked; only the built module's subpage `.dives` are links). Each card: number, status pill, title (`.t`),
one-line (`.o`), and a `.dives` list of three subpages.

- **A0.1 · Why it works** — pill `soon` (static `<div class="mod">`, not a link)
  - one-line: "The case: the two ways software built with AI fails, and why thin, provable slices beat both."
  - dives (plain text, no links): A0.1.1 The two failure modes · A0.1.2 Pragmatic Programming, for agents · A0.1.3 Correct by definition
- **A0.2 · What we are building** — pill `built` (static `<div class="mod">`; its three dives ARE links)
  - one-line: "The framework the course runs on: its structure, its vocabulary, and how it moves."
  - dives (linked):
    - A0.2.1 The two-layer model → `/course/agile-agent-workflow/what/two-layer-model`
    - A0.2.2 The four artifacts → `/course/agile-agent-workflow/what/four-artifacts`
    - A0.2.3 The Author/Operator loop → `/course/agile-agent-workflow/what/author-operator-loop`
- **A0.3 · Who does the work** — pill `soon` (static `<div class="mod">`, not a link)
  - one-line: "The pairing: the human who decides and accepts, the agent who specifies and builds, and the rhythm between them."
  - dives (plain text, no links): A0.3.1 The Operator · A0.3.2 The Author · A0.3.3 The pairing in practice

`.note` after the grid (verbatim): "Start with the built module, **A0.2 — What we are building**: read
[A0.2.1 · The two-layer model](/course/agile-agent-workflow/what/two-layer-model) first. The next chapter,
[A1 · Decomposition](/course/agile-agent-workflow/why), turns this framework into a backlog of user stories."

## The interactives

This A0 landing carries **one** interactive (the hero `wwSel` figure), plus the footer build-stamp decoder. There
are no `.fold-ctrl` sliders, no second content figure, and no `pre.code` block on this page. The `.solid-select`,
`.geo-readout`, etc. CSS shells are present in the shared `<style>` but only the single hero group is instantiated.

### Hero figure — "The chapter · why, what, who" (`#wwSel` selector + `#wwOut` readout)

- **Markup:** a `<figure class="fig" aria-labelledby="wwTitle">` titled "The chapter · why, what, who". Inside:
  a `.controls` > `.solid-select#wwSel` group of three buttons, an inline `<svg viewBox="0 0 440 268">` with three
  tile `<rect>`s (`#wwWhy`, `#wwWhat`, `#wwWho`), and a `.geo-readout#wwOut` (`aria-live="polite"`).
- **Control ids / buttons:** `#wwSel` group, role="group". Three `<button>`s:
  - `data-k="why"  data-c="blue"` — label "why" — starts with class `active`
  - `data-k="what" data-c="gold"` — label "what"
  - `data-k="who"  data-c="sage"` — label "who"
- **SVG rect ids:** `#wwWhy` (A0.1, blue `#5a87c4`), `#wwWhat` (A0.2, gold `#d4a85a`), `#wwWho` (A0.3, sage `#7ba387`).
- **Pure function:** `pick(k)` — for each key in `WW {why, what, who}`, sets the matching rect's `stroke` to
  `bright` when `key === k` else `base`, and `stroke-width` to `'3'` (on) / `'2'` (off); toggles each `#wwSel`
  button's `active` class and `aria-pressed` by `data-k === k`; and writes `OUT[k]` into `#wwOut.innerHTML`.
  Wired via `addEventListener('click', …)` on each button; initial call `pick('why')`.
  - `WW` palette dataset: `why {id:'wwWhy', base:'#5a87c4', bright:'#9fc0ea'}`,
    `what {id:'wwWhat', base:'#d4a85a', bright:'#f0cd7f'}`, `who {id:'wwWho', base:'#7ba387', bright:'#a7c9b1'}`.
- **Readout strings (`OUT`, verbatim — the `#wwOut` default in HTML matches the `why` string):**
  - why: "Why it works: two failure modes to avoid — vibe coding and big-bang specs — and the case for thin, provable slices. Module A0.1."
  - what: "What we are building: the framework the course runs on — two layers, four artifacts, one loop. Module A0.2, and the one that is built."
  - who: "Who does the work: the Operator who decides and accepts, the Author who specifies and builds, and the pairing between them. Module A0.3."
- **Degrades:** controls + SVG + the default `why` readout are present in static markup; JS only enhances
  (`pick('why')` re-applies the already-default state). Respects `prefers-reduced-motion` globally; no browser storage.

### Footer build-stamp decoder (`#stamp`)

- **Stamp id:** `TSK0NgQDWY78BE` (in `#stampId`); panel `#st-ts` hard-codes "2026-06-03 17:31:57 UTC".
- **Pure functions:** `b62decode(s)` (base62 over `"0123…XYZabc…xyz"` → BigInt); `pad2(x)`;
  `decodeBranded(id)` — splits `ns = id.slice(0,3)` and `snow = b62decode(id.slice(3))`, then
  `ts = snow >> 22n`, `node = (snow >> 12n) & 0x3FFn`, `seq = snow & 0xFFFn`, with epoch
  `EPOCH_MS = 1704067200000`, formatting a UTC timestamp string. Fills `#st-ns`/`#st-snow`/`#st-node`/`#st-seq`/`#st-ts`.
  Toggle on click / Enter / Space sets `.open` and `aria-expanded`.

## References (`#refs`, verbatim)

Intro prose: "Primary sources for the foundations, and where the chapter connects."

**Sources**
- Hunt, A. & Thomas, D. — *The Pragmatic Programmer* — tracer bullets and tight feedback.
- Beck, K. — *Extreme Programming Explained* — small batches, short loops.
- Adzic, G. — *Specification by Example* — the spec as one living source of truth.

**Related in this course**
- A0.2.1 · The two-layer model → `/course/agile-agent-workflow/what/two-layer-model`
- A0.2.2 · The four artifacts → `/course/agile-agent-workflow/what/four-artifacts`
- A1 · Decomposition → `/course/agile-agent-workflow/why`

## Wiring

- **route-tag:** `/course/agile-agent-workflow/what` — matches the served route.
- **crumbs:** `Agile Agent Workflow` → `/course/agile-agent-workflow` · sep `/` · here `A0 · Foundations` (no link).
- **toc-mini:** `#modules` ("The three modules") · `#refs` ("References").
- **pager:** prev → `/course/agile-agent-workflow` ("← Course · Agile Agent Workflow"); next →
  `/course/agile-agent-workflow/what/two-layer-model` ("Start · the two-layer model →"). No `.p-left` text used.
- **footer (3-column "foot-cols", not the 2-script-only model):**
  - Chapters column links: `/course/agile-agent-workflow/what` ("A0 · Why an agile agent workflow"),
    `/course/agile-agent-workflow/why` ("A1 · Decomposition"); plus non-linked `.it` spans A2–A6.
  - The course column links: `/course/agile-agent-workflow`, `/course/agile-agent-workflow/what/two-layer-model`,
    `/elixir/course`, `/elixir`.
  - Brand links (header `.brand`, footer `.fbrand`) both point at `/elixir`.
- **Page meta:** `<title>` "A0 — Foundations · Agile Agent Workflow · jonnify"; `<meta description>` "Chapter A0,
  the foundations: why a pragmatic, story-led, agent-driven workflow works (why), the framework it runs on — two
  layers, four artifacts, one loop (what) — and the two roles that drive it (who)."
- Copy the head + header + 3-column footer + both trailing scripts verbatim from this page when authoring siblings.
