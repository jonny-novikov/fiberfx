# F5.03.3 — Iterating the slice (dive)

- Route (served): `/elixir/pragmatic/tracer-bullets/iterating`
- File: `elixir/pragmatic/tracer-bullets/iterating.html`
- Place in the chapter: third and last of the three dives under F5.03 (the tracer-bullets module of F5 · Pragmatic Programming). After the skeleton walks, this dive grows it one thin vertical slice at a time and closes the module, handing off to F5.04 (Design by contract).
- Accent: burgundy (`--burgundy: #c4504c`, the F5 · Pragmatic chapter accent).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F5.03 · part 3 of 3`

Hero title (verbatim): `Iterating the slice`

Hero lede (verbatim):

> Once the skeleton walks, the system grows the same way it started: one thin vertical slice at a time. The next use case — deliver the first lesson — is another tracer bullet through the same layers: a route, a context function, a read from the store. Then record progress, then the next thing. Each slice is thin at every layer and reuses the frame, and crucially each one leaves the system **running and demoable**. This is the opposite of building horizontally — finishing the whole web layer, then the whole engine — where nothing works until the very end.

Kicker (verbatim, `.kicker`):

> Three slices, each cutting through every layer. Select one to see what it adds.

## Sections

Two teaching sections plus a References section.

1. `#slices` — **Slice by slice** — each iteration is one vertical cut across all four layers; the interactive slice figure.
2. `#code` — **In code** — the running example: iteration 2 (deliver the first lesson) has the same shape as the first, then a `.bridge` and the closing `.note`.

Running example / real Elixir code (the `#code` block, verbatim tokens):

```
# iteration 2 — deliver the first lesson: a new thin slice, same shape
get "/lessons/:id" do
  case Portal.Catalog.lesson(id) do
    {:ok, lesson} -> send_resp(conn, 200, Jason.encode!(lesson))
    :error        -> send_resp(conn, 404, "not found")
  end
end

# Catalog grows one function; Learning, the store, and the server are untouched
def lesson(lesson_id), do: Portal.Store.fetch(lesson_id)
```

`.bridge`: `one slice at a time` ("Each use case is a thin vertical cut through every layer, added on top of the last.") → `always running` ("The system works at the end of every slice — growth never takes it offline.").

## The interactives

One in-body figure (this dive has no hero concept figure — the hero is plain copy).

Figure — `figure.fig` titled (`#itTitle`) `Vertical slices · select one`.
- Control group `#itSel` (`role="group"`, `aria-label="Iteration"`) with three buttons, `data-k`/label: `enroll`/`1 · enroll` (default `active`), `deliver`/`2 · deliver lesson`, `progress`/`3 · record progress`.
- SVG slice rects: `#itSlice_enroll`, `#itSlice_deliver`, `#itSlice_progress` (over a four-layer grid labelled `web` / `context` / `struct` / `store`). Readout container `#itOut` (`aria-live="polite"`); footnote spans `#itRole` (iteration) and `#itResult` (adds).
- The pure `pick(k)` function highlights the selected slice (gold stroke `#d4a85a`, fill `#241d10`), sets `#itRole`/`#itResult`, and writes `#itOut`. Initial call is `pick('enroll')`.
- Iteration table (`name` / `adds` / `desc`, verbatim from the script):
  - `enroll` — `Iteration 1 · enroll` / `the skeleton` / `The walking skeleton itself: enroll a learner, end to end. Every layer is now exercised once — the frame the next slices reuse.`
  - `deliver` — `Iteration 2 · deliver a lesson` / `a lesson route + query` / `A new vertical slice: GET /lessons/:id calls a Catalog query and returns the lesson. A route, a context function, and a read — thin at every layer, reusing the frame.`
  - `progress` — `Iteration 3 · record progress` / `a progress command` / `Another slice: POST /progress records a learner advancing, building a %Progress{} and storing it. Each iteration leaves the system running and demoable.`
- Readout string template (`#itOut`, verbatim): `<b>{name}</b> — adds <b>{adds}</b>. {desc}`

Takeaway (`.take`, verbatim): `Grow vertically, never horizontally. A stack of thin, finished slices is a working product at every step; a stack of half-built layers is nothing that runs until the last one lands.`

Footer build-stamp decoder: stamp id `TSK0NctaMskCLA`, hard-coded `st-ts` `2026-06-01 14:32:29 UTC`. Decoded: namespace `TSK`, snowflake `319845669151965184`, node `0`, seq `0`, timestamp `2026-06-01 14:32:29 UTC`.

## References (#refs, verbatim)

Intro line: `Primary sources for this lesson, and where it connects in the course.`

Sources:
- `https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/` — Hunt and Thomas — The Pragmatic Programmer — tracer bullets: build end-to-end before exhaustive.
- `https://hexdocs.pm/elixir/introduction-to-mix.html` — Elixir — Introduction to Mix — scaffold the thin, running skeleton app.

Related in this course:
- `/elixir/pragmatic/tracer-bullets` — F5.03 · Tracer bullets: a walking skeleton
- `/elixir/pragmatic/tracer-bullets/skeleton` — The walking skeleton
- `/elixir/pragmatic/contracts` — F5.04 · Design by contract

## Wiring

- route-tag (verbatim): `/ ` `elixir` ` / ` `pragmatic` ` / ` `tracer-bullets` ` / ` `iterating` (links: `elixir` → `/elixir`, `pragmatic` → `/elixir/pragmatic`, `tracer-bullets` → `/elixir/pragmatic/tracer-bullets`, current segment `iterating` in `.rcur`).
- crumbs (verbatim): `F5` (→ `/elixir/pragmatic`) `/` `F5.03` (→ `/elixir/pragmatic/tracer-bullets`) `/` `iterating` (`.here`).
- toc-mini: `#slices` → `Slice by slice`; `#code` → `In code`.
- pager: prev → `/elixir/pragmatic/tracer-bullets/skeleton` label `← F5.03.2 · skeleton`; next → `/elixir/pragmatic/tracer-bullets` label `Back to F5.03 →`.
- The closing `.note` (verbatim): `That closes F5.03: a tracer bullet became a walking skeleton, and the skeleton grows by slices. The next module, F5.04 — Design by contract, hardens the commands each slice runs with preconditions and invariants. Back to the module overview or the chapter.` (links: `/elixir/pragmatic/tracer-bullets`, `/elixir/pragmatic`).
- footer: three columns, identical to the hub. **Chapters** — F1 `/elixir/algebra`, F2 `/elixir/functional`, F3 `/elixir/language`, F4 `/elixir/algorithms`, F5 `/elixir/pragmatic`, F6 `/elixir/phoenix`. **The course** — `Course home` `/elixir`, `Contents & history` `/elixir/course`, `Start · F1.01` `/elixir/algebra/functions`.
- Page meta: `<title>` = `Iterating the slice — F5.03.3 · jonnify`. `<meta name="description">` = `Once the skeleton walks, you grow it one thin vertical slice at a time: deliver the first lesson, then record progress, each slice touching route, context, struct, and store, each leaving the system running and demoable. Vertical slices keep the whole thing alive where horizontal layers would not.`

## Build instruction

To rebuild this dive, copy the `<head>…</style>`, the `header.site`, the `footer.site-foot`, and the two trailing `<script>` blocks verbatim from a recent built sibling on the burgundy F5 accent — the model sibling is `elixir/pragmatic/tracer-bullets/skeleton.html` (same module, same stamp epoch, same `solid-select`/`geo-readout` script shape) — changing only the `<title>`/`<meta description>`, the route-tag, the crumbs `.here`, and the `<main>` body. Keep the `#itSel`/`#itOut` slice-selector wiring exactly as authored: a pure `pick` function, no framework. No-invent guards: use only the real Portal surfaces as written — the `Portal.Catalog` context (`lesson/1`), the `Portal.Store` (`fetch/1`), the `%Progress{}` struct, the `Learning` context and `%Enrollment{}` from the prior slices, and the one `Portal` facade over the event-sourced engine — and cite the companion course for OTP internals rather than re-teaching them. Voice rules: no first person, no exclamation marks, no emoji, and none of just / simply / obviously.
