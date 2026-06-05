# F5.01.3 — A web layer built for replacement (dive)

- Route (served): `/elixir/pragmatic/foundations/replaceable`
- File: `elixir/pragmatic/foundations/replaceable.html`
- Place in the chapter: the last of F5.01's three dives (part 3 of 3). It turns the thin server's smallness into a discipline — the web may only call the engine's boundary — so that F6 can swap the Plug server for Phoenix with the engine untouched. It closes F5.01 and hands off to F5.02.
- Accent: burgundy (`--burgundy: #c4504c`; the F5 chapter accent). The in-page figure accents the engine and the active front end in gold (`--gold`).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F5.01 · part 3 of 3`

Hero `h1` (verbatim): A web layer built for replacement

Hero lede (`.lede`, verbatim):

> Starting thin only pays off if the thin part is easy to discard. The discipline is one rule: the web layer may only call the engine's boundary — `dispatch/1` and `query/2` — and may never reach past it into the Portal's internals. Hold that line and the front end becomes a detail. In F6 the thin Plug server is replaced by Phoenix and LiveView, and because Phoenix calls the very same functions, the engine does not change at all. This is orthogonality and ETC — easier to change — made concrete: the part that varies (the web) is decoupled from the part that stays (the Portal).

Kicker (`.kicker`, verbatim):

> Two front ends, one engine. Toggle between today's thin server and tomorrow's Phoenix, and watch what stays fixed.

## Sections

The teaching arc runs seam → same-call-twice:

1. **One engine, two front ends** (`#seam`) — the engine's boundary is the seam; whatever sits above it (a Plug router now, a Phoenix LiveView later) is only a caller, and callers are interchangeable when they speak through the same two functions. The `#rpSel` figure toggles the front end while the engine box does not move. `.take` (verbatim): "Decoupling is not a diagram; it is a rule you can break. \"The web only calls the boundary\" is the rule — keep it, and replacing the web is a swap, not a rewrite."
2. **The same call, twice** (`#code`) — the same use case from both front ends; the Plug handler today and the LiveView event handler in F6 build the same command and make the same call, differing only in how they receive input and render output. `.bridge`: "orthogonality & ETC" → "one seam". `.note` (verbatim): "That closes F5.01: the Portal runs, the roadmap is set, and the web is replaceable. The next module, F5.02 — Modeling the Portal domain, gives the engine its first real shape. Back to [the module overview](/elixir/pragmatic/foundations) or [the chapter](/elixir/pragmatic)."

Running example: the `enroll` use case (`%EnrollLearner{}`) shown once as a Plug handler and once as a LiveView event.

The real Elixir code shown (`pre.code`):

```
# today — the thin Plug handler (F5.01)
post "/enroll" do
  Portal.Engine.dispatch(%EnrollLearner{user_id: conn.params["user"], course_id: conn.params["course"]})
end

# tomorrow — a Phoenix LiveView event (F6), the same call
def handle_event("enroll", %{"user" => u, "course" => c}, socket) do
  Portal.Engine.dispatch(%EnrollLearner{user_id: u, course_id: c})
  {:noreply, socket}
end

# the engine never changes; only the caller does
```

## The interactives

### Figure — "The front end is swappable · select one" (`#rpSel` selector + `#rpOut` readout)

- `<figure class="fig" aria-labelledby="rpTitle">`, title `#rpTitle` "The front end is swappable · select one". A `.solid-select#rpSel` group of two `<button data-k>`s and an `<svg viewBox="0 0 720 210">` of two front-end boxes both pointing at one engine box.
- Buttons (`data-k`, label): `thin` "thin server (now)" (`class="active"`) · `phoenix` "Phoenix (F6)".
- SVG element ids: front-end boxes `#rpFront_thin` (gold `#d4a85a`, active) and `#rpFront_phoenix`; arrows `#rpArrow_thin` / `#rpArrow_phoenix`; the fixed engine box `#rpEngine` (`Portal.Engine · dispatch/1 · query/2`).
- Pure function: `pick(k)` looks up `FRONTS[k]`, toggles each `#rpSel` button's `active`/`aria-pressed`, restrokes the chosen front box and its arrow (`GOLD_MUTE = '#d4a85a'` and opacity 1 when on, else `#3a4263` and opacity 0.25), and writes `#rpRole` (name), `#rpResult` (engine), and `#rpOut.innerHTML` (`Front end: name. The engine is engine. desc`). The `#rpEngine` box never changes. Initial call `pick('thin')`.
- Readout `FRONTS` desc strings (verbatim; the desc embeds inline `<code class="inl">` markup):
  - thin: name "thin server (Plug)", engine "unchanged" — "A `Plug.Router` on Bandit. It receives HTTP and calls `dispatch/1` / `query/2`. Small, and meant to be discarded once Phoenix arrives."
  - phoenix: name "Phoenix + LiveView", engine "unchanged" — "In F6, Phoenix and LiveView replace the thin server. They receive events and render UI, then call the same `dispatch/1` / `query/2` — so the engine, and its boundary, do not change."
- Static default: the `thin server (now)` button is `active` and the static labels (`front end: thin server (Plug)`, `engine: unchanged`) render in markup; `#rpOut` is empty until `pick('thin')` fills it. Respects `prefers-reduced-motion` globally; no browser storage.

### Footer build-stamp decoder (`#stamp`)

- Stamp id: `TSK0Ncqelgh6Mi` (in `#stampId`); panel `#st-ts` hard-codes "2026-06-01 13:51:30 UTC".
- Pure functions: `b62decode(s)`, `pad2(x)`, `decodeBranded(id)` — `ns = id.slice(0,3)`, `snow = b62decode(id.slice(3))`, `ts = snow >> 22n`, `node = (snow >> 12n) & 0x3FFn`, `seq = snow & 0xFFFn`, epoch `EPOCH_MS = 1704067200000`, formatted UTC. Toggle on click / Enter / Space.
- Decoding `TSK0Ncqelgh6Mi`: namespace `TSK`; the snowflake over epoch `2024-01-01` resolves to the panel's stamped "2026-06-01 13:51:30 UTC".

## References (#refs, verbatim)

Intro line: "Primary sources for this lesson, and where it connects in the course."

**Sources**
- [Introduction to Mix — Elixir documentation](https://hexdocs.pm/elixir/introduction-to-mix.html) — applications, deps, and tasks.
- [`Mix` — Elixir documentation](https://hexdocs.pm/mix/Mix.html) — the build tool reference.

**Related in this course**
- F5.01 · Foundations → `/elixir/pragmatic/foundations`
- The thin server → `/elixir/pragmatic/foundations/thin-server`
- F5.02 · Modeling the Portal domain → `/elixir/pragmatic/domain`

## Wiring

- route-tag (verbatim): `<span class="rsep">/</span><a href="/elixir">elixir</a><span class="rsep">/</span><a href="/elixir/pragmatic">pragmatic</a><span class="rsep">/</span><a href="/elixir/pragmatic/foundations">foundations</a><span class="rsep">/</span><span class="rcur">replaceable</span>`.
- crumbs: `F5` → `/elixir/pragmatic` · sep `/` · `F5.01` → `/elixir/pragmatic/foundations` · sep `/` · here `replaceable` (no link).
- toc-mini: `#seam` ("One engine, two front ends") · `#code` ("The same call, twice").
- pager: prev → `/elixir/pragmatic/foundations/thin-server` ("← F5.01.2 · thin server"); next → `/elixir/pragmatic/foundations` ("Back to F5.01 →").
- footer (3-column `.foot-nav`): Brand → `/elixir`; Chapters column `/elixir/algebra` ("F1 · Algebra"), `/elixir/functional` ("F2 · Functional Programming"), `/elixir/language` ("F3 · The Elixir Language"), `/elixir/algorithms` ("F4 · Algorithms & Data Structures"), `/elixir/pragmatic` ("F5 · Pragmatic Programming"), `/elixir/phoenix` ("F6 · Phoenix Framework"); The course column `/elixir` ("Course home"), `/elixir/course` ("Contents & history"), `/elixir/algebra/functions` ("Start · F1.01").
- Page meta: `<title>` "A web layer built for replacement — F5.01.3 · jonnify"; `<meta description>` "The thin server is a detail, by design. Because every route only calls Portal.Engine.dispatch/1 and query/2, the same calls move unchanged into a Phoenix controller or a LiveView handle_event in F6 — the web layer is swapped, the engine is not. Orthogonality and ETC, made concrete."

## Build instruction

To rebuild this page, copy the head…`</style>`, the `<header class="site">`, the `<footer class="site-foot">`, and both trailing `<script>` blocks verbatim from a recent BUILT sibling on the burgundy F5 accent — the model is its sibling dive `elixir/pragmatic/foundations/thin-server.html` (same `--burgundy` chapter, same single-column lesson `.hero`, same stamp/decoder and reveal scripts) — and change only `<title>`/`<meta>`, the route-tag, the crumbs, and the `<main>` body. The dive body is the single-column `.hero`, the `#seam` section with the `#rpSel` swap figure (two front ends, one fixed `#rpEngine`), the `#code` section with the two-handler `pre.code` + `.bridge`, then `#refs` and pager. No-invent guards: use only the real Portal surfaces as written — `Portal.Engine.dispatch/1` and `Portal.Engine.query/2` are the only boundary the web may call, `%EnrollLearner{}` the command, the Plug handler today and the Phoenix LiveView `handle_event/3` in F6 — and cite the companion `/elixir` course for OTP and Phoenix internals rather than re-teaching them. Voice rules: no first person, no exclamation marks, no emoji, and none of just/simply/obviously.
