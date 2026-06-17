# A3.6 · The program roadmap — module hub

- **Route:** `/course/agile-agent-workflow/roadmap/program-roadmap`
- **File:** `html/agile-agent-workflow/roadmap/program-roadmap/index.html`
- **Role:** module hub (A3.6). Accent: elixir-purple. Stamp `TSK0Ng9hnHJgW0`.
- **Pager:** prev `/course/agile-agent-workflow/roadmap` · next `…/program-roadmap/roadmap-of-roadmaps`.

## Lead

A chapter roadmap orders rungs. Above it sits one more altitude: the **program roadmap**, which orders whole
*chapters* into program milestones. The Portal is one domain core behind one `Portal` facade, surfaced through
several adapters — a web app (F6) and a Telegram bot (F10) are parallel surfaces over that one facade. Each surface
is a roadmap of its own; both ship on independent cadences. The program roadmap sequences those chapters, and the
master invariant is the seam that keeps each surface's roadmap independent of the others.

## Precise framing

Two levels of planning, named by their unit:

- **Program** — the planning unit is the **chapter** (and its program milestones). The program roadmap
  (`portal.roadmap.md`) sequences chapters: F4 store → F5 engine → F6 web · F10 bot → F7–F9 multi-runtime.
- **Chapter** — the planning unit is the **rung**. A chapter roadmap (`phoenix.roadmap.md`) sequences nine rungs
  `f6.1…f6.9` into three milestones, each pointing at a spec, none defining behaviour.

The program view's grounding facts (verbatim from `portal.roadmap.md`): the web (F6) and the bot (F10) are parallel
surfaces over the same `Portal` facade; neither depends on the other for its core loop, so they are sequenced by
product priority, not a hard dependency, and they ship on independent cadences. The master invariant threads through
every chapter — every surface calls only the facade and renders only the closed error set, so adding a surface adds
a roadmap of its own and never changes the core.

## Framing interactive (hero `.fig`) — the level switch

- **id:** `lvlPick` (`.solid-select`), buttons `program` (`data-c="elixir"`, active), `chapter`
  (`data-c="gold"`).
- **SVG:** `id="lvlSvg"`, two stacked bands — a "program" band showing chapters, a "chapter" band showing rungs;
  the selected level lit.
- **Pure function:** `planningUnit(level)` → `{level, unit, sequences, artifact}` over a fixed `LEVELS` dataset.
- **Readout id:** `lvlOut`. Static default (program): `Program level · the planning unit is the chapter · sequences
  whole chapters (F4 store → F5 engine → F6 web · F10 bot → F7–F9) into program milestones · artifact:
  portal.roadmap.md.`
- **Move:** names the planning unit at each level — chapter at program level, rung at chapter level.

## `.mods` grid — the three dives

1. **A3.6.1 · Roadmap of roadmaps** → `roadmap-of-roadmaps` — the program roadmap sequences chapters into program
   milestones, not rungs; the levels of planning (program → chapter → rung).
2. **A3.6.2 · One core, many surfaces** → `one-core-many-surfaces` — one domain core behind one `Portal` facade,
   surfaced through several adapters; web (F6) and bot (F10) as parallel surfaces; the master invariant is what makes
   them independent.
3. **A3.6.3 · Independent cadence** → `independent-cadence` — each surface ships on its own cadence, sequenced by
   product priority not a hard dependency; shared core, separate delivery.

## Bridge (the module's concept)

- **Principle:** a program of many surfaces stays plannable when each surface's roadmap is independent of the
  others — sequenced by product priority, not by a hard dependency.
- **Portal practice:** "call only the facade" — every surface calls only the `Portal` facade and renders only the
  closed error set, so web (F6) and bot (F10) each carry a roadmap of their own and ship on independent cadences.
- **Take:** the program roadmap orders chapters; the master invariant is the seam that keeps each surface's roadmap
  its own.

## References — Sources (real, vetted)

- Continuous Delivery — https://continuousdelivery.com/
- Extreme Programming Explained — https://www.oreilly.com/library/view/extreme-programming-explained/0201616416/
- The Pragmatic Programmer — https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/

Related in this course: the three dives; `/course/agile-agent-workflow/roadmap/roadmap-anatomy`;
`/course/agile-agent-workflow/why/two-layers`; `/course/agile-agent-workflow/roadmap`; `/elixir/phoenix`;
`/elixir/course`.
