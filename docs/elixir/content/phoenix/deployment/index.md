# F6.08 — Auth, deployment & going live (module hub)

- **Route (served):** `/elixir/phoenix/deployment`
- **File:** `elixir/phoenix/deployment/index.html`
- **Place in the chapter:** the F6.08 module hub of the F6 · Phoenix Framework chapter — the M3 "ship to users" rung. It frames the three deep dives that take the whole supervised system to production (`auth`, `releases`, `deploy`), follows F6.07 (`/elixir/phoenix/pubsub`), and hands off to the chapter capstone F6.09 (`/elixir/phoenix/live-dashboard`).
- **Accent:** chapter accent blue (`--blue` / `--blue-bright`); the `.ex` h1 span renders in the course `--elixir-bright` lilac.
- **Status:** built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F6 · the architecture · module 8`.

Hero `h1` (verbatim): `Auth, deployment & going live` (the `.ex` accent span wraps `going live`).

Hero lede (`.lede`, verbatim): "Everything built so far — the F5 engine, the contexts, the controllers, LiveView, PubSub and Presence — now has to run as one supervised system in production, and three concerns stand between a working app and a live one. First, the app must know **who the user is**: sessions and authentication, which in Phoenix is a generated *context* plus a signed-cookie session and a plug, not a special subsystem. Second, the app must be **packaged to run** on a server with no Elixir toolchain present: a `mix release` bundles your code, its dependencies, and the BEAM itself into one self-contained artifact, with secrets supplied at boot through `runtime.exs` rather than baked in at compile time. Third, it must actually **go live**: build the release, run pending migrations through a release command (there is no `mix` on the server), and boot the supervision tree so the endpoint serves — with the nodes clustered so the F6.07 broadcasts and presence span every machine. None of this replaces what you built; it wraps the same tree from F5 in the operational concerns that make it a real, running platform."

Kicker (`.kicker`, verbatim): "Three dives: sessions and authentication, releases and runtime config, and the deploy itself — the same supervised system from F5, now in production."

## What the page frames

The hub presents F6.08 as three deep dives (the `.dives`-style card list, here authored as three full-width `<a>` cards in the `#dives` section), each on its own accent colour:

- **F6.08.1 · Sessions & authentication** — `mix phx.gen.auth`, the signed-cookie session, a `fetch_current_user` plug, and `on_mount` for LiveView. Route `/elixir/phoenix/deployment/auth`. Built. (left-border accent `--blue`.)
- **F6.08.2 · Releases & config** — `mix release`, compile-time versus `runtime.exs`, and running migrations without `mix`. Route `/elixir/phoenix/deployment/releases`. Built. (left-border accent `--gold`.)
- **F6.08.3 · Deploying to production** — The build-migrate-boot sequence, the supervision tree in production, and clustering so PubSub and Presence span nodes. Route `/elixir/phoenix/deployment/deploy`. Built. (left-border accent `--sage`.)

The hub has three framing sections before the dive cards: `#pieces` ("Three concerns of going live"), `#prod` ("What runs in production"), and `#dives` ("Three deep dives"). A `.bridge` at the foot pairs "F5 supervised it" → "F6.08 ships it", and the `.note` orders the reading: start with `auth`, then `releases`, then `deploy`; the chapter closes with F6.09.

## The interactives

### Hero figure — "Going live · build, migrate, boot" (`#hpTitle`)

- **Figure:** `<figure class="hero-fig" aria-labelledby="hpTitle">`; figcaption `.fc-lbl` text "Going live · build, migrate, boot".
- **SVG ids:** the moving marker `#hpTok` (`.hp-tok`); three stage groups `#hpStage_build`, `#hpStage_migrate`, `#hpStage_boot`; the terminal `#hpServe` ("the endpoint serves — live").
- **Controls (`.hp-ctrls`):** `#hpAdv` ("▸ advance") and `#hpReset` ("reset", `.ghost`). Readout `#hpCap` (`aria-live="polite"`).
- **Pure function:** `paint()` — moves `#hpTok`'s `cy` to the current stage centre, sets each stage rect's stroke/fill on/off, lights `#hpServe` green only when `boot` is reached, and writes the stage caption into `#hpCap`. `advBtn` advances `at = (at + 1) % PATH.length` (wraps build→migrate→boot→build); `resetBtn` returns `at = 0`. No paint on load — the static SVG already shows the deploy at the `build` stage.
- **Caption strings (`PATH[].cap` + the appended `ART`, verbatim):**
  - build: "`build` — compile the release into a runnable image."
  - migrate: "`migrate` — run pending migrations through a release command, with no mix on the server."
  - boot: "`boot` — start the supervision tree from F5; the endpoint serves and the app is live."
  - `ART` (appended to every caption): "mix release packages the app, its deps, and the BEAM into one artifact."
- **Static default `#hpCap` in markup (verbatim):** "`build` — compile the release into a runnable image. / mix release packages the app, its deps, and the BEAM into one artifact."

### Section figure — "Going live · select a concern" (`#dpTitle`)

- **Figure:** `<figure class="fig" aria-labelledby="dpTitle">` in `#pieces`; `.solid-select#dpSel` (role group "Production concern").
- **Control buttons (data-k / label):** `auth` ("auth", starts `active`) · `release` ("release") · `deploy` ("deploy"). Buttons carry no `data-c`.
- **SVG rect ids:** `#dpRow_auth`, `#dpRow_release`, `#dpRow_deploy`.
- **Readouts:** `#dpOut` (`.geo-readout`, `aria-live`), plus `#dpRole` (default "authentication") and `#dpResult` (default "know who the user is").
- **Pure function:** `pick(k)` — over `ORDER = ['auth','release','deploy']` toggles each button's `active`/`aria-pressed` by `data-k === k`, sets each `#dpRow_*` rect stroke/width/fill on/off, writes `PARTS[k].name` into `#dpRole`, `PARTS[k].does` into `#dpResult`, and `'<b>'+name+'</b> — '+does+'. '+desc` into `#dpOut`. Initial call `pick('auth')`.
- **`PARTS` readout dataset (`name` / `does` / `desc`, verbatim):**
  - auth: name "authentication", does "know who the user is", desc "Authentication is a generated Accounts context plus a signed-cookie session and a plug that loads the current user into conn.assigns. It is ordinary domain code, not a separate subsystem."
  - release: name "a release", does "package the app to run", desc "mix release bundles your app, its dependencies, and the BEAM into one self-contained artifact that runs on a server with no Elixir installed, with secrets supplied at boot by runtime.exs."
  - deploy: name "deployment", does "boot it in production", desc "Deployment is build, migrate, boot: compile the release, run pending migrations through a release command, and start the supervision tree so the endpoint serves — clustered across nodes."

### Section figure — "release artifact → boot → supervised, serving" (`#dpProdTitle`)

A static (no-control) diagram in `#prod`: `<figure class="fig" aria-labelledby="dpProdTitle">` showing the release artifact (`app + deps + BEAM`) → `runtime.exs` (reads `DATABASE_URL, SECRET, PHX_HOST`) → the F5 supervision tree (`Repo`, `Endpoint`, `PubSub + Presence`, `Portal.Engine`) → "serves users · HTTPS", with the caption "clustered across nodes, PubSub and Presence span every machine — the same code as one node". No buttons; informational only.

### Degrade behaviour

Both interactive figures ship their full controls, SVG, and the default readout/caption in static markup; JS only enhances (`pick('auth')` re-applies the default; the hero leaves the static `build` stage in place on load). The hero token transition is gated behind `@media (prefers-reduced-motion: no-preference)` and the `.arc-flow`/reveal animations respect `prefers-reduced-motion: reduce`. No browser storage is used. The `.reveal` References section is visible without JS.

### Footer build-stamp decoder (`#stamp`)

- **Stamp id (`#stampId`):** `TSK0NdZT0vdn8q`; the static `#st-ts` reads "2026-06-02 00:18:34 UTC".
- **Pure functions:** `b62decode(s)` (base62 over `"0123…XYZabc…xyz"` → BigInt); `pad2(x)`; `decodeBranded(id)` — `ns = id.slice(0,3)`, `snow = b62decode(id.slice(3))`, then `ts = snow >> 22n`, `node = (snow >> 12n) & 0x3FFn`, `seq = snow & 0xFFFn`, epoch `EPOCH_MS = 1704067200000`, formatting a UTC timestamp into `#st-ns`/`#st-snow`/`#st-node`/`#st-seq`/`#st-ts`. Toggle on click / Enter / Space sets `.open` + `aria-expanded`. Decoding `TSK0NdZT0vdn8q` yields the `2026-06-02 00:18:34 UTC` timestamp shown.

## References (`#refs`, verbatim)

Intro line: "Generated authentication, releases, runtime config, and going to production."

**Sources**
- Phoenix — mix phx.gen.auth → `https://hexdocs.pm/phoenix/mix_phx_gen_auth.html` — the generated authentication system.
- Phoenix — Deploying with releases → `https://hexdocs.pm/phoenix/releases.html` — release-based deployment.
- Mix — mix release → `https://hexdocs.pm/mix/Mix.Tasks.Release.html` — assembling a release and runtime config.
- Phoenix — Deployment → `https://hexdocs.pm/phoenix/deployment.html` — going to production.

**Related in this course**
- F6.08.1 · Sessions & authentication → `/elixir/phoenix/deployment/auth`
- F6.08.2 · Releases & config → `/elixir/phoenix/deployment/releases`
- F6.08.3 · Deploying to production → `/elixir/phoenix/deployment/deploy`
- F6.07 · PubSub → `/elixir/phoenix/pubsub` — clustered across nodes in production.
- F6 · Phoenix Framework → `/elixir/phoenix`

## Wiring

- **route-tag:** `<span class="rsep">/</span>elixir / phoenix / <span class="rcur">deployment</span>` — segmented, `elixir` and `phoenix` linked, `deployment` the current span; matches `/elixir/phoenix/deployment`.
- **crumbs:** `F6 · Phoenix Framework` → `/elixir/phoenix` · sep `/` · here `F6.08 · deployment` (no link).
- **toc-mini:** `#pieces` ("Three concerns of going live") · `#prod` ("What runs in production") · `#dives` ("Three deep dives").
- **pager:** prev → `/elixir/phoenix/pubsub` ("← F6.07 · PubSub"); next → `/elixir/phoenix/deployment/auth` ("Start · sessions & authentication →").
- **footer (`foot-nav`, 3-column):**
  - brand: `.foot-logo` → `/elixir`; `.foot-tag` "Functional Programming in Elixir — functional thinking taught twice: first as mathematics, then as idiomatic Elixir."
  - Chapters column: `/elixir/algebra` ("F1 · Algebra"), `/elixir/functional` ("F2 · Functional Programming"), `/elixir/language` ("F3 · The Elixir Language"), `/elixir/algorithms` ("F4 · Algorithms & Data Structures"), `/elixir/pragmatic` ("F5 · Pragmatic Programming"), `/elixir/phoenix` ("F6 · Phoenix Framework").
  - The course column: `/elixir` ("Course home"), `/elixir/course` ("Contents & history"), `/elixir/algebra/functions` ("Start · F1.01").
  - Header `.brand` and nav `Contents` link `/elixir` and `/elixir/course`.
- **Page meta:** `<title>` "Auth, deployment & going live — F6.08 · jonnify"; `<meta description>` "Taking the whole application to production: sessions and authentication so the app knows who the user is, releases and runtime config that package it to run, and the deploy itself — build, migrate, boot — with clustering so the F6.07 PubSub and Presence span every node. Three dives over the same supervised system from F5, now live in production."

## Build instruction

To rebuild this hub, copy the `<head>`…`</style>`, the `<header class="site">`, the `<footer class="site-foot">`, and both trailing `<script>` blocks verbatim from a recent built F6 (blue-accent) sibling hub — the closest model is `elixir/phoenix/pubsub/index.html` (the preceding F6.07 module hub); change only `<title>`/`<meta>`, the segmented `.route-tag` (`deployment` current), and the `<main>` body (hero, the `#pieces`/`#prod`/`#dives` sections, the dive cards, the `.bridge`, the `#refs` block, and the pager). No-invent guards: use only the real Portal surfaces as written — the branded store, the event-sourced engine behind ONE `Portal` facade, the Phoenix web app (`PortalWeb.Endpoint`, the contexts, `runtime.exs`, `Portal.Release`, `bin/portal`); the web layer renders only the closed `%Portal.Error{}` set and never names `Portal.Engine`, a repo, or `GenServer.call`. Cite the companion course for OTP internals (supervision, the BEAM) rather than re-teaching them. Voice rules: no first person, no exclamation marks, no emoji, and none of "just"/"simply"/"obviously". Model sibling to copy from: `elixir/phoenix/pubsub/index.html`.
