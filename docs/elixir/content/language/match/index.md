# F3.02 — Pattern matching (module hub)

- Route (served): `/elixir/language/match`
- File: `elixir/language/match/index.html`
- Place in the chapter: the second module of F3 · The Elixir Language. It introduces pattern matching as the way Elixir reads the shape of data and pulls it apart, and it is where the course stops being abstract — the running learning Portal (magic-link sign-in, lesson progress) becomes the practical thread. The hub frames three deep dives: `operator`, `destructuring`, and `branching`.
- Accent: elixir (purple), `--elixir` / `--elixir-bright`.
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow: `F3 · Foundations · module 2`

H1: Pattern `matching` (the word "matching" rendered in the elixir-italic `.ex` span).

Hero lede (verbatim):

> In most languages `=` means assignment. In Elixir it is the **match operator**: it asserts that the value on the right has the shape on the left, and binds any names in that shape. When the shapes disagree, the match fails — and that failure is a feature, not a bug.

Kicker line (verbatim):

> This is also where the course stops being abstract. From here on, the practical thread is a single project: **build this learning portal in Elixir** — magic-link sign-in, lesson progress, and later a Phoenix LiveView interface with Telemetry analytics. Every example in this module is a slice of that portal, starting with the data its sign-in returns.

## What the page frames

The hub renders the three deep dives as full-width cards (not the `.mods` grid). Each is built.

- F3.02.1 — The match operator — "= asserts and binds; the pin `^` matches a value you already hold. Seen through verifying a sign-in." — route `/elixir/language/match/operator` — built.
- F3.02.2 — Destructuring portal data — "Pull fields out of tuples, lists, maps, and structs — claims, request params, and progress records — in one match." — route `/elixir/language/match/destructuring` — built.
- F3.02.3 — Branching with case, with & guards — "Dispatch on shape: function heads, case, guards, and the `with` pipeline that runs the whole sign-in." — route `/elixir/language/match/branching` — built.

The page also carries a project orientation section, `The project: a learning portal`, with a `.deflist` of the Portal context modules (real surfaces, cited verbatim):

- `Portal.Accounts` — learners — `%User{id: "USR0NbAb1xcFCy", email: "ada@portal.dev"}`.
- `Portal.Auth` — magic-link sign-in: `request_link/1` and `verify/1`, which returns `{:ok, claims}` or `{:error, :expired | :invalid}`; sessions like `%Session{id: "SES0NbAb29FnXc"}`.
- `Portal.Catalog` — courses and lessons — `%Lesson{id: "LSN0NbAb2Lk9GS"}`.
- `Portal.Progress` — completions and the events that drive them — `{:lesson_completed, user_id, lesson_id}`.

An F1→F3 `.bridge` pairs "An equation asserts that both sides denote the same value." (F1 · Algebra) with "`=` asserts the value matches the pattern, and binds the names in it." (F3 · the match operator).

## The interactives

### Hero figure — `Assignment vs. match` (`aria-labelledby="asTitle"`)
- Figcaption label id `asTitle`: `Assignment vs. match`.
- SVG element ids: `asEq` (the `=` glyph), `asMode` (mode caption, initial `READ AS ASSIGNMENT`), `asArrows` (the arrow group), `asRev` / `asRevNote` (the reversed `1 = x` box + note), `asLaw` (the law line).
- Controls (`.hp-ctrls`): button `asBtn` label `▸ read it as a match` (toggles), button `asReset` (`.ghost`) label `reset`.
- Behaviour: an IIFE toggles `asMatch`. In assignment mode the arrow is one-way (`name ← value`), `asLaw` reads `one direction: name ← value`, `asRevNote` reads `rejected — cannot assign to 1`. In match mode the arrows become two-way, `asLaw` reads `an assertion: both sides denote 1`, `asRevNote` reads `holds — x already equals 1`, and the button flips to `▸ read it as assignment`.
- Readout `asCap` (`aria-live="polite"`), assignment state (verbatim): `x = 1 · assignment` / `A one-way store: the value lands in the name, and 1 = x is a syntax error.` Match state (verbatim): `x = 1 · match` / `An assertion that binds x to 1; the reversed 1 = x then holds, because x already equals 1.`

### `The match operator · select a case` (`aria-labelledby="mTitle"`)
- Title id `mTitle`: `The match operator · select a case`.
- Control group `meSel` (`.solid-select`, `role="group"`, `aria-label="Match cases"`): `verified` (`data-k="ok"`, `data-c="sage"`, active default); `expired` (`data-k="expired"`, `data-c="burg"`); `match the error` (`data-k="err"`, `data-c="blue"`).
- SVG ids: `mePat` (pattern box), `mePatT` (pattern text), `meResult` (verdict line), `meVal` (value box), `meValT` (value text). Code `pre` id `meCode`, readout `meOut` (`.geo-readout`, `aria-live="polite"`).
- Pure function: `pick(key)` reads the `CASES` table, recolours the boxes green/red, sets the verdict text to `matches — binds` or `no match — MatchError`, and writes the code + prose. `setT(id, t)` is the text-setter helper. Default `pick('ok')`.
- Readouts per case (verbatim from `CASES`):
  - `ok` — `meResult`: `matches — binds`; out: `The token verified. The :ok tag matched, and claims bound to the map of claims — ready to use.`
  - `expired` — `meResult`: `no match — MatchError`; out: `The tags differ — :ok against :error — so the match fails and Elixir raises a MatchError.`
  - `err` — `meResult`: `matches — binds`; out: `A pattern shaped for failure matches: reason binds to :expired, ready for an error branch.`
- Takeaway (verbatim): A match is an assertion. If you expect `{:ok, _}` and get `{:error, _}`, the program stops there rather than carrying a wrong assumption forward — the heart of "let it crash."

### Degrade behaviour
The hero SVG ships a static assignment state in markup (one-way arrow, `READ AS ASSIGNMENT`) so it is meaningful without JS. The `.hp-row.hp-new` slide-in animation is suppressed under `prefers-reduced-motion: reduce`; the `.arc-flow` dashed-flow animation is likewise gated to `no-preference`. Reveal-on-scroll is JS-gated and disabled under reduced motion.

### Footer build-stamp decoder
Stamp id `TSK0NbBlxoTUA4`. The `decodeBranded` routine base-62-decodes after the 3-char namespace, then splits the Snowflake into timestamp/node/seq against `EPOCH_MS = 1704067200000`. The page hard-codes the decoded timestamp `2026-05-31 13:51:47 UTC` in the `st-ts` panel cell.

## References (#refs, verbatim)

Intro line: Primary sources for this lesson, and where it connects in the course.

Sources:
- `https://hexdocs.pm/elixir/pattern-matching.html` — Pattern matching — Elixir documentation — = as the match operator.
- `https://hexdocs.pm/elixir/case-cond-and-if.html` — case, cond, and if — Elixir documentation — matching in control flow.

Related in this course:
- `/elixir/language/match/operator` — F3.02.1 · The match operator
- `/elixir/language/match/destructuring` — F3.02.2 · Destructuring portal data
- `/elixir/language/match/branching` — F3.02.3 · Branching with case, with & guards

## Wiring

- route-tag (verbatim): `/` `elixir` `/` `language` `/` `match` (with `match` as the current `.rcur` segment).
- crumbs (verbatim): `F3 · The Elixir Language` (links `/elixir/language`) `/` `F3.02 · match` (`.here`).
- toc-mini: `#match` → `= is a match`; `#project` → `The project`; `#dives` → `Three deep dives`.
- pager: prev → `/elixir/language/values` label `F3.01 · values`; next → `/elixir/language/match/operator` label `Start · the match operator`.
- footer: column `Chapters` — `/elixir/algebra` (F1 · Algebra), `/elixir/functional` (F2 · Functional Programming), `/elixir/language` (F3 · The Elixir Language), `/elixir/algorithms` (F4 · Algorithms & Data Structures), `/elixir/pragmatic` (F5 · Pragmatic Programming), `/elixir/phoenix` (F6 · Phoenix Framework). Column `The course` — `/elixir` (Course home), `/elixir/course` (Contents & history), `/elixir/algebra/functions` (Start · F1.01). Brand links `/elixir`.
- Page meta — `<title>`: `Pattern matching & the match operator — F3.02 · jonnify`. `<meta description>`: `Pattern matching is how Elixir reads the shape of data and pulls it apart. This module introduces it through the project the whole course builds: a learning portal with magic-link sign-in and progress tracking. Three deep dives follow.`

## Build instruction

To rebuild this hub, copy the `head…</style>`, `header`, `footer`, and the two trailing `<script>` blocks (the page IIFE + the Snowflake decoder, and the reveal-on-scroll enhancer) verbatim from a recent built sibling on this chapter accent, then change only `<title>`/`<meta>`, the `route-tag`, and the `<main>` body. The closest model sibling is another F3 module hub on the elixir accent — copy from `elixir/language/values/index.html` (the F3.01 leaf landing) or another F3.0x `index.html`; for the dive-card pattern and the project `.deflist`, this `match/index.html` is itself the canonical example. No-invent guards: use only the real Portal surfaces exactly as written here — the branded store (`USR…`/`SES…`/`LSN…`/`MLT…` ids), the event-sourced engine behind the one `Portal.*` facade (`Portal.Accounts`, `Portal.Auth` with `request_link/1` and `verify/1`, `Portal.Catalog`, `Portal.Progress`), and the Phoenix web app; do not invent new module names, arities, or struct fields, and cite the companion course for OTP internals rather than re-teaching them. Voice rules: no first person, no exclamation marks, no emoji, and none of just/simply/obviously.
