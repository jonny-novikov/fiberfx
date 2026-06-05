# F0.2 — The evolution of Erlang, the BEAM & OTP (dive)

- Route (served): `/elixir/course/beam-evolution`
- File: `elixir/course/beam-evolution.html`
- Place in the chapter: the second of the two history modules in F0, tracing the runtime Elixir stands on. It follows F0.1 (the language lineage at `/elixir/course/fp-evolution`) and completes the F0 history; the course proper then begins at F1 · Algebra. Three dives follow the overview, each pairing a runtime idea with the Elixir that sits on top of it.
- Accent: chapter F0 · History · blue (the timeline carries `--burgundy` "telecom" → `--blue` "real-time" markers, the supervisor card draws gold, workers sage/elixir; the page sits on the shared editorial palette).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F0 · History · optional`

H1 (verbatim): `The evolution of Erlang, the BEAM & OTP`

Lede (verbatim): "F0.1 traced the language. This one traces the machine — a runtime built for telephone switches that turned out to be exactly what real-time systems need."

Kicker (verbatim): "Where the functional lineage gave Elixir its way of thinking, the BEAM gave it a place to run: cheap processes, a scheduler that keeps every one of them responsive, and a supervision model that treats failure as routine. Three dives follow the overview, each pairing a runtime idea with the Elixir that sits on top of it."

## Sections

In order:

1. Overview — `One machine, six steps` (the interactive runtime timeline; running example: the six-step `Erlang → Open / OTP → SMP cores → Elixir → Phoenix → Polyglot` rail).
2. `#telecom-roots` — dive `F0.2.1` · `Telecom roots & "let it crash"` (teaching). Bridge: `Erlang, 1986` → `Elixir, today` (return `{:error, reason}` for the expected, let it crash for the rest; a `Supervisor` brings the worker back). Running example: a supervised worker that heals on crash. Real Elixir tokens: `{:error, reason}`, `Supervisor`.
3. `#inside-beam` — dive `F0.2.2` · `Inside the BEAM — scheduling, heaps & soft-real-time GC` (teaching). Bridge: `The BEAM scheduler` (reduction budget then preemption) → `Elixir, today` (`spawn` is cheap; a slow function can't freeze the others). Running example: one long job vs two short jobs under run-to-completion vs preemptive scheduling. Real Elixir token: `spawn`.
4. `#otp-supervision` — dive `F0.2.3` · `OTP & the supervision tree — and the polyglot BEAM` (teaching / advanced). Bridge: `OTP supervision` → `Elixir, today` (`Supervisor.start_link(children, strategy: :one_for_one)`). Running example: a supervisor with three children A/B/C under three restart strategies. Names other BEAM languages — Erlang, Elixir, Gleam.
5. Synthesis — `What this lands` (no interactive; threads forward into F3.07–F3.08, F5.04, F6) followed by the pager.

## The interactives

- `<figure aria-labelledby="linTitle">` — title `The runtime · select a step`. Six SVG nodes `g.arc-node` carry `data-era="0"`..`"5"` (`role="button"`, `tabindex="0"`), node 0 default `.active`. Readout targets `#linNm`, `#linIdea`, `#linYear`, `#linWho`, `#linEcho`. Pure function `selectEra(i)` reads the `ERAS` table and writes those five ids. Timeline node labels (verbatim, year + name): `1986 Erlang`, `1998 Open / OTP`, `2006 SMP cores`, `2012 Elixir`, `2014 Phoenix`, `today Polyglot`. Default readout in markup: `#linNm` = `Erlang`, `#linIdea` = "A language for telephone switches: enormous concurrency, fault tolerance, soft real-time response, and upgrades without downtime.", `#linYear` = `1986`, `#linWho` = `Ericsson — Armstrong, Virding, Williams`, `#linEcho` = "these are still the runtime guarantees; Elixir inherits all of them unchanged."
- `<figure aria-labelledby="crashTitle">` — title `Let it crash · a worker that heals`. Control group (`role="group"`, `aria-label="Worker actions"`) with two buttons: `#workBtn` `data-c="sage"` (default active, label `send work · +1`) and `#crashBtn` `data-c="elixir"` (label `crash the worker`). SVG targets `#wrkBox`, `#wrkName`, `#wrkState`, `#supEdge`; readout `#crashOut` (`aria-live="polite"`). State held in `pid`, `state`, `restarts`, `justCrashed`; sending work increments `state`, crashing increments `pid`/`restarts` and resets `state` to 0. Readout default VERBATIM: "worker #1 · state since start = 0 · restarts = 0 · running".
- `<figure aria-labelledby="schedTitle">` — title `Reductions · one long job, two short jobs`. Control: range `#budget` (`budget`, 500–4000, step 500, default 2000, value label `#budgetval`). SVG bars `#barCoop` (run-to-done, burgundy) and `#barPre` (preemptive, sage); readout `#schedOut`. Pure logic recomputes the tick where the short job B finishes under each scheme against the budget (`TOTAL` drained near 10,600). Readout default VERBATIM: "first short job (B) finishes — run‑to‑done: **10,300** · preemptive (budget 2000): **2,300** ticks · both drain all work near 10,600".
- `<figure aria-labelledby="supTitle">` — title `Supervision · pick a strategy, crash a child`. Control group `#stratSel` (`role="group"`, `aria-label="Restart strategy"`) with `data-strat="one"` `data-c="elixir"` (default active, label `one_for_one`), `data-strat="all"` `data-c="blue"` (label `one_for_all`), `data-strat="rest"` `data-c="gold"` (label `rest_for_one`). Control group `#crashSel` (`role="group"`, `aria-label="Which child crashes"`) with `data-child="0"` (label `crash A`), `data-child="1"` (default active, label `crash B`), `data-child="2"` (label `crash C`). SVG children `#nc0`/`#nc1`/`#nc2` (A/B/C) with edges `#e0`/`#e1`/`#e2`; readout `#supOut`. Pure logic computes `restarted` / `untouched` from the strategy and the crashed child. Readout default VERBATIM: "B crashes · one_for_one → restarted: **B** · untouched: A, C". Deflist rows: `one_for_one`, `one_for_all`, `rest_for_one` (definitions as in markup).
- Degrade behaviour: no `.reveal` elements; the `html.js` enhancer is a no-op here. Each figure carries a static default readout in the markup so the page reads with JS off; the animated `.arc-flow` timeline dashes run only under `prefers-reduced-motion: no-preference`.
- Footer build-stamp decoder (`#stamp` / `#stampId`): real id `TSK0NZAppGUWCe`; markup-decoded timestamp `2026-05-30 08:43:27 UTC`. Same decoder (3-char `TSK` namespace + base62 snowflake, `EPOCH_MS = 1704067200000`, `ts >> 22`, `node = (snow >> 12) & 0x3FF`, `seq = snow & 0xFFF`).

## References (#refs, verbatim)

This page has no `#refs` References section — no intro line, no Sources list, and no "Related in this course" block. Forward cross-links live inline in the dive prose and takeaways instead (F3.07, F3.08, F5.04, F6, F6.09, and back to F0.1). The only `https://` links are the Google Fonts preconnect/stylesheet in `<head>`.

## Wiring

- route-tag (verbatim): `/ ` `elixir` ` / ` `course` ` / ` `beam-evolution` — markup `<span class="route-tag"><span class="rsep">/</span><a href="/elixir">elixir</a><span class="rsep">/</span><a href="/elixir/course">course</a><span class="rsep">/</span><span class="rcur">beam-evolution</span></span>`.
- crumbs (verbatim): `F0 · History` (links `/elixir/course`) `/` `F0.1` (links `/elixir/course/fp-evolution`) `/` `F0.2`.
- toc-mini: `F0.2.1 · let it crash` → `#telecom-roots`; `F0.2.2 · inside the BEAM` → `#inside-beam`; `F0.2.3 · the supervision tree` → `#otp-supervision`.
- pager: prev → `/elixir/course/fp-evolution` label `F0.1 · the languages`; next → `/elixir/algebra` label `Begin · F1 Algebra`.
- footer: three columns identical to the F0 landing. Brand logo → `/elixir` + the "taught twice" tagline. Column `Chapters`: `F1 · Algebra` → `/elixir/algebra`, `F2 · Functional Programming` → `/elixir/functional`, `F3 · The Elixir Language` → `/elixir/language`, `F4 · Algorithms & Data Structures` → `/elixir/algorithms`, `F5 · Pragmatic Programming` → `/elixir/pragmatic`, `F6 · Phoenix Framework` → `/elixir/phoenix`. Column `The course`: `Course home` → `/elixir`, `Contents & history` → `/elixir/course`, `Start · F1.01` → `/elixir/algebra/functions`. Foot bar: `© jonnify` + build stamp.
- Page meta — `<title>`: `The evolution of Erlang, the BEAM & OTP — F0.2 · jonnify`. `<meta name="description">`: "Telecom roots and "let it crash", the reduction-counting scheduler and per-process heaps, and the OTP supervision tree — the runtime Elixir stands on."

## Build instruction

To rebuild this page, copy the `<head>…</style>`, the `header.site`, the `footer.site-foot`, and the trailing `<script>` blocks (the timeline + the three interactives + the snowflake decoder, then the `html.js` enhancer) verbatim from the built F0 sibling `elixir/course/fp-evolution.html`; change only `<title>` / `<meta>`, the `route-tag` current segment, the crumbs, and the `<main>` body (the runtime timeline, the three dives with their bridge cells, and the synthesis). No-invent guards: present only the real runtime facts and the real Elixir surfaces they map to — the actual `ERAS` table (years, the Ericsson team, Armstrong/Virding/Williams, José Valim's Elixir, Phoenix, the polyglot BEAM of Erlang/Elixir/Gleam) and the real surfaces (`{:error, reason}`, `Supervisor`, `Supervisor.start_link(children, strategy: :one_for_one)`, `spawn`, the three restart strategies). Do not invent dates, names, routes, or APIs. Cite the companion course for OTP internals and cross-link forward (F3.07, F3.08, F5.04, F6.09) rather than re-teaching the runtime here. Voice rules: no first person, no exclamation marks, no emoji, none of "just" / "simply" / "obviously". Model sibling to copy from: `elixir/course/fp-evolution.html` (the other F0 dive — same head, footer, timeline-and-three-dives anatomy, and decoder script).
