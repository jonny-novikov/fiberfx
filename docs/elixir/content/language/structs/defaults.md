# F3.05.2 — Enforcing keys & defaults (dive)

- Route (served): `/elixir/language/structs/defaults`
- File: `elixir/language/structs/defaults.html`
- Place in the chapter: the second of the three F3.05 deep dives. With the struct defined (F3.05.1), this dive tightens it — `@enforce_keys` for required fields and keyword defaults — before F3.05.3 matches on the tag.
- Accent: elixir (purple), `--elixir:#b39ddb` / `--elixir-bright:#cdb8f0`.
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F3.05 · part 2 of 3`

Hero `h1` (verbatim): Enforcing keys & defaults

Hero lede (verbatim):

> A bare `defstruct` makes every field optional and nil by default. Two additions tighten that: `@enforce_keys` marks fields that must be given, raising at build time when one is missing, and a keyword form of `defstruct` sets default values for the rest.

Kicker line (verbatim):

> A portal learner has no meaning without an email, so `:email` is enforced. A new learner is a `:student` and `active` until told otherwise, so those carry defaults. Choose what the caller supplies and watch the struct build — or refuse to.

## Sections

Two teaching sections in order:

1. `#build` — "Building with what is given". The struct enforces `:email` and defaults `role: :student` and `active: true`; an interactive figure colours each field by where its value comes from (supplied, default, or missing).
2. `#declare` — "Declaring required keys and defaults". `@enforce_keys` is a module attribute; the keyword form of `defstruct` pairs the rest with defaults; a field can be enforced or defaulted, not both.

Running example: `Portal.Accounts.User` with enforced `:email` and defaults `role: :student`, `active: true`; the seed learner email is `"ada@portal.dev"`.

Real Elixir code shown (`#declare` `pre.code`, verbatim):

```
defmodule Portal.Accounts.User do
  @enforce_keys [:email]
  defstruct [:email, role: :student, active: true]
end

%User{email: "ada@portal.dev"}
# => %User{email: "ada@portal.dev", role: :student, active: true}

%User{role: :admin}
# ** (ArgumentError) the following keys must also be given
#    when building struct Portal.Accounts.User: [:email]
```

Bridge cells (idea → Elixir): "The idea" — "Some fields are essential and some have a sensible starting value — the contract of a record." → "In Elixir" — "`@enforce_keys` raises when an essential field is absent; `defstruct` defaults fill the rest."

Takeaway (`.take`, verbatim): "Defaults remove boilerplate for the common case; `@enforce_keys` turns a missing essential field into an error at the moment of construction, not a nil discovered later."

Closing `.note` (verbatim): Next: `/elixir/language/structs/matching` "matching on a struct's type" — using the `__struct__` tag to dispatch by shape.

## The interactives

### Section figure — "What the caller supplies · select one"

- `<figure>` `aria-labelledby="ekTitle"`; heading (id `ekTitle`): "What the caller supplies · select one".
- Control group `id="ekSel"` (`role="group"`, `aria-label="Keys supplied by the caller"`), three buttons (data-k / data-c / label):
  - `data-k="email"` `data-c="elixir"` (active) — "email only"
  - `data-k="emailrole"` `data-c="blue"` — "email + role"
  - `data-k="noemail"` `data-c="sage"` — "role only (no email)"
- SVG element ids: three field rows `ekR0`/`ekR1`/`ekR2` (rect strokes recoloured by source) with source labels `ekS0`/`ekS1`/`ekS2`; result line `ekResT`. Output region ids: `ekCode` (a `pre.code`, `aria-live="polite"`) and `ekOut` (a `.geo-readout`, `aria-live="polite"`).
- Source colours (JS constants): `PROVIDED = '#b39ddb'`, `DEFAULTED = '#7ba387'`, `MISSING = '#e08f8b'`.
- Driving function: `pick(k)` — sets the active button; for each of the three rows sets the rect stroke and the source label text/fill from `CASES[k].rows`; sets the result line `ekResT` text/fill from `status`/`statusFill`; writes `CASES[k].code` into `ekCode` and `CASES[k].out` into `ekOut`. On load `pick('email')`.
- Per-case field sources (`email`/`role`/`active` → label):
  - email only: supplied / default / default — status `struct built` (`#a7c9b1`)
  - email + role: supplied / supplied / default — status `struct built` (`#a7c9b1`)
  - role only (no email): missing / default / default — status `ArgumentError — :email is enforced` (`#e08f8b`)
- Per-case code (`ekCode`) decoded VERBATIM:
  - email: `%User{email: "ada@portal.dev"}` / `# => %User{email: "ada@portal.dev", role: :student, active: true}`
  - emailrole: `%User{email: "ada@portal.dev", role: :admin}` / `# => %User{email: "ada@portal.dev", role: :admin, active: true}`
  - noemail: `%User{role: :admin}` / `# ** (ArgumentError) the following keys must also be given` / `#    when building struct Portal.Accounts.User: [:email]`
- Readout strings (`ekOut`) VERBATIM:
  - email: `Only <code class="inl">:email</code> is supplied. The enforced key is present, so the struct builds and the two defaults fill <code class="inl">role: :student</code> and <code class="inl">active: true</code>.`
  - emailrole: `Supplying <code class="inl">role: :admin</code> overrides its default; <code class="inl">active</code> still defaults to <code class="inl">true</code>. A supplied value always wins over a default.`
  - noemail: `With <code class="inl">:email</code> absent, <code class="inl">@enforce_keys</code> refuses to build the struct and raises an <code class="inl">ArgumentError</code> — the error arrives at construction, not later.`
- Degrade: the SVG ships the static three-row field set in markup with the default `email only` colouring (email supplied `#b39ddb`, role/active default `#7ba387`, result `struct built`), so it reads without JS; `ekCode`/`ekOut` start empty and are filled by `pick('email')` on load. The page-wide `prefers-reduced-motion: reduce` suppresses the `.reveal` transitions on the References section.

### Footer build-stamp

- `id="stampId"` text: `TSK0NbNoW9SqES`. `decodeBranded` yields: namespace `TSK`, snowflake `319515441074536448`, node `0`, seq `0`, timestamp **`2026-05-31 16:40:17 UTC`** (matching the static `st-ts` placeholder). Click / Enter / Space toggles the `.panel` open.

## References (#refs, verbatim)

Intro line: "Primary sources for this lesson, and where it connects in the course."

Sources:
- `https://hexdocs.pm/elixir/structs.html` — Structs — Elixir documentation — named, typed maps, `@enforce_keys`, and defaults.
- `https://hexdocs.pm/elixir/keywords-and-maps.html` — Keywords and maps — Elixir documentation — choosing a data shape.
- `https://hexdocs.pm/elixir/Map.html` — `Map` — Elixir documentation — the map module a struct rests on.

Related in this course:
- `/elixir/language/structs` — F3.05 · Structs, maps & keyword lists
- `/elixir/language/structs/define` — F3.05.1 · Defining a struct
- `/elixir/language/structs/matching` — F3.05.3 · Matching on a struct's type

## Wiring

- route-tag (verbatim): `/ elixir / language / structs / defaults` — `defaults` is the current segment (`.rcur`); `elixir`, `language`, `structs` are links.
- crumbs (verbatim): `F3` (links `/elixir/language`) / `F3.05` (links `/elixir/language/structs`) / `defaults` (here).
- toc-mini: `#build` "Building with what is given"; `#declare` "Declaring required keys and defaults".
- pager: prev → `/elixir/language/structs/define` "F3.05.1 · define"; next → `/elixir/language/structs/matching` "Next · matching".
- footer: identical three-column footer as the hub — Chapters (`/elixir/algebra`…`/elixir/phoenix`), The course (`/elixir`, `/elixir/course`, `/elixir/algebra/functions`), same foot tag.
- Page meta: `<title>` = `Enforcing keys & defaults — F3.05.2 · jonnify`; `<meta name="description">` = `@enforce_keys for required fields and keyword defaults in defstruct: what fills in for the common case, and the ArgumentError raised at construction when an essential field is missing.`

## Build instruction

To rebuild this dive, copy the `<head>…</style>`, the `header.site`, the `footer.site-foot`, and the two trailing `<script>` blocks (the figure/stamp IIFE and the reveal-on-scroll enhancer) verbatim from a recent built sibling on the F3 elixir-purple accent. Change only the `<title>`/`<meta description>`, the `route-tag` segments, the crumbs, and the `<main>` body (hero, `#build` figure, `#declare` code + bridge, references, pager). No-invent guards: use only the real Portal surfaces as written — the branded store, the event-sourced engine behind the ONE `Portal` facade, the Phoenix web app; `Portal.Accounts.User` is the running learner record, `:email` enforced with `role: :student` / `active: true` defaults. Do not invent fields or alter the `ArgumentError` text; cite the companion F6 (`/elixir/phoenix`) for web/OTP internals rather than re-teaching them. Voice: no first person, no exclamation marks, no emoji, and none of just/simply/obviously. Model sibling to copy from: `elixir/language/structs/define.html` (same module, same accent, same shared head and scripts).
