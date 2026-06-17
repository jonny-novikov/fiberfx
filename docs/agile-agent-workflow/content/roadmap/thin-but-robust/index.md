# A3.4 · Thin but robust — module hub

- **Route:** `/course/agile-agent-workflow/roadmap/thin-but-robust`
- **File:** `html/agile-agent-workflow/roadmap/thin-but-robust/index.html`
- **Numbering:** A3.4 (module hub of chapter A3 · The roadmap layer)
- **Accent:** elixir-purple (`<span class="ex">` in the `<h1>`, the `.cell.elix` bridge cell)
- **Model copied verbatim:** `html/agile-agent-workflow/roadmap/roadmap-anatomy/index.html`
- **Stamp:** `TSK0Ng9hnHJgW0` (reused verbatim with its decoder)

## Lead

The discipline at the centre of the method: each increment is a narrow vertical slice built to production quality —
supervised, contract-guarded, harnessed, and gated — never a prototype to be redone. This module draws the line
between **thin** and **flimsy**.

A backlog ordered into rungs (A2 → A3.3) still leaves one question open: what does a single rung have to *be* before
it counts as shipped? The wrong answer is "anything that demos". A slice that demos but has no test, no contract, and
no path to staying live is **flimsy** — it ships debt, not value, and it has to be redone. The right answer is a
**thin-but-robust** slice: a vertical thread that runs through every layer over the facade, with a contract guard, a
green harness, a gate, and the system still booting clean and serving after it lands.

## Precise definition

A candidate increment is **thin-but-robust** only when all five hold:

1. **Vertical** — it threads end to end through every layer (request → facade → render), not one horizontal layer in
   isolation.
2. **Over the facade** — it calls only the `Portal` facade and renders only the closed error set; it invents no
   domain logic and no new error vocabulary.
3. **Harnessed** — it ships a fast automated test (a `ConnTest`/`LiveViewTest`-style smoke) that needs no live
   browser.
4. **Gated** — verified routes, escaped interpolation, declared component attributes — a typo fails before it ships.
5. **Always live** — after it lands the node boots clean and serves (`GET /health` answers `200` and the rung's route
   renders).

Miss any one and it is **flimsy**: a shallow horizontal layer, an untested demo, or a thread that breaks the
mainline.

## The worked Portal example

The exemplar is the Portal's real web chapter **F6 (Phoenix)** and its `phoenix.roadmap.md`. F6.1 — "the engine
served as a web app (endpoint, request → facade → render)" — is the tracer bullet: a real thin feature, thin yet
robust, kept and grown. Its robustness comes from the seven "thin but robust for the web" properties named in the F6
roadmap: over the facade · harnessed · verified and safe · rendered in the system · honest real-time · supervised ·
always live.

## The framing interactive (hero `.fig`) — classify candidate increments

- **id:** `tbrPick` (`.solid-select`), `tbrOut` (`.geo-readout`), SVG `class="tbr"`.
- **Move:** select one of a fixed set of candidate increments; the readout marks it *thin-but-robust* or *flimsy* and
  names the failing test. Buttons carry `data-c`.
- **Pure function:** `classify(key) -> {verdict, reason}` over a fixed `CANDS` dataset. Each candidate carries five
  booleans (vertical, facade, harnessed, gated, live); `verdict` is `thin-but-robust` only when all five hold,
  otherwise `flimsy`, and `reason` names the first failing property.
- **Sample readout:** `f6.1 · the engine served as a web app → THIN-BUT-ROBUST. A vertical thread over the facade, harnessed by a ConnTest smoke, gated, and leaving the node live.`
- **Static default (degrade):** the f6.1 candidate, marked thin-but-robust.

## The `.mods` grid — three dives

- A3.4.1 `thin-not-shallow` — thin = a vertical slice, not a shallow horizontal layer; the line between thin and
  flimsy.
- A3.4.2 `what-robust-adds` — the seven F6 production properties that make a thin slice robust.
- A3.4.3 `always-live` — the liveness criterion: every rung leaves the system booting clean and serving.

## The bridge

- **principle:** A slice earns "robust" only when it is a vertical thread, contract-guarded, harnessed, gated, and
  leaving the system live — anything less is flimsy.
- **on the Portal:** every F6 rung holds the **master invariant** — the web layer calls only the `Portal` facade and
  renders only the closed `%Portal.Error{}` set — which is what keeps each thin slice robust.
- **take:** Thin is the size of a slice; robust is the bar it clears — and the master invariant is the bar.

## References

- Continuous Delivery — https://continuousdelivery.com/
- Extreme Programming Explained — https://www.oreilly.com/library/view/extreme-programming-explained/0201616416/
- The Pragmatic Programmer — https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/

Related in this course: roadmap-anatomy, why/correct, why/pragmatic/contracts, the chapter landing, /elixir/phoenix.

## Wiring

- Crumbs: jonnify (/elixir) → Agile Agent Workflow → A3 · The roadmap layer → A3.4 · Thin but robust (here).
- Route-tag rcur = `thin-but-robust`.
- Pager: prev `/course/agile-agent-workflow/roadmap`, next `…/thin-but-robust/thin-not-shallow`.
