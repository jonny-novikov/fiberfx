# A3.2.2 · Incremental design — `/roadmap/xp-small-batches/incremental-design`

- **File:** `html/agile-agent-workflow/roadmap/xp-small-batches/incremental-design.html`
- **Pager:** prev `…/small-releases` · next `…/continuous-feedback`

## Lead

The second XP practice: design grows one rung at a time. Incremental design adds only the structure the current
slice needs, leaving the rest until a slice requires it. The opposite — designing the whole system up front —
is the big-bang the course argues against: it bets correctness on a plan no slice has yet exercised.

## Definition

- **incremental design** — the design is grown rung by rung; each rung adds only what its slice needs.
- **stable seam** — a fixed boundary (a facade) the increments hang off, so adding structure never changes what
  is below it.
- **deferred decision** — a design choice held open until a rung forces it, recorded as an open decision until
  then.

## Worked Portal example

F6 grows the web design one rung at a time behind one master invariant: "the web layer calls only the `Portal`
facade and renders only `%Portal.Error{}`." F6.1 adds only `PortalWeb.Endpoint` to the F5 supervision tree.
PubSub and Presence are not added until F6.7 — "later rungs add `Phoenix.PubSub` and `Phoenix.Presence` only as
the real-time features require them." Authentication, deployment, and the dashboard are open decisions until
F6.8–F6.9 force them. The design is never drawn ahead of a slice that needs it.

## Hero interactive — the design grows behind a facade

A facade line with the engine below it (never changing) and the web design above it. Add rungs one at a time;
the readout reports how many web pieces exist, what is below the facade (always 1: the engine), and which
decisions are still open at this rung.

- Control: `#idRung` range 1..9 (or buttons), advancing the rung.
- Pure: `piecesAt(rung)`, `openDecisionsAt(rung)`, `belowFacade()` (constant 1).
- Readout `#idOut`: "At F6.N: K web pieces added · engine below the facade unchanged · D decisions still open. …"

## Content interactive — up-front vs incremental design cost

A second figure: choose "design all up front" or "grow incrementally" and the readout reports the count of
design decisions made before the first slice ships, and how many of those a later rung would have changed —
proving up-front design pays for decisions no slice has tested.

- Control: `#idMode` segmented buttons (up-front / incremental).
- Pure: `decisionsBeforeFirstShip(mode)`, `wouldChange(mode)`.
- Readout `#idModeOut`.

## Bridge

- **Principle (XP):** Incremental design — add only the structure the current slice needs; defer the rest.
- **On the Portal (F6):** Each rung adds web surface behind the unchanged facade; PubSub, auth, and the
  dashboard are deferred to the rung that needs them, recorded as open decisions until then.
- **Take:** The design is grown, not drawn — one rung's worth at a time, behind a seam that keeps the engine
  below it untouched.

## Sources

- Extreme Programming Explained → https://www.oreilly.com/library/view/extreme-programming-explained/0201616416/
- Continuous Delivery → https://continuousdelivery.com/
- The Pragmatic Programmer → https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/
