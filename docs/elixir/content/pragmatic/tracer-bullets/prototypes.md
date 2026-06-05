# F5.03.1 — Tracer bullets vs prototypes (dive)

- Route (served): `/elixir/pragmatic/tracer-bullets/prototypes`
- File: `elixir/pragmatic/tracer-bullets/prototypes.html`
- Place in the chapter: first of the three dives under F5.03 (the tracer-bullets module of F5 · Pragmatic Programming). It draws the line between a tracer bullet and a prototype before the next dive (`skeleton`) drives the tracer bullet end to end.
- Accent: burgundy (`--burgundy: #c4504c`, the F5 · Pragmatic chapter accent).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F5.03 · part 1 of 3`

Hero title (verbatim): `Tracer bullets vs prototypes`

Hero lede (verbatim):

> Both techniques start the same way — build something small and fast — but they have opposite fates, and confusing them is expensive. A **tracer bullet** is thin but real production code that travels the whole system; you fire it, watch where it lands, and adjust, then keep it and build the next path on top. A **prototype** is throwaway code written to answer one question — will this library do the job, is this shape right — and once the question is answered it is deleted. The mistake to avoid is shipping a prototype, or lavishing polish on what should have been thrown away.

Kicker (verbatim, `.kicker`):

> Same fast start, opposite ending. Select one to see what it is for and what becomes of the code.

## Sections

Two teaching sections plus a References section.

1. `#fate` — **Same start, opposite fate** — the framing question (am I building part of the system, or learning something about it?) and the interactive technique comparison.
2. `#code` — **In code** — the running example: the enroll route as a tracer bullet vs a throwaway payload-shape prototype, then a `.bridge` and a forward `.note`.

Running example / real Elixir code (the `#code` block, verbatim tokens):

```
# tracer bullet — real, thin, KEPT: the actual enroll path through the system
post "/enroll" do
  {:ok, enrollment} = Portal.Learning.enroll(conn.params["user"], conn.params["course"])
  send_resp(conn, 201, enrollment.id)
end

# prototype — throwaway: answers "what shape is the payload?", then DELETED
"sample.json" |> File.read!() |> Jason.decode!() |> IO.inspect()
```

`.bridge`: `am I building or learning?` ("Building the system → tracer bullet, real. Learning something → prototype, throwaway.") → `the enroll path` ("Thin but real, and kept — the first tracer bullet, which the skeleton is built from.").

## The interactives

One in-body figure (this dive has no hero concept figure — the hero is plain copy).

Figure — `figure.fig` titled (`#tpTitle`) `Two techniques · select one`.
- Control group `#tpSel` (`role="group"`, `aria-label="Technique"`) with two buttons, `data-k`/label: `tracer`/`tracer bullet` (default `active`), `prototype`/`prototype`.
- SVG row rects: `#tpRow_tracer`, `#tpRow_prototype`. Readout container `#tpOut` (`aria-live="polite"`); footnote spans `#tpRole` (technique) and `#tpResult` (the code is).
- The pure `pick(k)` function highlights the selected row (burgundy stroke `#c4504c`, fill `#1d1320`), sets `#tpRole` to the technique name and `#tpResult` to its `fate`, and writes `#tpOut`. Initial call is `pick('tracer')`.
- Technique table (`name` / `fate` / `desc`, verbatim from the script):
  - `tracer` — `Tracer bullet` / `kept & built upon` / `Thin but real production code that round-trips the whole system. You aim it, see where it lands, and adjust — then keep it and add the next path. The walking skeleton is one.`
  - `prototype` — `Prototype` / `thrown away` / `Throwaway code written to answer one question — will this library work, is this layout right. Once answered it is discarded; its value was the lesson, not the code.`
- Readout string template (`#tpOut`, verbatim): `A <b>{name}</b> — the code is <b>{fate}</b>. {desc}`

Takeaway (`.take`, verbatim): `Decide the fate before you write the code. A tracer bullet earns its keep by being real; a prototype earns its keep by being deleted.`

Footer build-stamp decoder: stamp id `TSK0NctaMCAMpU`, hard-coded `st-ts` `2026-06-01 14:32:29 UTC`. Decoded: namespace `TSK`, snowflake `319845668522819584`, node `0`, seq `0`, timestamp `2026-06-01 14:32:29 UTC`.

## References (#refs, verbatim)

Intro line: `Primary sources for this lesson, and where it connects in the course.`

Sources:
- `https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/` — Hunt and Thomas — The Pragmatic Programmer — tracer bullets: build end-to-end before exhaustive.
- `https://hexdocs.pm/elixir/introduction-to-mix.html` — Elixir — Introduction to Mix — scaffold the thin, running skeleton app.

Related in this course:
- `/elixir/pragmatic/tracer-bullets` — F5.03 · Tracer bullets: a walking skeleton
- `/elixir/pragmatic/tracer-bullets/skeleton` — The walking skeleton
- `/elixir/pragmatic/tracer-bullets/iterating` — Iterating on the skeleton

## Wiring

- route-tag (verbatim): `/ ` `elixir` ` / ` `pragmatic` ` / ` `tracer-bullets` ` / ` `prototypes` (links: `elixir` → `/elixir`, `pragmatic` → `/elixir/pragmatic`, `tracer-bullets` → `/elixir/pragmatic/tracer-bullets`, current segment `prototypes` in `.rcur`).
- crumbs (verbatim): `F5` (→ `/elixir/pragmatic`) `/` `F5.03` (→ `/elixir/pragmatic/tracer-bullets`) `/` `prototypes` (`.here`).
- toc-mini: `#fate` → `Same start, opposite fate`; `#code` → `In code`.
- pager: prev → `/elixir/pragmatic/tracer-bullets` label `← F5.03 · tracer-bullets`; next → `/elixir/pragmatic/tracer-bullets/skeleton` label `Next · the walking skeleton →`.
- The closing `.note` (verbatim): `Next: the walking skeleton — the tracer bullet, driven end to end through every layer.` (link `/elixir/pragmatic/tracer-bullets/skeleton`).
- footer: three columns, identical to the hub. **Chapters** — F1 `/elixir/algebra`, F2 `/elixir/functional`, F3 `/elixir/language`, F4 `/elixir/algorithms`, F5 `/elixir/pragmatic`, F6 `/elixir/phoenix`. **The course** — `Course home` `/elixir`, `Contents & history` `/elixir/course`, `Start · F1.01` `/elixir/algebra/functions`.
- Page meta: `<title>` = `Tracer bullets vs prototypes — F5.03.1 · jonnify`. `<meta name="description">` = `Both are built fast, but their fates are opposite. A tracer bullet is thin but real code that round-trips the whole system and is kept and built upon; a prototype is throwaway code written to answer one question, then discarded. Knowing which you are writing keeps you from shipping a prototype or polishing a tracer bullet.`

## Build instruction

To rebuild this dive, copy the `<head>…</style>`, the `header.site`, the `footer.site-foot`, and the two trailing `<script>` blocks verbatim from a recent built sibling on the burgundy F5 accent — the model sibling is `elixir/pragmatic/tracer-bullets/skeleton.html` (same module, same stamp epoch, same script shape) — changing only the `<title>`/`<meta description>`, the route-tag, the crumbs `.here`, and the `<main>` body. Keep the `#tpSel`/`#tpOut` comparison wiring exactly as authored: a pure `pick` function, no framework. No-invent guards: use only the real Portal surfaces as written — the `Portal.Learning` context, the branded store, `enrollment.id`, the event-sourced engine behind the one `Portal` facade — and cite the companion course for OTP internals rather than re-teaching them. Voice rules: no first person, no exclamation marks, no emoji, and none of just / simply / obviously.
