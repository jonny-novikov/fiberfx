# A3.6.2 · One core, many surfaces

- **Route:** `/course/agile-agent-workflow/roadmap/program-roadmap/one-core-many-surfaces`
- **File:** `html/agile-agent-workflow/roadmap/program-roadmap/one-core-many-surfaces.html`
- **Pager:** prev `…/roadmap-of-roadmaps` · next `…/independent-cadence`.

## Lead

The Portal is one domain core behind one `Portal` facade, surfaced through several adapters. The web (F6) and the
bot (F10) are parallel surfaces over that one facade — a LiveView, a bot handler, a future worker, each an adapter.
The master invariant is what makes them independent: every surface calls only the facade and renders only the closed
error set, so adding a surface adds a roadmap of its own and never changes the core.

## The shape (verbatim grounding)

From `portal.roadmap.md`: "There is one domain core, framework-free, behind a single facade (`Portal`); every
surface — a LiveView, a bot handler, a future worker — calls only that facade and renders only the closed
`%Portal.Error{}` set. The program grows by adding surfaces and capabilities over the unchanged core, never by
reaching into it." And: "F6 (web) and F10 (bot) are parallel surfaces over the same F5 facade — neither depends on
the other for its core loop."

The master invariant (the one place A3 names `Portal.Engine`/`%Portal.Error{}`, verbatim):

> The web layer calls only the `Portal` facade and renders only the closed `%Portal.Error{}` set. No controller,
> LiveView, plug, or template names `Portal.Engine`, a repo, or `GenServer.call`.

## Hero interactive — the core-and-surfaces map

- **id:** `mapPick` (`.solid-select`), buttons per surface: `web` (`data-c="gold"`, active), `bot`
  (`data-c="blue"`), `worker` (`data-c="sage"`).
- **SVG:** `id="mapSvg"` — a central core/facade node with three adapter nodes (web, bot, future worker) connected
  through one facade band; the picked surface lit, all routed through the same facade.
- **Pure function:** `surfaceView(surface)` → `{surface, chapter, adapter, callsFacadeOnly:true}` over a fixed
  `SURFACES` dataset.
- **Readout id:** `mapOut`. Static default (web): `Web (F6) · adapter: LiveView/HEEx · calls only the Portal facade ·
  renders only the closed error set. One core, surfaced — the core is untouched.`
- **Move:** map each surface to its adapter and confirm all route through the one facade.

## Content interactive — toggle a surface (the core is unchanged)

- **id:** `toggleSet` (`.solid-select`), buttons that add/remove a surface: `web` (`data-c="gold"`, active),
  `bot` (`data-c="blue"`), `worker` (`data-c="sage"`). Each click toggles that surface present/absent.
- **SVG:** `id="toggleSvg"` — the core node fixed, surfaces appear/disappear; a "core changes" counter band.
- **Pure function:** `coreImpact(activeSet)` → `{surfaces:n, coreChanges:0, masterInvariant:'holds'}` over the fixed
  set. The "core changes" counter holds at 0 regardless of which surfaces are present — adding or removing a surface
  changes no core code, because every surface calls only the facade.
- **Readout id:** `toggleOut`. Static default (web on): `Surfaces present: 1 (web) · core changes: 0 · master
  invariant: holds. Toggle a surface on or off — the core is unchanged.`
- **Move:** add or remove a surface; the core-changes counter proves the core is unchanged.

## Bridge

- **Principle:** one core, many surfaces — a surface is an adapter over the core, added without reaching into it.
- **Portal practice:** "call only the facade" — the master invariant; the web (F6) and bot (F10) each call only the
  `Portal` facade and render only the closed error set, so each is independent of the others and of the core's
  internals.
- **Take:** the master invariant is the decoupling seam — add a surface, add a roadmap; the core never changes.

## References — Sources

- The Pragmatic Programmer — https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/
- Continuous Delivery — https://continuousdelivery.com/
- Extreme Programming Explained — https://www.oreilly.com/library/view/extreme-programming-explained/0201616416/
