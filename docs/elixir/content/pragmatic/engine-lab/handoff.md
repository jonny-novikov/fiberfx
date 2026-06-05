# F5.09.3 — What ships in F6 (dive)

- Route (served): `/elixir/pragmatic/engine-lab/handoff`
- File: `elixir/pragmatic/engine-lab/handoff.html`
- Place in the chapter: third and last of the dives under the F5.09 lab, and the close of F5 · Pragmatic Programming. After the engine is assembled (F5.09.1) and mounted behind a LiveView sketch (F5.09.2), this dive states the handoff — what F6 inherits unchanged, what it replaces, and the chapter's definition of done.
- Accent: burgundy (the F5 · Pragmatic Programming chapter accent; `--burgundy:#c4504c`). The interactive uses the F5.09.3 gold (`#f0cd7f` / `#d4a85a`) to match its dive-card border.
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F5.09 · part 3 of 3`

H1 (verbatim): What ships in F6

Hero lede (verbatim):

> F6 brings Phoenix. The temptation is to treat that as a rewrite, but the whole point of the boundary is that it is not. F6 **replaces** one thing — the thin web layer — with Phoenix and LiveView, and adds the Phoenix endpoint to the same supervision tree. Everything else is **kept**: the `Portal` facade is called unchanged, the closed `%Portal.Error{}` contract is the render surface, the engine and store behind the port are untouched, and the F5.07 tests carry over because they were written against the facade, not the web. The handoff is small on purpose: a stable boundary means the next chapter inherits a working engine and only has to dress it.

Kicker (verbatim):

> Three things F6 builds on. Select one to see what F6 does with it.

## Sections

In order:

1. `#inherits` — What F6 inherits (teaching). The three pieces that cross the chapter boundary intact — facade, error contract, supervision tree; carries the interactive inherited-piece figure.
2. `#kept` — Kept and replaced. Only the web layer (`Plug`/`Bandit` → Phoenix LiveView) is replaced; carries the replaced-vs-kept diagram.
3. `#endpoint` — The endpoint joins the tree. The one change to the assembly: adding `PortalWeb.Endpoint` as a child of the F5.09.1 tree.
4. `#done` — The chapter is done (advanced/closing). The F5 definition of done as one paragraph, a bridge from F5 to F6, and the closing note.

Running example: the F5 → F6 boundary on the Portal — the `Portal` facade (`enroll/2`, `deliver_lesson/2`, `progress_of/1`), the closed `%Portal.Error{}` set, the `Portal.Application` tree, and the F5.07 tests.

Real Elixir code shown:

- `Portal.Application.start/2` (F6 form) — `children = [Portal.EventStore.adapter(), {Portal.Engine, []}, PortalWeb.Endpoint]` with the comments `kept from F5.09.1`, `kept from F5.09.1`, `NEW in F6: the Phoenix endpoint, supervised alongside`, then `Supervisor.start_link(children, strategy: :one_for_one, name: Portal.Supervisor)`.

## The interactives

One interactive figure plus one static diagram.

### Inherited-piece figure — `What F6 builds on · select one` (`#hfTitle`)

- `<figure class="fig">` labelled by `hfTitle`.
- Control group id `hfSel` (`role="group"`, `aria-label="Inherited piece"`), three buttons with `data-k`: `facade` (active default, `the facade`), `errors` (`the error contract`), `tree` (`the supervision tree`).
- SVG (`viewBox="0 0 720 200"`) draws three highlightable rows: `hfRow_facade` (`THE FACADE · Portal`, `enroll/2 · deliver_lesson/2 · progress_of/1 — called unchanged`, side label `kept`, default gold-highlighted), `hfRow_errors` (`THE ERROR CONTRACT · %Portal.Error{}`, `a closed set of codes — the UI render surface`, side label `kept`), `hfRow_tree` (`THE SUPERVISION TREE · Portal.Application`, `engine + store — F6 adds the endpoint as a child`, side label `extended`).
- Pure function `pick(k)`: toggles active button, recolours the matching row to gold (`#d4a85a` stroke, `#241d10` fill), and writes the readout/role/result from the `ITEMS` table.
- Readout id `hfOut` (`aria-live="polite"`) renders `<b>{name}</b> — {detail}. {desc}`. Role id `hfRole`, result id `hfResult`. VERBATIM item data:
  - `facade` → name `the facade`, detail `F6 calls it unchanged`, desc: `The Portal context is the API F6 calls. A Phoenix controller or LiveView invokes enroll/2, deliver_lesson/2, progress_of/1 exactly as the sketch does — the signatures do not move, so no caller is rewritten.`
  - `errors` → name `the error contract`, detail `F6 renders the closed set`, desc: `The closed %Portal.Error{} set is the UI render surface. F6 branches on the same codes the lab defined, attaching field errors to inputs and other failures to flashes — the rendering stays total.`
  - `tree` → name `the supervision tree`, detail `F6 adds the endpoint as a child`, desc: `The Portal.Application tree from F5.09.1 gains one child: PortalWeb.Endpoint. The engine and store entries are unchanged and the one_for_one strategy now supervises the web layer alongside them.`
- Static markup defaults: role `the facade`, result `F6 calls it unchanged`.

### Boundary diagram — `At the F5 → F6 boundary` (`#hfKeptTitle`)

Static SVG (`viewBox="0 0 720 230"`): a `REPLACED` column holding `WEB LAYER` (`Plug/Bandit → Phoenix LiveView`), and a `KEPT` column (gold) holding four boxes — `the facade · Portal`, `the engine + store`, `the error contract`, `the F5.07 tests`.

Degrade behaviour: the inherited-piece figure ships with `facade` pre-marked `active` and `hfRole`/`hfResult` defaults in markup; `pick('facade')` runs on load. The boundary diagram is static. References and other `.reveal` sections are visible without JS; `prefers-reduced-motion: reduce` disables the reveal transition. No per-figure motion beyond reveal.

Footer build-stamp: id `TSK0Nd9oQe77ei` (namespace `TSK`); the panel's `st-ts` decodes to `2026-06-01 18:19:34 UTC`. Decoder as on the hub (base62 snowflake; timestamp `>> 22` over epoch `1704067200000`, node `>> 12 & 0x3FF`, seq `& 0xFFF`).

## References (#refs, verbatim)

Intro line: `Primary sources for this lesson, and where it connects in the course.`

Sources:

- `https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html` — Phoenix — Phoenix.LiveView — server-rendered, stateful UI over the engine.
- `https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html` — Phoenix — Phoenix.Component (HEEx) — function components and the HEEx template.
- `https://hexdocs.pm/elixir/Supervisor.html` — Elixir — Supervisor — the engine runs under a supervision tree.

Related in this course:

- `/elixir/pragmatic/boundaries` — F5.08 · Boundaries & integration seams
- `/elixir/pragmatic/state/supervision` — F5.06 · Supervision & restart
- `/elixir/language/otp/supervisors` — F3.08 · Supervisors

## Wiring

- route-tag (verbatim): `<a href="/elixir">elixir</a>` / `<a href="/elixir/pragmatic">pragmatic</a>` / `<a href="/elixir/pragmatic/engine-lab">engine-lab</a>` / `<span class="rcur">handoff</span>`.
- crumbs (verbatim): `F5` (→ `/elixir/pragmatic`) `/` `F5.09` (→ `/elixir/pragmatic/engine-lab`) `/` `handoff` (here).
- toc-mini: `#inherits` What F6 inherits · `#kept` Kept and replaced · `#endpoint` The endpoint joins the tree · `#done` The chapter is done.
- pager: prev → `/elixir/pragmatic/engine-lab/mount` label `F5.09.2 · mount`; next → `/elixir/pragmatic/engine-lab` label `Back to F5.09`.
- footer: column **Chapters** — `/elixir/algebra`, `/elixir/functional`, `/elixir/language`, `/elixir/algorithms`, `/elixir/pragmatic`, `/elixir/phoenix` (F1–F6). Column **The course** — `/elixir`, `/elixir/course`, `/elixir/algebra/functions`. Same foot-tag as the hub.
- Page meta — `<title>`: `What ships in F6 — F5.09.3 · jonnify`. `<meta description>`: `The handoff: F6 replaces the thin web layer with Phoenix and adds its endpoint to the same supervision tree, but the Portal facade is called unchanged, the closed %Portal.Error{} contract is the render surface, the engine and store are untouched, and the F5.07 tests carry over. The chapter's definition of done, closed.`

## Build instruction

To rebuild this page, copy the `<head>…</style>`, the `<header class="site">`, the `<footer class="site-foot">`, and both trailing `<script>` blocks verbatim from a recent built sibling on this burgundy chapter — the model sibling is `elixir/pragmatic/engine-lab/mount.html` (same lab, same accent, identical stamp/reveal/`solid-select` machinery; this dive only re-colours the figure to the F5.09.3 gold). Change only the `<title>`/`<meta description>`, the `route-tag` (ending in `<span class="rcur">handoff</span>`), and the `<main>` body (hero, `#inherits`, `#kept`, `#endpoint`, `#done`, references, pager). No-invent guards: use only the real Portal surfaces as written — the `Portal` facade (`enroll/2`, `deliver_lesson/2`, `progress_of/1`) called unchanged, the closed `%Portal.Error{}` render surface, the `Portal.Application` tree gaining exactly one child (`PortalWeb.Endpoint`) under the same `:one_for_one`, the untouched engine/store behind the port, and the carried-over F5.07 tests; the Phoenix web app is the only thing F6 adds — cite `Phoenix.LiveView`/`Supervisor` rather than re-teaching OTP. Voice rules: no first person, no exclamation marks, no emoji, and none of just/simply/obviously.
