# A3.4.3 · Always live — dive 3

- **Route:** `/course/agile-agent-workflow/roadmap/thin-but-robust/always-live`
- **File:** `html/agile-agent-workflow/roadmap/thin-but-robust/always-live.html`
- **Numbering:** A3.4.3 (dive 3 of A3.4 · Thin but robust)
- **Accent:** elixir-purple
- **Model copied verbatim:** `html/agile-agent-workflow/roadmap/roadmap-anatomy/what-it-carries.html`
- **Stamp:** `TSK0Ng9hnHJgW0`

## Lead

The last property is the strictest: **always live**. Every rung leaves the dev node booting clean and serving —
`GET /health` answers `200` and the rung's route renders — so the mainline is never broken. A rung that lands red is
not done; it is a regression. This is the liveness criterion, and it is what makes a ladder of thin slices safe to
climb: each rung stands on a green one below it.

## Precise definition

- **The liveness criterion (verbatim):** every rung leaves the dev node booting clean and serving — `GET /health`
  answers `200` and the rung's route renders.
- **Green rung:** boots clean, `/health → 200`, the route renders, the harness passes. Done.
- **Red rung:** any of those fails. Not done; the mainline is broken until it is green again.
- **The invariant the chapter proves:** re-ordering rungs edits the roadmap, never a spec — and every ordering leaves
  the mainline green, because each rung is independently live.

## The worked Portal example

F6's nine rungs `f6.1…f6.9` each leave the node live. F6.1 boots and serves the root; F6.3 adds persistence and still
boots and serves; F6.6 adds live updates and still answers `/health → 200`. Break one — say a rung leaves a route
that fails to render — and the rung is red: it is reverted or fixed before the next begins. The ledger of rungs is
all-green by construction, which is what lets the roadmap re-order them freely.

## Hero interactive — the rung ledger (each rung leaves green)

- **id:** `ledgerPick` (`.solid-select`) or a range; `ledgerOut` (`.geo-readout`); SVG `class="ledger"` listing the
  nine rungs as a column of status cells.
- **Move:** step through the nine rungs f6.1…f6.9; for each, the ledger shows it boots clean, `/health → 200`, the
  route renders — all green — and the readout reports the live count. Buttons carry `data-c`.
- **Pure function:** `ledgerAt(n) -> {greenThrough, health, renders}` over a fixed nine-rung dataset; through rung n,
  all n rungs are green, `/health` is 200, the route renders.
- **Sample readout:** `through f6.5 · 5/9 rungs landed → all green · GET /health → 200 · the route renders. The mainline is never broken.`
- **Static default:** through f6.1 (1/9 green).

## Content interactive — break a rung → what fails

- **id:** `breakPick` (`.solid-select`), `breakOut` (`.geo-readout`), SVG `class="brk"`.
- **Move:** choose a way to break a rung (route fails to render / `/health` returns 500 / harness goes red / boot
  crashes); the readout names what the liveness check reports and why the rung is not done. Buttons carry `data-c`.
- **Pure function:** `breakRung(key) -> {live, health, signal}` over a fixed `BREAKS` dataset (break → the failing
  signal). Any break sets `live` false and names the gate that catches it.
- **Sample readout:** `break: /health returns 500 → NOT LIVE. The liveness check fails; the rung is a regression, reverted before the next begins.`
- **Static default:** the route-fails-to-render break.

## The bridge

- **principle:** Always live is the bar a rung clears to count as done — boots clean, `/health → 200`, the route
  renders — so the mainline is never broken and the ladder is safe to climb.
- **on the Portal:** every F6 rung holds it under the **master invariant** — the web layer calls only the `Portal`
  facade and renders only the closed `%Portal.Error{}` set — so a new rung adds a supervised child and a route, never
  a reason for the node not to boot.
- **take:** A rung is done only when it leaves the system live; a red rung is not a rung, it is a regression.

## References

- Continuous Delivery — https://continuousdelivery.com/
- The Pragmatic Programmer — https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/
- Extreme Programming Explained — https://www.oreilly.com/library/view/extreme-programming-explained/0201616416/

Related: thin-but-robust (hub), what-robust-adds (prev dive), why/correct, why/pragmatic/contracts, /elixir/phoenix.

## Wiring

- Crumbs end A3.4.3 · Always live.
- Route-tag rcur = `always-live`.
- Pager: prev `…/what-robust-adds`, next back to hub `/course/agile-agent-workflow/roadmap/thin-but-robust`.
