# A4.7.1 · The engine deliverables (dive 1)

- **Route:** `/course/agile-agent-workflow/spec/workshop/the-engine-deliverables`
- **File:** `html/agile-agent-workflow/spec/workshop/the-engine-deliverables.html`
- **Pager:** prev hub `/course/agile-agent-workflow/spec/workshop` · next `run-the-sequence`.
- **Accent:** elixir-purple. **Stamp:** `TSK0Ng9hnHJgW0`. **Model:** `why/two-layers/spec.html` (lesson).

## Grounding (verbatim from the F5.1 spec)

The workshop rule for all four `workshop/*` pages: they cite **F5.1 — Portal's engine-facade rung** (the
engine chapter's first rung), which sits below the F6 web ladder the spec-ladder viewer shows. There is no
`#f5-1` viewer stop, so these pages add **no** `.specref` chip to `/spec/specimens`. Instead F5.1 is given a
**named reference** in prose — written **"F5.1 — Portal's engine-facade rung"** — and the `/elixir` cross-link
to the engine chapter (`/elixir/pragmatic`, with `/elixir/phoenix` for the F6 chapter that replaces the seam)
is kept. A bare filename `f5.1.md` survives only as a `pre.code` excerpt label (the illustrated spec) and in JS
comments, never as a dangling prose citation.

The seven deliverables of F5.1 "Start thin: a running Portal":

- **F5.1-D1** — a supervised Mix project `portal` with `bandit`, `plug`, `jason`; no Phoenix, no Ecto.
- **F5.1-D2** — `Portal.ID`: branded Snowflake ids (3-letter namespace + width-11 Base62, 14 chars); the id
  contract `Portal.ID.generate/1` / decode the course names freely.
- **F5.1-D3** — `Portal.Engine`: a stubbed boundary (`dispatch/1`, `query/2`), each returning
  `{:ok, term} | {:error, atom}`.
- **F5.1-D4** — the thin router: parse, call the engine boundary, format a response. One read route, one write
  route, a 404 fallback.
- **F5.1-D5** — `Portal.Application` supervises the engine and the web server `:one_for_one`.
- **F5.1-D6** — the web layer is a thin, replaceable adapter plus a roadmap of what stays and what F6 replaces.
- **F5.1-D7** — verification: boot, the stub responses, an unknown path 404, and a supervised restart.

The master-invariant seed, **F5.1-INV1 (replaceable seam · seed of the master invariant)** — "the web layer
holds no domain logic … so F6 can replace `Bandit` with Phoenix untouched". A4 may name `Portal.Engine` only
inside this seam statement and the closed-error fact; the API named freely is `Portal.ID.generate/1` /
`Portal.ID.decode/1`.

## Lead

Before a spec is written, its inventory is fixed: the deliverables — the concrete artifacts a rung ships.
**F5.1 — Portal's engine-facade rung** carries seven, D1 through D7. Each is one artifact, and each constrains
the build by naming what exists without dictating how it is coded. This dive reads them from that rung's spec —
the first rung of the engine chapter, taught in the companion Elixir course at `/elixir/pragmatic` — then shows
the line F5.1-INV1 draws — the replaceable web seam that becomes the F6 master invariant. The deliverables are
the workshop's starting material: A4.7.2 runs the sequence over them, A4.7.3 checks the result closes.

## Hero interactive — pick a deliverable, read what it constrains

Hero figure: a list of the seven deliverables D1…D7. Pick one; the readout names the artifact (verbatim
gloss from `f5.1.md`) and what it constrains — and, crucially, that it constrains *what* exists, never *how*
it is implemented. Teaches: a deliverable is a named artifact, not an implementation.

- Fixed dataset `DELIV` (seven entries D1…D7): each carries `rect` id, accent, `artifact` string, and a
  `constrains` string.
- Pure `deliverableReadout(key)` → string.
- Static default: D1 lit; readout reports the supervised project deliverable.
- Control ids: `delSel` (seven buttons `data-k=d1…d7`, `data-c=elixir`); SVG rects `del-d1`…`del-d7`;
  readout `delOut` (`aria-live`).

## Main interactive — the replaceable web seam (F5.1-INV1)

Main figure: the two-layer split of F5.1 — a web layer over an engine boundary. Toggle which layer is asked
to hold domain logic. When the web layer holds none (the F5.1-INV1 position), the readout reports the seam
holds and F6 can replace `Bandit` with Phoenix untouched; when the web layer is asked to hold domain logic,
the readout reports the seam is broken — F6 could not swap the web layer without disturbing the domain.
Teaches the consequence: D6's discipline is what makes the chapter's later web rung (F6) cheap.

- Fixed dataset: two positions `thin` (INV1 holds) and `thick` (INV1 broken).
- Pure `seamReadout(pos)` → string.
- Static default: `thin` selected; readout reports the seam holds.
- Control ids: `seamSel` (two buttons `data-k=thin|thick`, `data-c=elixir|gold`); SVG groups `seam-web`,
  `seam-engine`, link `seam-link`; readout `seamOut` (`aria-live`).

## pre.code (markdown only — no Elixir source)

An `f5.1.md` excerpt: the Deliverables heading, D3/D6 bullets, and the F5.1-INV1 invariant line — rendered
with `.cmt`/`.str`/`.res` spans. No `def`/`defmodule`/test.

## Bridge

- **The principle** — deliverables fix the inventory of a rung: each names one artifact and constrains *what*
  exists, leaving *how* to the build.
- **On the Portal** — F5.1 ships D1…D7 — the supervised app, `Portal.ID`, the engine boundary, the thin
  router, supervision, the replaceable-seam discipline, and verification — with F5.1-INV1 holding the web
  seam thin.
- **Take** — name the deliverables and the invariant they hold, and the build has a precise target without a
  dictated solution.

## References

- Sources: Specification by Example (`gojko.net`), Continuous Delivery (`continuousdelivery.com`), User
  Stories Applied (`mountaingoatsoftware.com`).
- Related: hub, `/course/agile-agent-workflow/spec`, `/course/agile-agent-workflow/why/correct`,
  `/elixir/pragmatic` (the engine chapter whose first rung, F5.1, ships these deliverables — the named-reference
  anchor), `/elixir/phoenix` (the F6 chapter that replaces the seam), `/elixir/course`.
