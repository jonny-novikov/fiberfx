# A3.6.1 · Roadmap of roadmaps

- **Route:** `/course/agile-agent-workflow/roadmap/program-roadmap/roadmap-of-roadmaps`
- **File:** `html/agile-agent-workflow/roadmap/program-roadmap/roadmap-of-roadmaps.html`
- **Pager:** prev hub `…/program-roadmap` · next `…/program-roadmap/one-core-many-surfaces`.

## Lead

A backlog of stories rolls up into a chapter roadmap; a set of chapter roadmaps rolls up into a program roadmap.
There are three levels of planning, each with its own unit and its own artifact: program (the chapter,
`portal.roadmap.md`), chapter (the rung, `phoenix.roadmap.md`), and rung (the story/spec, `f6.N.md`). The program
roadmap is the roadmap of roadmaps: it sequences whole chapters into program milestones and hands each chapter off
to its own roadmap for rung-level detail.

## The three levels (verbatim grounding)

From `portal.roadmap.md`: the Portal is one domain core surfaced through several adapters; the file "sequences the
chapters that build it … into program milestones … and hands off to each chapter's own roadmap for rung-level
detail." Its program-at-a-glance table lists F4 (branded store), F5 (the engine), F6 (the web), F7–F9 (multi-runtime,
reserved), F10 (the Telegram bot). Its program milestones: M1 · the engine (F5), M2 · the web platform (F6), M3 ·
the bot (F10), M4 · the multi-runtime platform (F7–F9).

A program milestone groups chapters the way a chapter milestone groups rungs. The unit zooms by one level at each
step: program → chapter → rung.

## Hero interactive — zoom the levels

- **id:** `zoomPick` (`.solid-select`), buttons `program` (`data-c="elixir"`, active), `chapter` (`data-c="gold"`),
  `rung` (`data-c="sage"`).
- **SVG:** `id="zoomSvg"` — three nested frames; the selected level's frame lit, its unit named.
- **Pure function:** `levelView(level)` → `{name, unit, artifact, example}` over a fixed `LEVELS` dataset.
- **Readout id:** `zoomOut`. Static default (program): `Program · unit: the chapter · artifact: portal.roadmap.md ·
  example: sequence F4 store → F5 engine → F6 web · F10 bot → F7–F9 multi-runtime.`
- **Move:** zoom across the three planning levels and name each one's unit + artifact.

## Content interactive — the program milestone grouper

- **id:** `groupPick` (`.solid-select`), buttons per chapter: `f5` (`data-c="sage"`, active), `f6`
  (`data-c="gold"`), `f10` (`data-c="blue"`), `f79` (`data-c="elixir"`).
- **SVG:** `id="groupSvg"` — four chapter chips above the four program milestones M1–M4; the picked chapter's
  milestone lit.
- **Pure function:** `milestoneOf(chapter)` → `{chapter, milestone, capability, specEdits:0}` over fixed
  `PROGRAM` dataset. A "spec edits" counter holds at 0 — re-grouping chapters into milestones edits the program
  roadmap, never a chapter spec.
- **Readout id:** `groupOut`. Static default (F5): `F5 · the engine → M1 · The engine · capability: a correct,
  recoverable learning engine behind the facade · spec edits: 0.`
- **Move:** assign a chapter to its program milestone; the spec-edits counter proves grouping edits no spec.

## Bridge

- **Principle:** plan in levels — a program roadmap sequences chapters into milestones; it does not restate a
  chapter's rungs, and grouping chapters edits no chapter spec.
- **Portal practice:** `portal.roadmap.md` sequences F4 → F5 → F6 · F10 → F7–F9 into M1–M4; each chapter is handed
  off to its own roadmap (`phoenix.roadmap.md`, `f10.roadmap.md`); "call only the facade" is the seam that keeps the
  hand-off clean.
- **Take:** the program roadmap is the roadmap of roadmaps — it orders chapters; each chapter's roadmap orders its
  own rungs.

## References — Sources

- Continuous Delivery — https://continuousdelivery.com/
- The Pragmatic Programmer — https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/
- Extreme Programming Explained — https://www.oreilly.com/library/view/extreme-programming-explained/0201616416/
