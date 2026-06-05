# F6.08.2 — Releases & config (dive)

- **Route (served):** `/elixir/phoenix/deployment/releases`
- **File:** `elixir/phoenix/deployment/releases.html`
- **Place in the chapter:** the second of the three F6.08 dives (part 2 of 3). It packages the app — `mix release`, the compile-time-versus-`runtime.exs` config split, reading secrets from the environment, and migrating without `mix` via a `Portal.Release` command — after `auth` and before `deploy`. Belongs to the M3 "ship to users" arc.
- **Accent:** chapter accent blue (`--blue`); the `.ex` h1 span renders in `--elixir-bright` lilac.
- **Status:** built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F6.08 · part 2 of 3`.

Hero `h1` (verbatim): `Releases & config` (the `.ex` accent span wraps `config`).

Hero lede (`.lede`, verbatim): "A **release** is how an Elixir app ships. `mix release` assembles your compiled code, every dependency, and the **ERTS** — the Erlang runtime, the BEAM itself — into one self-contained directory that runs on a server with no Elixir or Erlang installed. It comes with a launcher, `bin/portal`, that can `start` the system, open a remote console, or run a one-off command. The subtlety that trips people is **configuration timing**. `config/config.exs` and `config/prod.exs` are read at *compile* time and baked into the artifact — good for fixed settings, wrong for secrets, which would then live in your build. `config/runtime.exs` is different: it is evaluated *every time the release boots*, on the server, so it can read environment variables for the database URL, the secret key base, and the host. That single distinction is most of release config. The last wrinkle is migrations: a release has no `mix`, so `mix ecto.migrate` is unavailable. Instead you add a tiny `Portal.Release` module and invoke it with `bin/portal eval`, which boots only enough of the app to run the migrator."

Kicker (`.kicker`, verbatim): "Four parts: what a release is, the compile-time-versus-runtime config split, reading the environment in `runtime.exs`, and running migrations without `mix`."

## Sections

Four teaching sections in order:

1. **`#what` — Release, runtime, command** — the three ideas (artifact, boot-time config, release command), with the interactive `#rlSel` selector.
2. **`#config` — Compile time vs boot time** — `config.exs`/`prod.exs` baked in at build versus `runtime.exs` evaluated at boot, with the `#rlConfigTitle` diagram.
3. **`#runtime` — Reading the environment** — `runtime.exs` guarded by `config_env()`, reading secrets with `System.fetch_env!/1`; a `pre.code` Elixir block.
4. **`#migrate` — Migrating without mix** — the `Portal.Release` module run via `bin/portal eval`; a `pre.code` Elixir block, a `.bridge` (fixed config → secrets & migrations), and the `.note` forward to `deploy`.

**Running example:** the Portal release — `mix release`, `bin/portal`, `config/runtime.exs`, `Portal.Repo`, `PortalWeb.Endpoint`, and a `Portal.Release` migrator over `Ecto.Migrator`.

**Real Elixir shown (`pre.code`, verbatim tokens):**
- `runtime.exs` (`#runtime`): `import Config`, then `if config_env() == :prod do … end` reading `System.fetch_env!("DATABASE_URL")`, configuring `Portal.Repo` with `url:` and `pool_size: 10`, and `PortalWeb.Endpoint` with `url: [host: System.fetch_env!("PHX_HOST"), port: 443, scheme: "https"], secret_key_base: System.fetch_env!("SECRET_KEY_BASE")`.
- `Portal.Release` (`#migrate`): `defmodule Portal.Release do @app :portal; def migrate do load_app(); for repo <- repos() do {:ok, _, _} = Ecto.Migrator.with_repo(repo, fn repo -> Ecto.Migrator.run(repo, :up, all: true) end) end end`, plus `defp repos`/`defp load_app` and the comment `# on the server, with no mix:  bin/portal eval "Portal.Release.migrate()"`.

## The interactives

### Section figure — "Releases · select one" (`#rlTitle`)

- **Figure:** `<figure class="fig" aria-labelledby="rlTitle">` in `#what`; `.solid-select#rlSel` (role group "Release concept").
- **Control buttons (data-k / label):** `release` ("mix release", starts `active`) · `runtime` ("runtime.exs") · `command` ("a release command"). Buttons carry no `data-c`.
- **SVG rect ids:** `#rlRow_release`, `#rlRow_runtime`, `#rlRow_command`.
- **Readouts:** `#rlOut` (`.geo-readout`, `aria-live`), plus `#rlRole` (default "mix release") and `#rlResult` (default "a self-contained artifact").
- **Pure function:** `pick(k)` — over `ORDER = ['release','runtime','command']` toggles each button's `active`/`aria-pressed` by `data-k === k`, sets each `#rlRow_*` rect on/off, writes `PARTS[k].name` into `#rlRole`, `PARTS[k].is` into `#rlResult`, and `'<b>'+name+'</b> — '+is+'. '+desc` into `#rlOut`. Initial call `pick('release')`.
- **`PARTS` readout dataset (`name` / `is` / `desc`, verbatim):**
  - release: name "mix release", is "a self-contained artifact", desc "mix release assembles your code, every dependency, and the BEAM into one directory that runs with no Elixir or Erlang installed, with a bin/portal launcher to start it or run commands."
  - runtime: name "runtime.exs", is "config read at boot, not compile", desc "config/runtime.exs is evaluated every time the release boots on the server, so it can read environment variables — the database URL, secret key base, host — that must not be baked into the build."
  - command: name "a release command", is "run code without mix", desc "A release has no mix, so one-off tasks run via bin/portal eval, which boots only enough of the app to execute a function — used to run migrations with a small Portal.Release module."

### Section figure — "build (baked in) → artifact → boot (reads env)" (`#rlConfigTitle`)

A static (no-control) diagram in `#config`: `<figure class="fig" aria-labelledby="rlConfigTitle">` showing BUILD TIME (`config.exs + prod.exs`, compiled in) → "the release" artifact → BOOT TIME (server) (`runtime.exs evaluated`, reads env for secrets & URLs), with the env box `DATABASE_URL · SECRET_KEY_BASE · PHX_HOST` and the note "secrets enter at boot, so the same artifact runs in any environment". No buttons; informational only.

### Degrade behaviour

The `#rlSel` figure ships its controls, SVG, and default `#rlOut`/`#rlRole`/`#rlResult` values in static markup; JS only enhances (`pick('release')` re-applies the default). The config figure is fully static. Animations respect `prefers-reduced-motion: reduce`; no browser storage. There is no References block on this dive (the module References live on the hub).

### Footer build-stamp decoder (`#stamp`)

- **Stamp id (`#stampId`):** `TSK0NdZT1YoR5k`; the static `#st-ts` reads "2026-06-02 00:18:34 UTC".
- **Pure functions:** `b62decode(s)`, `pad2(x)`, `decodeBranded(id)` — `ns = id.slice(0,3)`, `snow = b62decode(id.slice(3))`, `ts = snow >> 22n`, `node = (snow >> 12n) & 0x3FFn`, `seq = snow & 0xFFFn`, epoch `EPOCH_MS = 1704067200000`, formatting into `#st-ns`/`#st-snow`/`#st-node`/`#st-seq`/`#st-ts`; toggle on click / Enter / Space. Decoding `TSK0NdZT1YoR5k` yields the `2026-06-02 00:18:34 UTC` timestamp shown.

## References

This dive carries no `#refs` section. The F6.08 module References (Sources + "Related in this course") live on the hub at `/elixir/phoenix/deployment`. Note rather than fabricate: there is no per-dive References block here.

## Wiring

- **route-tag:** `<span class="rsep">/</span>elixir / phoenix / deployment / <span class="rcur">releases</span>` — segmented, `elixir`/`phoenix`/`deployment` linked, `releases` the current span; matches `/elixir/phoenix/deployment/releases`.
- **crumbs:** `F6` → `/elixir/phoenix` · sep `/` · `F6.08` → `/elixir/phoenix/deployment` · sep `/` · here `releases` (no link).
- **toc-mini:** `#what` ("Release, runtime, command") · `#config` ("Compile time vs boot time") · `#runtime` ("Reading the environment") · `#migrate` ("Migrating without mix").
- **pager:** prev → `/elixir/phoenix/deployment/auth` ("← F6.08.1 · sessions & authentication"); next → `/elixir/phoenix/deployment/deploy` ("Next · deploying to production →").
- **footer (`foot-nav`, 3-column):** identical to the hub — brand `.foot-logo` → `/elixir` with the "Functional Programming in Elixir…" `.foot-tag`; Chapters column `/elixir/algebra`…`/elixir/phoenix` (F1–F6); The course column `/elixir`, `/elixir/course`, `/elixir/algebra/functions` ("Start · F1.01").
- **Page meta:** `<title>` "Releases & config — F6.08.2 · jonnify"; `<meta description>` "mix release packages the app, its dependencies, and the BEAM into one self-contained artifact. config/runtime.exs is evaluated at boot and reads env vars for secrets and the database URL, distinct from compile-time config, and a release has no mix, so migrations run through a small release command module."

## Build instruction

To rebuild this dive, copy the `<head>`…`</style>`, the `<header class="site">`, the `<footer class="site-foot">`, and both trailing `<script>` blocks verbatim from a recent built F6 (blue-accent) dive sibling; change only `<title>`/`<meta>`, the segmented `.route-tag` (`releases` current), and the `<main>` body (hero, the four `#what`/`#config`/`#runtime`/`#migrate` sections, the two figures, the two `pre.code` blocks, the `.bridge`, and the pager). No-invent guards: use only the real Portal surfaces as written — `mix release`, `bin/portal`, `config/runtime.exs`, `config_env()`, `System.fetch_env!/1`, `Portal.Repo`, `PortalWeb.Endpoint`, the `Portal.Release` migrator over `Ecto.Migrator`; the web layer calls only the `Portal` facade and renders only the closed `%Portal.Error{}` set, and never names `Portal.Engine`, a repo, or `GenServer.call` from the web. Cite the companion course for OTP/BEAM internals rather than re-teaching them. Voice rules: no first person, no exclamation marks, no emoji, and none of "just"/"simply"/"obviously". Model sibling to copy from: `elixir/phoenix/deployment/auth.html` (the preceding dive in this module).
