# F3.05.3 — Matching on a struct's type (dive)

- Route (served): `/elixir/language/structs/matching`
- File: `elixir/language/structs/matching.html`
- Place in the chapter: the third and last of the F3.05 deep dives. With the struct defined (F3.05.1) and tightened (F3.05.2), this dive uses the `__struct__` tag to dispatch across function clauses — the bridge into F3.06 (`protocols`), where that tag drives polymorphism.
- Accent: elixir (purple), `--elixir:#b39ddb` / `--elixir-bright:#cdb8f0`.
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F3.05 · part 3 of 3`

Hero `h1` (verbatim): Matching on a struct's type

Hero lede (verbatim):

> Because a struct carries its module in the `__struct__` key, a pattern can match on the type itself. `%User{} = value` succeeds only when the value is a `User`, and a function can have one clause per struct — the runtime picks the clause whose tag fits.

Kicker line (verbatim):

> The portal passes many shapes around: a `%User{}`, a `%Session{}`, sometimes a plain map from outside. A single `describe/1` dispatches on which one arrives. Send a value through and watch the clause light up.

## Sections

Two teaching sections in order:

1. `#dispatch` — "Dispatch by the tag". Three `describe/1` clauses in order — one for `%User{}`, one for `%Session{}`, and a final guarded clause for any plain map; an interactive figure shows which clause matches an incoming value and why.
2. `#guard` — "Clause order and the guard". Order matters because a struct is a map: the `%{}` clause would match a `%User{}` too; struct clauses go first, the map clause is guarded with `not is_struct(m)`.

Running example: `Portal.Accounts.User` (`%User{email: "ada@portal.dev"}`), `Portal.Auth.Session` (`%Session{id: "SES0NbAb29FnXc"}`), and a plain map.

Real Elixir code shown (`#guard` `pre.code`, verbatim):

```
def describe(%User{email: e}), do: "user #{e}"
def describe(%Session{id: id}), do: "session #{id}"
def describe(%{} = m) when not is_struct(m), do: "plain map of #{map_size(m)} keys"

# is_struct/2 asks the tag directly
is_struct(user)         # => true
is_struct(user, User)   # => true
is_struct(%{a: 1})       # => false
```

Bridge cells (idea → Elixir): "The idea" — "Choose the right behaviour by looking at a value's type — dispatch by what the thing is." → "In Elixir" — "`%Struct{}` patterns and `is_struct/2` dispatch on the tag — and that tag is what protocols use for polymorphism."

Takeaway (`.take`, verbatim): "The tag turns a value's type into something a pattern can read. One function dispatches across shapes with no conditionals — the clause whose struct matches is the one that runs."

Closing `.note` (verbatim): "That is the whole of structs: a named, checked shape over a map, with a tag you can match on. Next module: **F3.06 — Protocols & behaviours**, where that tag drives polymorphism across types."

## The interactives

### Section figure — "The incoming value · select one"

- `<figure>` `aria-labelledby="mtTitle"`; heading (id `mtTitle`): "The incoming value · select one".
- Control group `id="mtSel"` (`role="group"`, `aria-label="Incoming value"`), three buttons (data-k / data-c / label):
  - `data-k="user"` `data-c="elixir"` (active) — "%User{}"
  - `data-k="session"` `data-c="blue"` — "%Session{}"
  - `data-k="map"` `data-c="sage"` — "plain map"
- SVG element ids: incoming-value box `mtIn` (stroke per value) and text `mtInT`; `__struct__` tag readout `mtTag`; three clause rects `mtCl0`/`mtCl1`/`mtCl2` with "match" markers `mtM0`/`mtM1`/`mtM2` (opacity toggled). Output region ids: `mtCode` (a `pre.code`, `aria-live="polite"`) and `mtOut` (a `.geo-readout`, `aria-live="polite"`).
- The three clause labels in the SVG (verbatim): `describe(%User{} = u)`, `describe(%Session{} = s)`, `describe(%{} = m) when not is_struct(m)`. Section header above them: `CLAUSES · FIRST MATCH WINS`.
- JS constants: `LINE = '#2a3252'` (unmatched stroke), `LIT = '#7ba387'` (matched stroke).
- Driving function: `pick(k)` — sets the active button; sets `mtIn` stroke and `mtInT` text; sets `mtTag` text/fill; for each clause row sets the matched stroke (`LIT`/`LINE`) and the marker opacity (the matching clause `match` mark to `1`, others `0`); writes `CASES[k].code` into `mtCode` and `CASES[k].out` into `mtOut`. On load `pick('user')`.
- Per-case incoming value / tag / matching clause index:
  - user: `%Portal.Accounts.User{email: "ada@portal.dev"}` / tag `Portal.Accounts.User` / clause 0
  - session: `%Portal.Auth.Session{id: "SES0NbAb29FnXc"}` / tag `Portal.Auth.Session` / clause 1
  - map: `%{email: "ada@portal.dev", role: :student}` / tag `(none — a plain map)` / clause 2
- Per-case code (`mtCode`) decoded VERBATIM:
  - user: `def describe(%User{email: e}), do: "user #{e}"` / `# => "user ada@portal.dev"`
  - session: `def describe(%Session{id: id}), do: "session #{id}"` / `# => "session SES0NbAb29FnXc"`
  - map: `def describe(%{} = m) when not is_struct(m), do: "plain map of #{map_size(m)} keys"` / `# => "plain map of 2 keys"`
- Readout strings (`mtOut`) VERBATIM:
  - user: `The value carries <code class="inl">__struct__: Portal.Accounts.User</code>, so the <code class="inl">%User{}</code> clause matches first and binds <code class="inl">email</code>.`
  - session: `Its tag is <code class="inl">Portal.Auth.Session</code>, so the <code class="inl">%User{}</code> clause is skipped and the <code class="inl">%Session{}</code> clause matches.`
  - map: `A plain map has no <code class="inl">__struct__</code> tag, so both struct clauses are skipped; the guarded <code class="inl">%{}</code> clause catches it.`
- Degrade: the SVG ships the static `%User{}` state in markup (incoming text `%Portal.Accounts.User{email: "ada@portal.dev"}`, tag `Portal.Accounts.User`, clause 0 lit with its `match` marker at `opacity="1"`, the others at `opacity="0"`), so it reads without JS; `mtCode`/`mtOut` start empty and are filled by `pick('user')` on load. The page-wide `prefers-reduced-motion: reduce` suppresses the `.reveal` transitions on the References section.

### Footer build-stamp

- `id="stampId"` text: `TSK0NbNoWkeIGu`. `decodeBranded` yields: namespace `TSK`, snowflake `319515441623990272`, node `0`, seq `0`, timestamp **`2026-05-31 16:40:17 UTC`** (matching the static `st-ts` placeholder). Click / Enter / Space toggles the `.panel` open.

## References (#refs, verbatim)

Intro line: "Primary sources for this lesson, and where it connects in the course."

Sources:
- `https://hexdocs.pm/elixir/structs.html` — Structs — Elixir documentation — named, typed maps and the `__struct__` tag.
- `https://hexdocs.pm/elixir/keywords-and-maps.html` — Keywords and maps — Elixir documentation — choosing a data shape.
- `https://hexdocs.pm/elixir/Map.html` — `Map` — Elixir documentation — the map module a struct is built on.

Related in this course:
- `/elixir/language/structs` — F3.05 · Structs, maps & keyword lists
- `/elixir/language/structs/define` — Defining a struct
- `/elixir/language/protocols` — F3.06 · Protocols & behaviours

## Wiring

- route-tag (verbatim): `/ elixir / language / structs / matching` — `matching` is the current segment (`.rcur`); `elixir`, `language`, `structs` are links.
- crumbs (verbatim): `F3` (links `/elixir/language`) / `F3.05` (links `/elixir/language/structs`) / `matching` (here).
- toc-mini: `#dispatch` "Dispatch by the tag"; `#guard` "Clause order and the guard".
- pager: prev → `/elixir/language/structs/defaults` "F3.05.2 · defaults"; next → `/elixir/language` "Back to F3 · The Elixir Language".
- footer: identical three-column footer as the hub — Chapters (`/elixir/algebra`…`/elixir/phoenix`), The course (`/elixir`, `/elixir/course`, `/elixir/algebra/functions`), same foot tag.
- Page meta: `<title>` = `Matching on a struct's type — F3.05.3 · jonnify`; `<meta name="description">` = `The %Struct{} pattern dispatches on the __struct__ tag across function clauses; why clause order matters when a struct is a map, and the is_struct/2 guard that keeps plain maps in their own clause.`

## Build instruction

To rebuild this dive, copy the `<head>…</style>`, the `header.site`, the `footer.site-foot`, and the two trailing `<script>` blocks (the figure/stamp IIFE and the reveal-on-scroll enhancer) verbatim from a recent built sibling on the F3 elixir-purple accent. Change only the `<title>`/`<meta description>`, the `route-tag` segments, the crumbs, and the `<main>` body (hero, `#dispatch` figure, `#guard` code + bridge, references, pager). No-invent guards: use only the real Portal surfaces as written — the branded store (`SES0NbAb29FnXc` is a branded session id), the event-sourced engine behind the ONE `Portal` facade, the Phoenix web app; `Portal.Accounts.User` and `Portal.Auth.Session` are the running shapes. Do not invent clauses, struct modules, or alter the `is_struct/2` semantics; cite the companion F6 (`/elixir/phoenix`) for web/OTP internals rather than re-teaching them, and leave protocol polymorphism for F3.06 (`/elixir/language/protocols`). Voice: no first person, no exclamation marks, no emoji, and none of just/simply/obviously. Model sibling to copy from: `elixir/language/structs/defaults.html` (same module, same accent, same shared head and scripts).
