# F3.08.3 — Supervisors & restart strategies (dive)

- Route (served): `/elixir/language/otp/supervisors`
- File: `elixir/language/otp/supervisors.html`
- Place in the chapter: the third and last of the three F3.08 dives, part 3 of 3. It closes the OTP arc after F3.08.1 (the GenServer behaviour) and F3.08.2 (call & cast), turning process isolation into recovery, and hands off to F3.09 (the playground lab).
- Accent: elixir (purple) — `--elixir:#b39ddb` / `--elixir-bright:#cdb8f0`.
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F3.08 · part 3 of 3`

H1 (verbatim): `Supervisors & restart strategies`

Hero lede (verbatim):

> Isolation (F3.07) means a crash stays local; a supervisor turns that into recovery. A Supervisor starts a set of child processes and, when one crashes, restarts it by a strategy. `:one_for_one` restarts only the failed child; `:one_for_all` restarts them all; `:rest_for_one` restarts the failed child and those started after it.

Kicker (verbatim):

> This is "let it crash": rather than defend every line, let a process die on a bad state and be restarted clean. The portal supervises a tally, a notifier, and a cache. The notifier crashes — choose a strategy and see who else restarts.

## Sections

In order:

1. `#strategies` — "When a child crashes" — the teaching section around the interactive strategy picker. Prose: children start in order (tally, notifier, cache); the notifier crashes; the strategy decides which siblings restart — none, all, or only those started afterward.
2. `#tree` — "Building the tree" — the applied section. Shows the supervisor module verbatim, then a `bridge` ("isolate it, then recover by starting fresh") and a `.note` that closes OTP and names the next module, F3.09.

Running example: a `Portal.Supervisor` over three children — `Portal.Tally`, `Portal.Notifier`, `Portal.Cache`.

Real Elixir code shown (the `#tree` block, verbatim from the page):

```
defmodule Portal.Supervisor do
  use Supervisor

  def start_link(_), do: Supervisor.start_link(__MODULE__, :ok)

  @impl true
  def init(:ok) do
    children = [
      Portal.Tally,
      Portal.Notifier,
      Portal.Cache
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
```

## The interactives

One interactive figure: `figure.fig`, labelled by `#svTitle` "The restart strategy · select one". Control group `#svSel` (role `group`, aria-label "The restart strategy"), three buttons:
- `data-k="one_for_one"` `data-c="elixir"` (active by default) — label `:one_for_one`
- `data-k="one_for_all"` `data-c="blue"` — label `:one_for_all`
- `data-k="rest_for_one"` `data-c="gold"` — label `:rest_for_one`

SVG element ids: the supervisor `#svSup`; the three children `#svC0` (Tally, child 1), `#svC1` (Notifier, child 2, always the crasher), `#svC2` (Cache, child 3); their status labels `#svS0`, `#svS1`, `#svS2`. Live code block `#svCode` and readout `#svOut` are rewritten on each pick.

Pure functions: `paint(rectId, lblId, spec)` sets a child rect's stroke and its status label text/fill; `pick(k)` looks up `CASES[k]`, paints children 0 and 2, forces child 1 to `crashed → restarted` (err colour), and sets `#svCode` and `#svOut`. Child statuses per strategy (child 1 is always `crashed → restarted`):
- `one_for_one` — child 0 `alive` (sage), child 2 `alive` (sage). Code: `Supervisor.init(children, strategy: :one_for_one)` / `# Notifier crashes → only Notifier restarts` / `# Tally and Cache keep running`. Out: "Under `:one_for_one`, only the crashed child restarts. Tally and Cache are untouched — the right choice when children are independent."
- `one_for_all` — child 0 `restarted` (gold), child 2 `restarted` (gold). Code: `Supervisor.init(children, strategy: :one_for_all)` / `# Notifier crashes → all three restart together` / `# use when the children share state and must stay consistent`. Out: "Under `:one_for_all`, one crash restarts every child. Choose it when the children depend on each other so closely that a partial restart would leave the group inconsistent."
- `rest_for_one` — child 0 `alive` (sage), child 2 `restarted` (gold). Code: `Supervisor.init(children, strategy: :rest_for_one)` / `# Notifier crashes → Notifier and Cache (started after it) restart` / `# Tally (started before) keeps running`. Out: "Under `:rest_for_one`, the crashed child and everything started after it restart. Tally came first and survives; Cache came later and restarts — the choice when children depend on the ones before them."

Static default in markup: the `:one_for_one` outcome — `#svS0` (Tally) `alive`, `#svS1` (Notifier) `crashed → restarted`, `#svS2` (Cache) `alive`.

Takeaway (`.take`, verbatim): "The crashed child always comes back; the strategy is only about its siblings. Pick the one that matches how the children depend on each other — independent, all-or-nothing, or ordered."

Degrade behaviour: the figure carries the `:one_for_one` defaults in the static SVG markup and reads without JS. The `.reveal` references section shows immediately when `IntersectionObserver` is absent or under `prefers-reduced-motion: reduce`.

Footer build-stamp decoder: `#stamp` holds id `TSK0NbRgGFlrua`; `decodeBranded` splits namespace `TSK` from the base-62 Snowflake with `EPOCH_MS = 1704067200000`. The static fallback timestamp in markup is `2026-05-31 17:34:24 UTC`.

## References (#refs, verbatim)

Intro line: "Primary sources for this lesson, and where it connects in the course."

Sources:
- `Supervisor` — Elixir documentation — `https://hexdocs.pm/elixir/Supervisor.html` — strategies, child specs, and restarts.
- `GenServer` — Elixir documentation — `https://hexdocs.pm/elixir/GenServer.html` — the stateful server a supervisor restarts.
- Mix & OTP: GenServer — Elixir documentation — `https://hexdocs.pm/elixir/genservers.html` — building one step by step.

Related in this course:
- `/elixir/language/otp/genserver` — F3.08.1 · GenServer — the supervised child
- `/elixir/language/otp/call-cast` — F3.08.2 · call & cast
- `/elixir/language/processes` — F3.07 · Processes & the actor model

## Wiring

- route-tag (verbatim): `/` `elixir` `/` `language` `/` `otp` `/` `supervisors` — `elixir`, `language`, `otp` link to `/elixir`, `/elixir/language`, `/elixir/language/otp`; `supervisors` is the current segment (`.rcur`).
- crumbs (verbatim): `F3` (→ `/elixir/language`) `/` `F3.08` (→ `/elixir/language/otp`) `/` `supervisors` (here).
- toc-mini: `#strategies` "When a child crashes"; `#tree` "Building the tree".
- pager: prev → `/elixir/language/otp/call-cast` label `← F3.08.2 · call-cast`; next → `/elixir/language` label `Back to F3 · The Elixir Language →`.
- footer columns: Chapters — `/elixir/algebra` (F1 · Algebra), `/elixir/functional` (F2 · Functional Programming), `/elixir/language` (F3 · The Elixir Language), `/elixir/algorithms` (F4 · Algorithms & Data Structures), `/elixir/pragmatic` (F5 · Pragmatic Programming), `/elixir/phoenix` (F6 · Phoenix Framework). The course — `/elixir` (Course home), `/elixir/course` (Contents & history), `/elixir/algebra/functions` (Start · F1.01).
- Page meta: `<title>` = `Supervisors &amp; restart strategies — F3.08.3 · jonnify`; `<meta name="description">` = "A supervisor starts child processes and restarts them when they crash, by strategy — one_for_one, one_for_all, or rest_for_one — turning process isolation into recovery: the let-it-crash model."

## Build instruction

To rebuild this dive, copy the `<head>…</style>`, the `header.site`, the `footer.site-foot`, and the trailing two `<script>` blocks (the figure picker plus the Branded-Snowflake decoder, and the reveal-on-scroll enhancer) verbatim from a recent BUILT sibling on this chapter accent; the model sibling to copy from is the adjacent dive `elixir/language/otp/call-cast.html` (the same F3.08 dive layout — hero `crumbs`/`eyebrow`/`lede`/`kicker`, one `solid-select` figure with a live `pre.code` plus `geo-readout`, a code-only applied section with a `bridge`, then refs + pager — and like this page it has no `.note` next-link beyond closing the arc). Change only `<title>` / `<meta description>`, the `route-tag` (current segment `supervisors`), the `crumbs`/`eyebrow`, and the `<main>` body; this is the last dive, so the pager's next returns to `/elixir/language`. No-invent guards: use only the real OTP surfaces as written — `use Supervisor`, `Supervisor.start_link/2`, `Supervisor.init/2` with `strategy:`, the three strategy atoms `:one_for_one` / `:one_for_all` / `:rest_for_one`, and the running example `Portal.Supervisor` over `Portal.Tally` / `Portal.Notifier` / `Portal.Cache`; cite the linked HexDocs Supervisor page for restart-limit and child-spec internals and do not re-teach them; do not invent a route, id, readout string, code token, or reference URL. Voice rules: no first person, no exclamation marks, no emoji, and none of just/simply/obviously.
