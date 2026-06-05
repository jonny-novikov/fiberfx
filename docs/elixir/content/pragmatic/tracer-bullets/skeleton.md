# F5.03.2 — The walking skeleton (dive)

- Route (served): `/elixir/pragmatic/tracer-bullets/skeleton`
- File: `elixir/pragmatic/tracer-bullets/skeleton.html`
- Place in the chapter: second of the three dives under F5.03 (the tracer-bullets module of F5 · Pragmatic Programming). After `prototypes` draws the line, this dive drives the enroll-a-learner tracer bullet end to end and is the richest dive of the three — it carries an extra teaching section (`Wire every layer before the logic`) with a second diagram.
- Accent: burgundy (`--burgundy: #c4504c`, the F5 · Pragmatic chapter accent).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F5.03 · part 2 of 3`

Hero title (verbatim): `The walking skeleton`

Hero lede (verbatim):

> The walking skeleton is the enroll-a-learner tracer bullet, wired end to end and actually running. A `POST /enroll` on the thin server calls `Learning.enroll/2`, which validates the ids, builds an `%Enrollment{}` with a fresh branded id, and writes it to the store; the handler answers `201`. Every layer from F5.01 and F5.02 is present, and every layer is doing the least it can — one route, one context function, one struct, one store call. It is not a demo and not a mock: a real request produces a real, persisted enrollment. That is the skeleton, and everything after this is flesh on these bones.

Kicker (verbatim, `.kicker`):

> Follow one enrollment through the round trip. Select a step to see what really happens there.

## Sections

Three teaching sections plus a References section.

1. `#round` — **The round trip** — the request/response sequence and the interactive step figure.
2. `#code` — **In code** — the two wired pieces (the F5.01 route mapping the tagged result to a status; the F5.02 context function validating, building, and storing in one `with` chain), then a `.bridge` and a forward `.note`.
3. `Wire every layer before the logic` (`#wireTitle`, a `.reveal` section) — the tracer-bullet discipline: every layer wired as a canned stub before any logic; the four canned layers are permanent scaffolding fleshed out in place. Carries a second figure and a second code block.

Running example / real Elixir code.

The `#code` block (verbatim tokens):

```
# web (F5.01) — one route, maps {:ok}/{:error} to a status
post "/enroll" do
  case Portal.Learning.enroll(conn.params["user"], conn.params["course"]) do
    {:ok, e}         -> send_resp(conn, 201, e.id)
    {:error, reason} -> send_resp(conn, 422, to_string(reason))
  end
end

# context (F5.02) — validate, build the struct, store it
def enroll(user_id, course_id) do
  with :ok        <- validate_ids(user_id, course_id),
       enrollment = %Enrollment{id: Portal.ID.new("ENR"), user_id: user_id, course_id: course_id},
       :ok        <- Portal.Store.put(enrollment) do
    {:ok, enrollment}
  end
end
```

The `Wire every layer before the logic` block (verbatim tokens):

```
# web — the one route, wired to the facade; status is canned for now
post "/enroll" do
  {:ok, _} = Portal.enroll(conn.params["user"], conn.params["course"])
  send_resp(conn, 201, "wired")
end

# facade — reaches the engine; no validation yet, only the wire
def enroll(user_id, course_id) do
  Portal.Engine.command({:enroll, user_id, course_id})
end

# engine — reaches the port and answers; no decide/evolve yet
def command(_cmd) do
  :ok = Portal.EventStore.append("portal", [])   # canned: append nothing to the stream
  {:ok, :enrolled}                       # canned result
end

# port — the seam the real adapter drops into later; a no-op stub today
def append(_stream, _events), do: :ok

# the whole path runs, with not one line of domain logic written
Portal.enroll("USR-1", "CRS-1")
# => {:ok, :enrolled}
```

`.bridge` (round-trip section): `one path, all layers` ("Web, context, struct, store — each touched once, none finished.") → `a skeleton that walks` ("A real request makes a real, stored enrollment — the frame is proven."). `.bridge` (wire section): `the wire comes first` ("Web, facade, engine, port — all four connected end to end while every body is still a canned stub.") → `scaffolding, not a prototype` ("Each stub stays put and is fleshed out in place; the proven frame is the one the system grows from.").

## The interactives

Two in-body figures (this dive has no hero concept figure — the hero is plain copy).

Figure 1 — `figure.fig` titled (`#skTitle`) `Enroll, end to end · select a step`.
- Control group `#skSel` (`role="group"`, `aria-label="Round-trip step"`) with four buttons, `data-k`/label: `request`/`request`, `enroll`/`enroll` (default `active`), `store`/`store`, `respond`/`respond`.
- SVG step rects: `#skStep_request`, `#skStep_enroll`, `#skStep_store`, `#skStep_respond`. Readout container `#skOut` (`aria-live="polite"`); footnote spans `#skRole` (step) and `#skResult` (does).
- The pure `pick(k)` function highlights the selected step (blue stroke, fill `#11203a`), sets `#skRole`/`#skResult`, and writes `#skOut`. Initial call is `pick('enroll')`.
- Step table (`name` / `does` / `desc`, verbatim from the script). Note the four `data-k` SVG-label captions differ slightly from the script's `does` (the SVG shows `request arrives`, `validate + build`, `keep it`, `answer w/ id`):
  - `request` — `POST /enroll` / `request arrives` / `A learner-enrolls request hits the thin server's one route. The params carry a user id and a course id; no auth, no middleware — only this path.`
  - `enroll` — `Learning.enroll/2` / `validate + build` / `The context validates the ids, builds an %Enrollment{} with a fresh branded id, and returns a tagged tuple. The real domain logic, for this one case.`
  - `store` — `Store.put/1` / `keep it` / `The enrollment is written to the F4 store. One entity persisted for real; the rest of the schema waits for later slices.`
  - `respond` — `201 Created` / `answer with the id` / `On {:ok, e} the handler returns 201 and the new id; on {:error, _}, 422. The round trip is complete — the skeleton walked.`
- Readout string template (`#skOut`, verbatim): `<b>{name}</b> — {does}. {desc}`

Figure 2 — `figure.fig` titled (`#wireFigTitle`) `Four layers wired, every body still canned`.
- Static SVG (no interactive controls): four stacked sage-stroked layer rects — `POST /enroll` (`stub · returns 201`), `Portal.enroll/2` (`stub · calls the engine`), `Portal.Engine` (`stub · canned :ok`), `Portal.EventStore` (`stub · no-op append/2`) — labelled `web` / `facade` / `engine` / `port`, with a request-down / `201`-up axis.
- Static `.geo-readout` caption (verbatim): `every layer present · every body canned · the path connects, then each stub is fleshed out in place`.

Takeaways: round-trip section `.take` (verbatim) `If one real request round-trips, the design is no longer a hope — it is a fact. The skeleton proves the layers fit together before any of them is finished.` Wire section `.take` (verbatim) `Wire the whole path through every layer before writing the logic: once the canned end-to-end call returns, each stub is filled in where it stands, so the skeleton that proved the path is the one the system keeps.`

Footer build-stamp decoder: stamp id `TSK0NctaMXSHaK`, hard-coded `st-ts` `2026-06-01 14:32:29 UTC`. Decoded: namespace `TSK`, snowflake `319845668837392384`, node `0`, seq `0`, timestamp `2026-06-01 14:32:29 UTC`.

## References (#refs, verbatim)

Intro line: `Primary sources for this lesson, and where it connects in the course.`

Sources:
- `https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/` — Hunt and Thomas — The Pragmatic Programmer — tracer bullets: build end-to-end before exhaustive.
- `https://hexdocs.pm/elixir/introduction-to-mix.html` — Elixir — Introduction to Mix — scaffold the thin, running skeleton app.

Related in this course:
- `/elixir/pragmatic/tracer-bullets` — F5.03 · Tracer bullets: a walking skeleton
- `/elixir/pragmatic/tracer-bullets/prototypes` — F5.03.1 · Prototypes
- `/elixir/pragmatic/tracer-bullets/iterating` — F5.03.3 · Iterating the slice

## Wiring

- route-tag (verbatim): `/ ` `elixir` ` / ` `pragmatic` ` / ` `tracer-bullets` ` / ` `skeleton` (links: `elixir` → `/elixir`, `pragmatic` → `/elixir/pragmatic`, `tracer-bullets` → `/elixir/pragmatic/tracer-bullets`, current segment `skeleton` in `.rcur`).
- crumbs (verbatim): `F5` (→ `/elixir/pragmatic`) `/` `F5.03` (→ `/elixir/pragmatic/tracer-bullets`) `/` `skeleton` (`.here`).
- toc-mini: `#round` → `The round trip`; `#code` → `In code`.
- pager: prev → `/elixir/pragmatic/tracer-bullets/prototypes` label `← F5.03.1 · prototypes`; next → `/elixir/pragmatic/tracer-bullets/iterating` label `Next · iterating the slice →`.
- The `#code` closing `.note` (verbatim): `Next: iterating the slice — growing the skeleton one thin vertical slice at a time.` (link `/elixir/pragmatic/tracer-bullets/iterating`).
- footer: three columns, identical to the hub. **Chapters** — F1 `/elixir/algebra`, F2 `/elixir/functional`, F3 `/elixir/language`, F4 `/elixir/algorithms`, F5 `/elixir/pragmatic`, F6 `/elixir/phoenix`. **The course** — `Course home` `/elixir`, `Contents & history` `/elixir/course`, `Start · F1.01` `/elixir/algebra/functions`.
- Page meta: `<title>` = `The walking skeleton — F5.03.2 · jonnify`. `<meta name="description">` = `The enroll-a-learner slice, end to end: a POST /enroll route calls Learning.enroll/2, which builds an %Enrollment{} and puts it in the store, and the handler answers 201. Every layer is present and every layer is minimal — a skeleton that walks, the frame every later feature drops into.`

## Build instruction

To rebuild this dive, copy the `<head>…</style>`, the `header.site`, the `footer.site-foot`, and the two trailing `<script>` blocks verbatim from a recent built sibling on the burgundy F5 accent — the model sibling is `elixir/pragmatic/tracer-bullets/iterating.html` (same module, same stamp epoch, same `solid-select`/`geo-readout` script shape) — changing only the `<title>`/`<meta description>`, the route-tag, the crumbs `.here`, and the `<main>` body. Preserve both figures: the interactive `#skSel`/`#skOut` round-trip stepper (a pure `pick`) and the static `Four layers wired` diagram. No-invent guards: use only the real Portal surfaces as written — the one `Portal` facade with `Portal.enroll/2`, the `Portal.Engine` command boundary, the `Portal.EventStore` port (`append/2`), the branded store (`Portal.Store.put/1`, `Portal.ID.new("ENR")`), the `Learning` context, and the `%Enrollment{}` struct — and cite the companion course for OTP internals rather than re-teaching them. Voice rules: no first person, no exclamation marks, no emoji, and none of just / simply / obviously.
