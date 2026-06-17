# A3.8.3 · The program view (dive)

- **Route:** `/course/agile-agent-workflow/roadmap/workshop/the-program-view`
- **File:** `html/agile-agent-workflow/roadmap/workshop/the-program-view.html`
- **Accent:** elixir-purple. **Stamp:** `TSK0Ng9hnHJgW0`.
- **Model copied:** `html/agile-agent-workflow/roadmap/roadmap-anatomy/what-it-carries.html` (lesson).

## Lead

A chapter roadmap plans one surface. A program roadmap plans the whole system: several surfaces over one core. Apply
A3.6 (the program roadmap): the web (F6) and the bot (F10) are parallel surfaces over the one `Portal` facade, each a
roadmap of its own, shipping on independent cadences. The master invariant is the seam that decouples them. This is
the delivery plan Part VII (A7) executes.

## Worked Portal example (from portal.roadmap.md)

The Portal is one domain core behind one facade, surfaced through several adapters. The web (F6) and the bot (F10)
are parallel surfaces over the same `Portal` facade — neither depends on the other for its core loop, so they are
sequenced by product priority, not a hard dependency, and ship on independent cadences. The master invariant is the
decoupling seam: every surface calls only the facade and renders only the closed error set, so adding a surface adds
a roadmap of its own and never changes the core. (F7–F9 multi-runtime are reserved, not designed.)

## Hero (framing) interactive — the program-milestone view across surfaces

- **Move:** select a surface (web F6 / bot F10) or the core; the readout names that surface's roadmap and the fact
  that it ships on its own cadence over the one facade.
- **Control ids:** `.solid-select#progPick` buttons `data-k=core|web|bot`, `data-c=elixir|blue|sage`.
- **SVG:** a hub-and-spoke — the `Portal` facade core in the centre, web and bot surfaces as spokes, each labelled
  with its roadmap; the selected node lights.
- **Readout id:** `#progOut`. Static default = core.
- **Pure function:** `surfaceView(key) -> {name, roadmap, cadence}` over `SURFACES`.
- **Sample readout:** `Core — the Portal facade: one domain core, one facade. Surfaces over it: web (phoenix.roadmap.md, F6) and bot (f10.roadmap.md, F10), each a roadmap of its own, shipping on independent cadences.`

## Content interactive — the shared-facade seam (master invariant decouples cadence)

- **Move:** toggle whether each surface "calls only the facade"; when both hold the invariant, a decoupled-cadence
  readout shows surfaces ship independently; if a surface is imagined to reach below the facade, the readout shows the
  cadences couple — demonstrating the invariant IS the seam.
- **Control ids:** `.solid-select#seamPick` buttons `data-k=both|webonly` (both hold the invariant / web reaches
  below), `data-c=sage|gold`. (Two states; the point is the invariant as the seam.)
- **SVG:** two surface boxes connected to the facade; a band shows "decoupled cadence" (green) or "coupled" (gold)
  per state.
- **Readout id:** `#fcOut`. Static default = both hold the invariant → decoupled.
- **Pure function:** `cadenceCoupling(key) -> {coupled, why}` over `STATES`.
- **Sample readout:** `Both surfaces call only the facade — cadences decoupled: web (F6) and bot (F10) ship independently; adding a surface adds a roadmap and never changes the core.`

## pre.code — the program roadmap fragment (markdown, NOT Elixir)

A fragment naming the core, the two surface roadmaps, their independent cadence, and the invariant as seam.

## NOTE: do NOT add an href to /portal or /spec (unbuilt). Refer to Part VII (A7) in prose only.

## Bridge

- **idea:** "call only the facade" is the rule that keeps each surface's roadmap independent of the others — the
  master invariant as the decoupling seam.
- **practice:** on the Portal the web (F6) and bot (F10) are parallel surfaces over the one facade; because each calls
  only the facade and renders only the closed error set, they ship on independent cadences and the core never
  changes.
- **take:** one core, many surfaces — the facade rule lets each surface's roadmap run on its own cadence.

## Pager

- prev `/course/agile-agent-workflow/roadmap/workshop/choose-the-tracer`
- next (back to hub) `/course/agile-agent-workflow/roadmap/workshop`

## References / Related — registry URLs; hub, choose-the-tracer, A3.3 roadmap-anatomy, A3 the-road-ahead, A3 roadmap, /elixir/phoenix.
