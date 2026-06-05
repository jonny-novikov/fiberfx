# F6.08.3 — Deploying to production (dive)

- **Route (served):** `/elixir/phoenix/deployment/deploy`
- **File:** `elixir/phoenix/deployment/deploy.html`
- **Place in the chapter:** the third and last F6.08 dive (part 3 of 3). It runs the deploy — build, migrate, boot — shows the F5 supervision tree in production, and clusters the nodes so the F6.07 PubSub and Presence span the cluster. It closes the module (pager loops back to the hub); the chapter then closes with F6.09. Belongs to the M3 "ship to users" arc.
- **Accent:** chapter accent blue (`--blue`); the `.ex` h1 span renders in `--elixir-bright` lilac.
- **Status:** built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F6.08 · part 3 of 3`.

Hero `h1` (verbatim): `Deploying to production` (the `.ex` accent span wraps `production`).

Hero lede (`.lede`, verbatim): "With auth in place and a release configured, deploying is three steps in order: **build** the release, **migrate** the database, **boot** the system. Building runs `mix release` to produce the artifact from F6.08.2. Migrating runs the `Portal.Release` command against the live database before the new code serves traffic, so the schema is ready. Booting starts `bin/portal`, which evaluates `runtime.exs` to read the environment and then starts the application's **supervision tree** — and this is the moment the whole course pays off. The tree is the same one from F5: it starts the Repo, the Endpoint, PubSub, Presence, and the engine in order, and if any child crashes it restarts under the supervisor's strategy. You do not start processes by hand or write health checks to revive them; the tree is the health model. The last production concern is scale: running more than one node means **clustering** them so the F6.07 broadcasts and Presence reach across machines, which a library like libcluster handles by connecting the nodes — after which the exact same broadcast code spans the cluster. Build, migrate, boot, and the platform is live."

Kicker (`.kicker`, verbatim): "Four parts: the three deploy steps, the supervision tree in production, clustering for PubSub and Presence, and the deploy as a sequence of commands."

## Sections

Four teaching sections in order:

1. **`#steps` — Build, migrate, boot** — the three ordered steps, with the interactive `#dySel` selector.
2. **`#tree` — The tree in production** — `Portal.Supervisor` (`one_for_one`) starting Repo, Endpoint, PubSub, Presence, engine and restarting a crashed child, with the `#dyTreeTitle` diagram.
3. **`#cluster` — Clustering the nodes** — `libcluster` joining nodes (a Kubernetes strategy) so a broadcast on `"courses"` reaches every node; a `pre.code` Elixir block.
4. **`#checklist` — The deploy, end to end** — the three deploy commands; a `pre.code` shell block, a `.bridge` (three steps → one running tree), and the `.note` forward to F6.09.

**Running example:** the Portal deploy — `MIX_ENV=prod mix release`, `bin/portal eval "Portal.Release.migrate()"`, `bin/portal start`, the `Portal.Supervisor` tree, and `libcluster` topology `portal`.

**Real code shown (`pre.code`, verbatim tokens):**
- `libcluster` (`#cluster`): `config :libcluster, topologies: [ portal: [ strategy: Cluster.Strategy.Kubernetes, config: [service: "portal-headless", application_name: "portal"] ] ]`, plus the comment "once clustered, a broadcast on "courses" reaches subscribers on every node".
- The deploy (`#checklist`, shell): `MIX_ENV=prod mix release` (# 1. build the self-contained artifact), `bin/portal eval "Portal.Release.migrate()"` (# 2. run migrations (no mix on the server)), `bin/portal start` (# 3. boot: runtime.exs reads env, the tree serves).

## The interactives

### Section figure — "The deploy · select a step" (`#dyTitle`)

- **Figure:** `<figure class="fig" aria-labelledby="dyTitle">` in `#steps`; `.solid-select#dySel` (role group "Deploy step").
- **Control buttons (data-k / label):** `build` ("build", starts `active`) · `migrate` ("migrate") · `boot` ("boot"). Buttons carry no `data-c`.
- **SVG rect ids:** `#dyRow_build`, `#dyRow_migrate`, `#dyRow_boot`.
- **Readouts:** `#dyOut` (`.geo-readout`, `aria-live`), plus `#dyRole` (default "build") and `#dyResult` (default "compile the release artifact").
- **Pure function:** `pick(k)` — over `ORDER = ['build','migrate','boot']` toggles each button's `active`/`aria-pressed` by `data-k === k`, sets each `#dyRow_*` rect on/off, writes `PARTS[k].name` into `#dyRole`, `PARTS[k].does` into `#dyResult`, and `'<b>'+name+'</b> — '+does+'. '+desc` into `#dyOut`. Initial call `pick('build')`.
- **`PARTS` readout dataset (`name` / `does` / `desc`, verbatim):**
  - build: name "build", does "compile the release artifact", desc "MIX_ENV=prod mix release compiles your code and the BEAM into the self-contained artifact from F6.08.2 — the thing you ship to the server."
  - migrate: name "migrate", does "run pending migrations on deploy", desc "bin/portal eval "Portal.Release.migrate()" applies pending migrations against the live database before the new code serves traffic, so the schema is ready first."
  - boot: name "boot", does "start the supervision tree and serve", desc "bin/portal start evaluates runtime.exs to read the environment and then starts the application supervision tree — Repo, Endpoint, PubSub, Presence, engine — which serves and self-heals."

### Section figure — "one supervisor → supervised children, restarted on crash" (`#dyTreeTitle`)

A static (no-control) diagram in `#tree`: `<figure class="fig" aria-labelledby="dyTreeTitle">` showing `Portal.Supervisor` (`one_for_one · starts in order`) over its supervised children, with each child restarted on crash. No buttons; informational only.

### Degrade behaviour

The `#dySel` figure ships its controls, SVG, and default `#dyOut`/`#dyRole`/`#dyResult` values in static markup; JS only enhances (`pick('build')` re-applies the default). The tree figure is fully static. Animations respect `prefers-reduced-motion: reduce`; no browser storage. There is no References block on this dive (the module References live on the hub).

### Footer build-stamp decoder (`#stamp`)

- **Stamp id (`#stampId`):** `TSK0NdZT1s79w8`; the static `#st-ts` reads "2026-06-02 00:18:34 UTC".
- **Pure functions:** `b62decode(s)`, `pad2(x)`, `decodeBranded(id)` — `ns = id.slice(0,3)`, `snow = b62decode(id.slice(3))`, `ts = snow >> 22n`, `node = (snow >> 12n) & 0x3FFn`, `seq = snow & 0xFFFn`, epoch `EPOCH_MS = 1704067200000`, formatting into `#st-ns`/`#st-snow`/`#st-node`/`#st-seq`/`#st-ts`; toggle on click / Enter / Space. Decoding `TSK0NdZT1s79w8` yields the `2026-06-02 00:18:34 UTC` timestamp shown.

## References

This dive carries no `#refs` section. The F6.08 module References (Sources + "Related in this course") live on the hub at `/elixir/phoenix/deployment`. Note rather than fabricate: there is no per-dive References block here.

## Wiring

- **route-tag:** `<span class="rsep">/</span>elixir / phoenix / deployment / <span class="rcur">deploy</span>` — segmented, `elixir`/`phoenix`/`deployment` linked, `deploy` the current span; matches `/elixir/phoenix/deployment/deploy`.
- **crumbs:** `F6` → `/elixir/phoenix` · sep `/` · `F6.08` → `/elixir/phoenix/deployment` · sep `/` · here `deploy` (no link).
- **toc-mini:** `#steps` ("Build, migrate, boot") · `#tree` ("The tree in production") · `#cluster` ("Clustering the nodes") · `#checklist` ("The deploy, end to end").
- **pager:** prev → `/elixir/phoenix/deployment/releases` ("← F6.08.2 · releases & config"); next → `/elixir/phoenix/deployment` ("Back to F6.08 · overview →").
- **footer (`foot-nav`, 3-column):** identical to the hub — brand `.foot-logo` → `/elixir` with the "Functional Programming in Elixir…" `.foot-tag`; Chapters column `/elixir/algebra`…`/elixir/phoenix` (F1–F6); The course column `/elixir`, `/elixir/course`, `/elixir/algebra/functions` ("Start · F1.01").
- **Page meta:** `<title>` "Deploying to production — F6.08.3 · jonnify"; `<meta description>` "The deploy is build, migrate, boot: compile the release, run pending migrations with a release command, then start the supervision tree so the endpoint serves over HTTPS. Clustering connects the nodes so the F6.07 PubSub and Presence span the whole cluster, and the F5 supervision tree keeps it alive."

## Build instruction

To rebuild this dive, copy the `<head>`…`</style>`, the `<header class="site">`, the `<footer class="site-foot">`, and both trailing `<script>` blocks verbatim from a recent built F6 (blue-accent) dive sibling; change only `<title>`/`<meta>`, the segmented `.route-tag` (`deploy` current), and the `<main>` body (hero, the four `#steps`/`#tree`/`#cluster`/`#checklist` sections, the two figures, the two `pre.code` blocks, the `.bridge`, and the pager). No-invent guards: use only the real Portal surfaces as written — `MIX_ENV=prod mix release`, `bin/portal eval "Portal.Release.migrate()"`, `bin/portal start`, `runtime.exs`, the `Portal.Supervisor` tree (Repo, Endpoint, PubSub, Presence, engine), and `libcluster` topology `portal`; the web layer calls only the `Portal` facade and renders only the closed `%Portal.Error{}` set, and never names `Portal.Engine`, a repo, or `GenServer.call` from the web. Cite the companion course for OTP/BEAM internals (supervision strategy, distribution) rather than re-teaching them. Voice rules: no first person, no exclamation marks, no emoji, and none of "just"/"simply"/"obviously". Model sibling to copy from: `elixir/phoenix/deployment/releases.html` (the preceding dive in this module).
