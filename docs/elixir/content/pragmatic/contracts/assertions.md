# F5.04.2 — Assertions in Elixir (dive)

- **Route (served):** `/elixir/pragmatic/contracts/assertions`
- **File:** `/Users/jonny/dev/jonnify/elixir/pragmatic/contracts/assertions.html`
- **Place in the chapter:** part 2 of 3 of module F5.04 · Design by contract (chapter F5 · Pragmatic Programming). It follows F5.04.1 (the three terms and their owners) and precedes F5.04.3 (failing fast). Where part 1 names the contract, this dive shows the Elixir idioms that express each term.
- **Accent:** burgundy (chapter) — this dive's selected idiom rides blue (`--blue:#5a87c4`; the `with` chip and `#asRole` use `#9fc0ea`), the chapter accent staying burgundy.
- **Status:** built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F5.04 · part 2 of 3`

Hero `h1` (verbatim): `Assertions in Elixir`

Hero lede (`<p class="lede">`, verbatim): "Elixir has no `require` or `ensure` keyword, so a contract is written in the language's ordinary idioms — and each idiom fits a different term. **Guards and pattern matching** in a function head express preconditions on the shape of arguments. A **`with` chain** composes several checks and short-circuits on the first failure. **Tagged tuples** carry expected failures back to the caller. And **`raise`** — or a match that fails — crashes on a broken invariant, which is a bug rather than a bad request. Choosing the right one is choosing how a violation should be handled."

Kicker (`<p class="kicker">`, verbatim): "Four idioms, four kinds of check. Select one to see which part of a contract it expresses."

## Sections

In order (teaching arc: *survey the idioms → see them in one command*):

1. **`#idioms` — "Four idioms"** (teaching). Prose: the split between expected failures (return `{:error, reason}`) and impossible states (crash). Carries the interactive `#asSel` idiom-selector figure and the `take` "There is no contract keyword because there does not need to be. Guards, `with`, tuples, and `raise` already say everything — you only have to pick the one that fits the failure."
2. **`#code` — "In code"**. The whole contract in one `enroll/2` function: binary-pattern shape preconditions in the head, a `with` chain composing the runtime checks with tagged-tuple expected failures, a fallback head returning `{:error, :bad_reference}`, and an invariant assertion inside `build/2`. Closes with a `.bridge` ("match the idiom to the failure" → "one honest command") and a `.note` forward to failing fast.

Running example: the `enroll(user_id, course_id)` command, with `ensure_not_enrolled/2`, `build/2`, and `Portal.Store.put/1`.

Real Elixir code shown (`#code` block):
- `def enroll(<<"USR", _::binary>> = user_id, <<"CRS", _::binary>> = course_id)` — the binary patterns are the shape precondition; a `with` chain runs `ensure_not_enrolled/2` (expected failure → `{:error, _}`), binds `enrollment = build(...)`, and `Portal.Store.put(enrollment)`, returning `{:ok, enrollment}`.
- `def enroll(_, _), do: {:error, :bad_reference}` — the unmet-precondition fallback, the caller's fault.
- `defp build(u, c)` — builds `%Enrollment{id: Portal.ID.new("ENR"), ...}` then asserts `true = e.progress in 0..100` (raises `MatchError` if ever false — the invariant assertion).

## The interactives

This dive carries one interactive figure (the idiom selector) plus the footer stamp.

### Content figure — "The contract toolkit · select an idiom" (`#asSel` + `#asOut`)

- **`<figure class="fig" aria-labelledby="asTitle">`** titled "The contract toolkit · select an idiom" (`#asTitle`).
- **Control group `#asSel`** (role="group"), four `<button>`s by `data-k` (no `data-c`):
  - `data-k="guards"` — label "guards"
  - `data-k="with"` — label "with" — starts `active`
  - `data-k="tuple"` — label "tagged tuple"
  - `data-k="raise"` — label "raise"
- **SVG chip ids:** `#asChip_guards` ("shape precondition"), `#asChip_with` (blue stroke `#5a87c4`, "compose checks"), `#asChip_tuple` ("expected failure"), `#asChip_raise` ("broken invariant"). A footer caption reads "expected failures return a tuple · impossible states crash".
- **Pure function:** `pick(k)` over `IDIOMS {guards, with, tuple, raise}` — toggles `#asSel` button `active`/`aria-pressed`, sets the matching `#asChip_*` rect's `stroke`/`stroke-width`/`fill` (on = `#5a87c4`/`2`/`#11203a`, off = `#3a4263`/`1.3`/`#10162b`), writes `I.name` into `#asRole`, `I.expresses` into `#asResult`, and the composed sentence into `#asOut.innerHTML`. Initial call `pick('with')`.
- **Readout strings (`IDIOMS`, verbatim — `#asOut` is composed as ``<b>{name}</b> — expresses {expresses}. {desc}``):**
  - guards: name "guards", expresses "shape preconditions", desc "A guard in the function head — `when is_binary(id)`, or a binary pattern — refuses the call before the body runs. A cheap, declarative precondition on the shape of arguments."
  - with: name "with", expresses "composed preconditions", desc "A `with` chain runs each check in order and short-circuits to the first `{:error, _}`. The happy path reads top to bottom; any failure falls straight through."
  - tuple: name "tagged tuple", expresses "expected failures", desc "Return `{:ok, value}` or `{:error, reason}` for failures the caller should handle — not-found, already-enrolled. The contract's channel for expected errors."
  - raise: name "raise", expresses "broken invariants", desc "A broken invariant is a bug, not a bad request — `raise` or a failed match crashes loudly. Let it crash; never paper over an impossible state."
- **Static readout fallbacks (in markup):** `#asRole` = "with"; `#asResult` = "composed preconditions"; `#asOut` empty until JS runs.

### Footer build-stamp decoder (`#stamp`)

- **Stamp id:** `TSK0Ncv1841gky` (in `#stampId`); `#st-ts` hard-codes "2026-06-01 14:52:31 UTC".
- **Decoder:** `decodeBranded(id)` with `EPOCH_MS = 1704067200000`, `ts = snow >> 22n`, `node = (snow >> 12n) & 0x3FFn`, `seq = snow & 0xFFFn`. Decoding `TSK0Ncv1841gky` yields **2026-06-01 14:52:31 UTC** (node 0, seq 0), matching the markup. Toggle on click / Enter / Space sets `.open` + `aria-expanded`.

Degrade behaviour: the `#asSel` controls + the four SVG chips (the blue `with` chip pre-highlighted) are in static markup; JS only enhances. The `.reveal` references section shows without JS and restores immediately under `prefers-reduced-motion: reduce`. No browser storage.

## References (#refs, verbatim)

Intro line: "Primary sources for this lesson, and where it connects in the course."

**Sources**
- [Bertrand Meyer — Applying Design by Contract](https://se.inf.ethz.ch/~meyer/publications/computer/contract.pdf) — preconditions, postconditions, invariants.
- [Eiffel — Design by Contract and assertions](https://www.eiffel.org/doc/solutions/Design_by_Contract_and_Assertions) — the contract metaphor, in depth.
- [Elixir — Patterns and guards](https://hexdocs.pm/elixir/patterns-and-guards.html) — guards as executable preconditions.

**Related in this course**
- F5.04 · Design by contract → `/elixir/pragmatic/contracts`
- Pre- and post-conditions → `/elixir/pragmatic/contracts/conditions`
- Failing fast at the boundary → `/elixir/pragmatic/contracts/fail-fast`

## Wiring

- **route-tag:** `<span class="rsep">/</span><a href="/elixir">elixir</a><span class="rsep">/</span><a href="/elixir/pragmatic">pragmatic</a><span class="rsep">/</span><a href="/elixir/pragmatic/contracts">contracts</a><span class="rsep">/</span><span class="rcur">assertions</span>` (current segment `assertions` is `.rcur`).
- **crumbs:** `F5` → `/elixir/pragmatic` · sep `/` · `F5.04` → `/elixir/pragmatic/contracts` · sep `/` · here `assertions` (no link).
- **toc-mini:** `#idioms` ("Four idioms") · `#code` ("In code").
- **pager:** prev → `/elixir/pragmatic/contracts/conditions` ("← F5.04.1 · conditions"); next → `/elixir/pragmatic/contracts/fail-fast` ("Next · failing fast →").
- **footer (3-column `foot-nav`):** Chapters column — `/elixir/algebra`, `/elixir/functional`, `/elixir/language`, `/elixir/algorithms`, `/elixir/pragmatic`, `/elixir/phoenix`. The course column — `/elixir` ("Course home"), `/elixir/course` ("Contents & history"), `/elixir/algebra/functions` ("Start · F1.01"). Header brand + footer logo both → `/elixir`.
- **Page meta:** `<title>` "Assertions in Elixir — F5.04.2 · jonnify"; `<meta description>` "Elixir has no design-by-contract keywords, so contracts are written in its idioms: guards and pattern matching express preconditions on shape, a with chain composes them and short-circuits on the first failure, tagged tuples carry expected errors back to the caller, and raise crashes loudly on a broken invariant — a bug, not a bad request."

## Build instruction

To rebuild this page, copy the `<head>…</style>`, the `<header class="site">`, the `<footer class="site-foot">`, and the two trailing `<script>` blocks verbatim from a recent BUILT sibling on the burgundy F5 accent; change only `<title>`/`<meta description>`, the `.route-tag` current segment, and the `<main>` body (hero, the `#idioms` idiom-selector figure, the `#code` block, and the `#refs` block). Keep the no-invent guards: use only the real Portal surfaces as written — `enroll/2` with binary-pattern heads, `ensure_not_enrolled/2`, `build/2`, `%Enrollment{}`, `Portal.ID.new("ENR")`, `Portal.Store.put/1`, the `{:error, :bad_reference}` tag, the `0..100` progress invariant — and do not re-teach OTP internals (cite the companion course). Voice rules: no first person, no exclamation marks, no emoji, none of just/simply/obviously. Model sibling to copy from: `conditions.html` (part 1 of 3 of this module, same burgundy accent and footer/stamp pattern).
