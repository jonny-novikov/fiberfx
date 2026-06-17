# A2.07.3 · Order the backlog

- **Route:** `/course/agile-agent-workflow/decomposition/workshop/order-the-backlog`
- **File:** `html/agile-agent-workflow/decomposition/workshop/order-the-backlog.html`
- **Role:** dive 3 of the workshop, and the A2 capstone close. The *when* of the decomposition: order the nine
  real F6 rungs into three dependency-ordered milestones, runnable at each rung; then read the git history of
  how the specs evolved over time (spec → build → reconcile).
- **Accent:** elixir-purple.
- **Grounding:** the Portal's REAL F6 web decomposition (the `/elixir/phoenix` chapter). All milestone rows,
  the F6.5-US0 story, the dates, and the commit hashes are quoted **verbatim** from
  `docs/elixir/content/phoenix/index.md` (§ "The three milestones" + § "The git evolution timeline") and
  `docs/elixir/content/phoenix/rungs.md` (§ F6.5). No-invent is relaxed to the real F6 API as written in source.

## Lead

The nine F6 rungs are written and proven on the hub; a list of nine is not a plan. This dive supplies the two
things that turn it into one — an **order** and a **history**. First the value ladder groups the rungs into three
dependency-ordered milestones, each runnable at its end: **M1 ship the catalog (F6.1–F6.5) · M2 make it live
(F6.6–F6.7) · M3 ship to users (F6.8–F6.9)**, with the shipped/specified frontier sitting after F6.6. Then the
git timeline replays how the specs got there — written up front, built one rung at a time, and reconciled as each
shipped rung fed the next. The cadence is **spec → build → reconcile**, and the spec is the moving source of truth.

## The two ideas

1. **The value-ladder ORDER (the three milestones).** The nine rungs group into three milestones that depend only
   downward and stay runnable at each end. Verbatim from `index.md` "The delivery arc":

   | Milestone | Rungs | What you can do at the end |
   |---|---|---|
   | 1 · Ship the catalog | F6.1–F6.5 | browse a persistent catalog and add courses, server-rendered, with inline errors |
   | 2 · Make it live | F6.6–F6.7 | search and create without reloads; every client updates live with a viewer count |
   | 3 · Ship to users | F6.8–F6.9 | sign in, run behind auth on a deployed clustered release, watch an operations dashboard |

   The downward dependency: F6.5 renders what F6.3/F6.4 make queryable; F6.6 makes F6.5's pages live; F6.9 composes
   all of it. The arc is the first deployable product first, then layer interactivity, real-time, and operations on
   top. Six rungs (F6.1–F6.6) are shipped; three (F6.7–F6.9) are specified — the frontier falls after F6.6.

2. **The spec → build → reconcile CADENCE over git time.** Specs written 02 Jun; F6.1 shipped 03 Jun; F6.2–F6.5 +
   the reconciles 04 Jun; F6.6 shipped 05 Jun; F6.7–F6.9 reconciled forward. Feedback edits the spec (the single
   source of truth), not the code below the facade — the move A1.03.3 named. The clearest spec-edit is the F6.5
   route reconcile `5a440fd`: `/courses` = catalog, `/my/courses` = enrollments, driven by **F6.5-US0** (the
   architect story).

## Verbatim facts (do not invent a date or a hash)

The git evolution timeline (verbatim from `index.md` § "The git evolution timeline"):

| Date | Commit | What changed |
|---|---|---|
| 02 Jun | `d2f959d` | the nine f6.N specs written — the whole ladder specced up front |
| 03 Jun | `470cd90` | **F6.1 built** |
| 04 Jun | `c98dabe` | F6.2 reconciled to the as-built F6.1, F6.1 marked shipped (the lag-1 reconcile) |
| 04 Jun | `98ef445` | F6.3 spec remediated to branded-string-surface / `:bigint`-column identity; F6.2 marked shipped |
| 04 Jun | `5a440fd` | **F6.5 reconcile** — `/courses` = catalog, `/my/courses` = enrollments (resolves a route collision) |
| 04 Jun | `47a15f1` | F6.6–F6.9 backlog groomed — the F6.5 direction folded forward into each downstream spec |
| 04 Jun | `0911b4d` | Specification-by-Example applied to the F6.6–F6.9 stories |
| 05 Jun | `3cf2480` | **F6.6 built** |
| 05 Jun | `706df05` | F6.6 feedback loop: Stage 6 reconcile of F6.7–F6.9 (re-grounded against shipped F6.6) |

**F6.5-US0** (the architect story that drove the route reconcile — verbatim from `rungs.md` § F6.5):

> As an **architect**, I want each URL named after the resource it returns, so that the catalog and a learner's
> enrollments stop colliding on `/courses`.

## Hero interactive — the milestone ladder (ordering view)

**Order the rungs into milestones.** Select a milestone (M1 / M2 / M3). The figure shows the nine rungs grouped
into three bands; selecting one highlights its rungs and what a role can do at its end. The readout prints the
verbatim milestone row from `index.md`, plus the factual shipped/specified count for that milestone and the
downward dependency it rests on. This is the ORDER view — structure, not time.

- control ids: `#otbMs` (segmented, `data-ms` = 1|2|3)
- pure function: `milestoneReadout(m) -> string` over the fixed three-milestone dataset (the verbatim `can` rows)
- sample readout (M1): "M1 · Ship the catalog — rungs F6.1–F6.5. At the end: browse a persistent catalog and add courses, server-rendered, with inline errors. Status: 5 of 5 shipped. Rests on: nothing above the F5 facade — the first deployable product. Runnable at the milestone's end."

## Main interactive — the git timeline stepper (replay over time)

**Replay the spec's evolution.** A slider advances through the nine dated F6 commits (02 Jun specs → 03 Jun F6.1
→ the 04 Jun reconciles → 05 Jun F6.6 → 05 Jun reconcile). At each commit the readout reports the date, the hash,
what changed, and how the ladder's status moved — a rung flipping `specified → shipped`, or a spec being
`reconciled`. The point it proves: across every step the **spec** changes (remediated, reconciled, groomed,
re-grounded) while nothing below the facade does — feedback edits the spec, the move A1.03.3 named. The F6.5
reconcile step quotes F6.5-US0. Distinct from the hero: the hero orders rungs into milestones; this one replays
how the specs got there over git time.

- control ids: `#otbTl` (range slider, `min=0 max=8 step=1`, one stop per commit)
- pure functions: `statusAt(i) -> {specified, shipped, reconciled}` (counts at commit i) and
  `timelineReadout(i) -> string` over the fixed nine-commit dataset (verbatim dates/hashes/what)
- sample readout (step 4, the F6.5 reconcile `5a440fd`): "04 Jun · 5a440fd — F6.5 reconcile: /courses = catalog, /my/courses = enrollments (resolves a route collision). The spec moved, not the engine: feedback edited F6.5's URL design. Driven by F6.5-US0 — As an architect, I want each URL named after the resource it returns, so that the catalog and a learner's enrollments stop colliding on /courses. Ladder now: 1 shipped · 1 reconciled · 7 specified."

## Principle ↔ practice bridge

- principle: a backlog is ordered into milestones that depend only downward and stay runnable; and the spec is the
  single source of truth, edited by feedback over time — never the working code.
- practice (on the Portal / F6): the nine rungs group into M1 ship the catalog (F6.1–F6.5) → M2 make it live
  (F6.6–F6.7) → M3 ship to users (F6.8–F6.9); the git history shows the specs written 02 Jun, F6.1–F6.6 shipped by
  05 Jun, and the F6.7–F6.9 specs reconciled forward — the F6.5 route reconcile (`5a440fd`) the clearest spec-edit.
- take: a backlog has an order and a history — milestones say what rests on what, and the git trail shows the spec
  moving under feedback while the engine below the facade holds still.

## Cross-links to /elixir

- `/elixir/phoenix` — the F6 chapter where the nine rungs and three milestones are specified, built, and proven.
- `/elixir/phoenix/deployment` — F6.8, the M3 frontier (auth + the deployed clustered release).

Both in prose and in References → "Related in this course". (Folder-routed; resolve 200 against the live server.
They are outside the `--routes-from` mount, so the `links` gate does not check them — crawl them live.)

## References (Sources — real, vetted; reuse the registry)

- Humble & Farley — *Continuous Delivery* — https://continuousdelivery.com/ — keeping the system releasable at
  every milestone, and shipping the first deployable product first.
- Cohn, M. — *User Stories Applied* — https://www.mountaingoatsoftware.com/books/user-stories-applied — ordering a
  backlog into dependency-aware milestones.
- Adzic, G. — *Specification by Example* — https://gojko.net/books/specification-by-example/ — the spec as the
  living, shared source of truth that feedback edits.

## Related (internal — must resolve)

- A2.07 workshop hub; A2.07.2 split-and-test (prev); A2.07.1 vision-to-stories
- A2.01 value (the ordering key); A2 landing
- A1.03.3 adapt — "feedback edits the spec" (the cadence this dive replays)
- `/elixir/phoenix`, `/elixir/phoenix/deployment` (the F6 chapter + the M3 frontier)

## Pager (keep exact)

- prev: `/course/agile-agent-workflow/decomposition/workshop/split-and-test`
- next: workshop hub `/course/agile-agent-workflow/decomposition/workshop` (back to the hub — this is the last dive)
