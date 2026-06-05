# A3.6.3 · Independent cadence

- **Route:** `/course/agile-agent-workflow/roadmap/program-roadmap/independent-cadence`
- **File:** `html/agile-agent-workflow/roadmap/program-roadmap/independent-cadence.html`
- **Pager:** prev `…/one-core-many-surfaces` · next back to hub `…/program-roadmap`.

## Lead

Because the web (F6) and the bot (F10) are parallel surfaces over the same facade, neither depends on the other for
its core loop. So they are sequenced by product priority, not a hard dependency — and they ship on independent
cadences. The shared core is one delivery; each surface is a separate delivery. Re-ordering one surface's roadmap
leaves the other untouched.

## The grounding (verbatim)

From `portal.roadmap.md`: "F6 (web) and F10 (bot) are parallel surfaces over the same F5 facade — neither depends on
the other for its core loop, so they are sequenced by product priority, not by a hard dependency." And: "M2 and M3
are both surfaces over M1's facade; either can lead, and they can advance in parallel once the engine's near-term
slice is shipping." The one soft link is F10.8's webhook delivery, fronted by F6.1's endpoint — named, not a hard
ordering of the core loops.

## Hero interactive — two cadence timelines

- **id:** `tlPick` (`.solid-select`), buttons that select which timeline to read: `web` (`data-c="gold"`, active),
  `bot` (`data-c="blue"`), `both` (`data-c="sage"`).
- **SVG:** `id="tlSvg"` — two parallel timelines, web rungs (f6.1…) on one row, bot rungs (f10.1…) on another, both
  feeding a single shared facade band beneath; the selected timeline lit.
- **Pure function:** `cadenceView(which)` → `{which, rungs, ship, sharedFacade:true}` over a fixed `CADENCE` dataset
  (web ships catalog → live → users; bot ships answer → identity → browse/enroll/learn).
- **Readout id:** `tlOut`. Static default (web): `Web (F6) cadence: f6.1 catalog → f6.6 live → f6.8 users · ships on
  its own schedule over the shared facade. The bot ships on its own cadence in parallel.`
- **Move:** read each surface's cadence over the one shared facade.

## Content interactive — reorder one surface (the other is untouched)

- **id:** `reSurface` (`.solid-select`), buttons `web` (`data-c="gold"`, active), `bot` (`data-c="blue"`); plus a
  reorder control (`reMove`) — buttons `advance` / `defer` on the selected surface's next rung.
- **SVG:** `id="reSvg"` — two rows of rung chips; the selected surface's row reorders, the other row stays fixed; a
  "other surface edits" counter and a "core edits" counter, both held at 0.
- **Pure function:** `reorderImpact(surface, move)` → `{surface, otherSurfaceEdits:0, coreEdits:0,
  specEdits:0}` over the fixed `CADENCE` dataset. Re-ordering one surface's roadmap edits that surface's roadmap
  only — the other surface and the core are untouched, and no spec is edited.
- **Readout id:** `reOut`. Static default (web/advance): `Reorder web (advance next rung) · web roadmap edited ·
  other-surface edits: 0 · core edits: 0 · spec edits: 0. Each cadence is its own.`
- **Move:** advance/defer a rung on one surface; the other-surface, core, and spec counters all hold at 0.

## Bridge

- **Principle:** independent cadence — surfaces over one core ship on their own schedules, sequenced by product
  priority, and re-ordering one leaves the others untouched.
- **Portal practice:** "call only the facade" — because the web (F6) and bot (F10) each call only the `Portal` facade
  and render only the closed error set, each surface's roadmap is independent; re-ordering F6's rungs edits no F10
  rung and no core code.
- **Take:** the master invariant lets two roadmaps run on independent cadences over one shared core.

## References — Sources

- Continuous Delivery — https://continuousdelivery.com/
- Extreme Programming Explained — https://www.oreilly.com/library/view/extreme-programming-explained/0201616416/
- The Pragmatic Programmer — https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/
