# F3.02.3 — Branching with case, with & guards (dive)

- Route (served): `/elixir/language/match/branching`
- File: `elixir/language/match/branching.html`
- Place in the chapter: part 3 of 3 in module F3.02 (Pattern matching) — the closing dive. It shows matching choosing what runs next: function heads, `case`, guards, and the `with` pipeline that runs the whole Portal sign-in. It completes F3.02 and hands off to F3.03.
- Accent: elixir (purple), `--elixir` / `--elixir-bright`.
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow: `F3.02 · part 3 of 3`

H1: Branching with case, with & guards

Hero lede (verbatim):

> Matching earns its keep when it chooses what runs next. Function heads match arguments to pick a clause; `case` matches a value against several patterns; `with` chains matches and stops at the first that fails; and guards add conditions with `when`.

Kicker line (verbatim):

> The portal's sign-in is a sequence of steps that can each fail: verify the magic-link token, load the learner, start a session. That is exactly the shape `with` was made for — a happy path of successful matches, and one place to handle whatever went wrong.

## Sections

In order:

1. `The sign-in flow` (`#flow`) — the teaching section. The reader toggles any of three `with` steps to fail and watches where the pipeline short-circuits to `else`. Carries the interactive figure.
2. `The four forms` (`#forms`) — the advanced section. Shows the same matching driving function heads, `case`, and guards, as a static `pre.code`. Includes an F1→F3 `.bridge` (equations by cases → matching dispatch).

Running example: the Portal's three-step sign-in — `verify(token)` → `load_user(claims)` → `start_session(user)` — as a `with` pipeline, plus the progress-event `handle/1` clauses.

Real Elixir shown (verbatim from the static `pre.code` in `#forms`):
- function heads — `def handle({:lesson_completed, user_id, lesson_id}), do: Progress.mark(user_id, lesson_id)` and `def handle({:lesson_started, _user_id, _lesson_id}), do: :ok`.
- case — `case Portal.Auth.verify(token) do` / `{:ok, claims} -> sign_in(claims)` / `{:error, reason} -> deny(reason)` / `end`.
- guard — `def valid?(%{exp: exp}) when exp > now(), do: true`.

The interactive figure additionally renders the `with` block live: `with {:ok, claims} <- verify(token), {:ok, user} <- load_user(claims), {:ok, sess} <- start_session(user) do {:ok, sess} else {:error, reason} -> {:error, reason} end`.

## The interactives

### `with · toggle a step to fail` (`aria-labelledby="wTitle"`)
- Title id `wTitle`: `with · toggle a step to fail`.
- Control group `wfSel` (`.solid-select`, `aria-label="Steps; active means the step succeeds"`): `verify · ok` (`data-i="0"`, `data-c="sage"`, active default); `load_user · ok` (`data-i="1"`, `data-c="sage"`, active default); `start_session · ok` (`data-i="2"`, `data-c="sage"`, active default). Toggling a button flips its label to `· fail`, swaps `data-c` to `burg`, and re-renders.
- SVG ids: `wf0`/`wf0t`, `wf1`/`wf1t`, `wf2`/`wf2t` (the three step boxes + labels), `wfRes`/`wfResT` (the result box + text, default `{:ok, session}`). Code `pre` id `wfCode`, readout `wfOut` (`.geo-readout`, `aria-live="polite"`).
- Pure function: `render()` reads each step's active state via `okState(i)`, finds the first failing index, colours each box pass/fail/skip (green/red/dim), sets the result to `{:ok, session}` or `{:error, <err>}`, and rewrites the `with` code + the prose. The `STEPS` table holds each step's `name`, `okv`, and `err` (`verify → :expired`, `load_user → :unknown_user`, `start_session → :session_failed`).
- Result box `wfResT` (verbatim): all ok → `{:ok, session}`; first failure at step i → `{:error, <STEPS[i].err>}`.
- `wfOut` readout (verbatim):
  - all ok: `Every step matched {:ok, _}, so the body runs and returns {:ok, session} — the learner is signed in.`
  - on failure: `The <step> step returned {:error, <err>}, which did not match {:ok, _}. with stops there and the value falls through to else.`
- Takeaway (verbatim): One happy path, read top to bottom, and a single `else` for every failure. No nested conditionals, and no way to forget a branch — an unmatched error falls through to `else`.

### Degrade behaviour
The figure renders the all-ok default on load via `render()`; the SVG ships meaningful default step/result boxes in markup. The `.arc-flow` and `.hp-row` animations are gated to `prefers-reduced-motion: no-preference`; reveal-on-scroll is JS-gated and disabled under reduced motion. The `wfCode` block is JS-populated, so without JS only the static `#forms` `pre.code` (function heads / case / guard) is shown.

### Footer build-stamp decoder
Stamp id `TSK0NbBlxqSg4W`. `decodeBranded` base-62-decodes after the 3-char namespace and splits the Snowflake against `EPOCH_MS = 1704067200000`; the page hard-codes the decoded `st-ts` panel value `2026-05-31 13:51:47 UTC`.

## References (#refs, verbatim)

Intro line: Primary sources for this lesson, and where it connects in the course.

Sources:
- `https://hexdocs.pm/elixir/pattern-matching.html` — Pattern matching — Elixir documentation — `=` as the match operator.
- `https://hexdocs.pm/elixir/case-cond-and-if.html` — case, cond, and if — Elixir documentation — matching in control flow.

Related in this course:
- `/elixir/language/match` — F3.02 · Pattern matching & the match operator
- `/elixir/language/match/operator` — The match operator

## Wiring

- route-tag (verbatim): `/` `elixir` `/` `language` `/` `match` `/` `branching` (with `branching` as the current `.rcur` segment).
- crumbs (verbatim): `F3` (links `/elixir/language`) `/` `F3.02` (links `/elixir/language/match`) `/` `branching` (`.here`).
- toc-mini: `#flow` → `The sign-in flow`; `#forms` → `The four forms`.
- pager: prev → `/elixir/language/match/destructuring` label `Destructuring`; next → `/elixir/language` label `F3 overview`.
- footer: column `Chapters` — `/elixir/algebra` (F1 · Algebra), `/elixir/functional` (F2 · Functional Programming), `/elixir/language` (F3 · The Elixir Language), `/elixir/algorithms` (F4 · Algorithms & Data Structures), `/elixir/pragmatic` (F5 · Pragmatic Programming), `/elixir/phoenix` (F6 · Phoenix Framework). Column `The course` — `/elixir` (Course home), `/elixir/course` (Contents & history), `/elixir/algebra/functions` (Start · F1.01). Brand links `/elixir`.
- Page meta — `<title>`: `Branching with case, with & guards — F3.02 · jonnify`. `<meta description>`: `Dispatching on shape: function-head matching, case, guards, and the with pipeline — built around the portal's magic-link sign-in flow and its progress events.`

## Build instruction

To rebuild this dive, copy the `head…</style>`, `header`, `footer`, and the two trailing `<script>` blocks (the figure IIFE with the `STEPS` table + the Snowflake decoder, and the reveal-on-scroll enhancer) verbatim from a recent built sibling on this chapter accent, then change only `<title>`/`<meta>`, the `route-tag`, and the `<main>` body (hero, the two sections, the figure, the static `pre.code`, references, pager). The canonical model sibling is `elixir/language/match/destructuring.html` — the same dive shell on the same elixir accent (this page swaps the bind-table figure for a flow-diagram of toggleable steps and adds a static four-forms code block). No-invent guards: use only the real Portal surfaces as written — `Portal.Auth.verify/1`, the `verify`/`load_user`/`start_session` step names and their `:expired`/`:unknown_user`/`:session_failed` errors, `Progress.mark/2`, and the `{:lesson_completed, …}` / `{:lesson_started, …}` event shapes; do not invent new step names, error atoms, or event tags, and cite the companion course for OTP internals rather than re-teaching them. Voice rules: no first person, no exclamation marks, no emoji, and none of just/simply/obviously.
