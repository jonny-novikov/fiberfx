# F3.05.1 — Defining a struct (dive)

- Route (served): `/elixir/language/structs/define`
- File: `elixir/language/structs/define.html`
- Place in the chapter: the first of the three F3.05 deep dives, opening the struct arc (`define` → `defaults` → `matching`). It establishes what a struct is — a tagged map — before the next dives enforce keys and match on the tag.
- Accent: elixir (purple), `--elixir:#b39ddb` / `--elixir-bright:#cdb8f0`.
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F3.05 · part 1 of 3`

Hero `h1` (verbatim): Defining a struct

Hero lede (verbatim):

> A struct is declared inside a module with `defstruct`, which lists the fields the struct may hold. The module's name becomes the struct's name, so `Portal.Accounts.User` defines the `%User{}` shape. At runtime a struct is an ordinary map carrying one extra key, `__struct__`, set to the module.

Kicker line (verbatim):

> The portal needs a learner with a guaranteed shape: an id, an email, and a role. One `defstruct` line gives every `%User{}` exactly those fields and nothing else.

## Sections

Two teaching sections in order:

1. `#reveal` — "A struct is a tagged map". The `%User{}` literal is sugar over a map carrying a hidden `__struct__` key naming its module; an interactive figure shows the one value three ways.
2. `#define` — "Declaring the fields". The one-line `defstruct` declaration; building a value with an unknown key is a compile error.

Running example: `Portal.Accounts.User` with fields `id`, `email`, `role`; the seed learner is `id: "USR0NbAb1xcFCy"`, `email: "ada@portal.dev"`, `role: :student`.

Real Elixir code shown (`#define` `pre.code`, verbatim):

```
defmodule Portal.Accounts.User do
  defstruct [:id, :email, :role]
end

# build one — and look underneath
user = %Portal.Accounts.User{id: "USR0NbAb1xcFCy", email: "ada@portal.dev", role: :student}

user.__struct__   # => Portal.Accounts.User
Map.keys(user)   # => [:__struct__, :email, :id, :role]
is_map(user)      # => true
```

Bridge cells (idea → Elixir): "F2.07 · product types" — "A product type bundles a fixed set of fields into one value — all present together." → "F3 · defstruct" — "The same product, named by its module and backed by a map — the fields are fixed, the shape is checked."

Takeaway (`.take`, verbatim): "The literal and the map are the same value. The `__struct__` key is the only thing that separates a struct from a plain map — and it is what lets a later clause match on the type."

Closing `.note` (verbatim): Next: `/elixir/language/structs/defaults` "enforcing keys and defaults" — making some fields required and giving others a starting value.

## The interactives

### Section figure — "One value, three views · select one"

- `<figure>` `aria-labelledby="dfTitle"`; heading (id `dfTitle`): "One value, three views · select one".
- Control group `id="dfSel"` (`role="group"`, `aria-label="View of the value"`), three buttons (data-k / data-c / label):
  - `data-k="literal"` `data-c="elixir"` (active) — "%User{} literal"
  - `data-k="map"` `data-c="blue"` — "underlying map"
  - `data-k="keys"` `data-c="sage"` — "Map.keys/1"
- SVG element ids: `dfTag` (the `__struct__` row rect, opacity toggled between `0.35` dimmed and `1` revealed); static field rows for `id`, `email`, `role`. Output region ids: `dfCode` (a `pre.code`, `aria-live="polite"`) and `dfOut` (a `.geo-readout`, `aria-live="polite"`).
- Driving function: `pick(k)` — sets the active button, sets `dfTag` opacity from `VIEW[k].tagOpacity`, writes `VIEW[k].code` into `dfCode`, and `VIEW[k].out` into `dfOut`. On load `pick('literal')`.
- Per-view code (`dfCode`) decoded VERBATIM:
  - literal (`tagOpacity 0.35`): `%User{id: "USR0NbAb1xcFCy", email: "ada@portal.dev", role: :student}`
  - map (`tagOpacity 1`): `%{__struct__: Portal.Accounts.User, id: "USR0NbAb1xcFCy", email: "ada@portal.dev", role: :student}`
  - keys (`tagOpacity 1`): `Map.keys(user)` / `# => [:__struct__, :email, :id, :role]`
- Readout strings (`dfOut`) VERBATIM:
  - literal: `The <code class="inl">%User{}</code> literal shows the fields you set. The <code class="inl">__struct__</code> key is there too, but the sugar keeps it out of sight.`
  - map: `The map underneath reveals the <code class="inl">__struct__</code> key, set to <code class="inl">Portal.Accounts.User</code>. A struct is a map with this one extra key.`
  - keys: `<code class="inl">Map.keys/1</code> lists every key, <code class="inl">:__struct__</code> included — the struct is an ordinary map at runtime.`
- Degrade: the SVG ships the static four-row field set in markup (the `__struct__` row dimmed at `opacity="0.35"`), so it reads without JS; the `dfCode`/`dfOut` regions start empty and are filled by `pick('literal')` on load. No animation on this figure; the page-wide `prefers-reduced-motion: reduce` suppresses `.reveal` transitions on the References section.

### Footer build-stamp

- `id="stampId"` text: `TSK0NbNoVYqaS8`. `decodeBranded` yields: namespace `TSK`, snowflake `319515440533471232`, node `0`, seq `0`, timestamp **`2026-05-31 16:40:17 UTC`** (matching the static `st-ts` placeholder). Click / Enter / Space toggles the `.panel` open.

## References (#refs, verbatim)

Intro line: "Primary sources for this lesson, and where it connects in the course."

Sources:
- `https://hexdocs.pm/elixir/keywords-and-maps.html` — Keywords and maps — Elixir documentation — choosing a data shape.
- `https://hexdocs.pm/elixir/structs.html` — Structs — Elixir documentation — named, typed maps.
- `https://hexdocs.pm/elixir/Map.html` — `Map` — Elixir documentation — the map module.

Related in this course:
- `/elixir/language/structs` — F3.05 · Structs, maps & keyword lists
- `/elixir/language/structs/matching` — Pattern matching on a struct
- `/elixir/functional/adt/product` — F2.07 · Product types

## Wiring

- route-tag (verbatim): `/ elixir / language / structs / define` — `define` is the current segment (`.rcur`); `elixir`, `language`, `structs` are links.
- crumbs (verbatim): `F3` (links `/elixir/language`) / `F3.05` (links `/elixir/language/structs`) / `define` (here).
- toc-mini: `#reveal` "A struct is a tagged map"; `#define` "Declaring the fields".
- pager: prev → `/elixir/language/structs` "F3.05 · structs"; next → `/elixir/language/structs/defaults` "Next · keys & defaults".
- footer: identical three-column footer as the hub — Chapters (`/elixir/algebra`…`/elixir/phoenix`), The course (`/elixir`, `/elixir/course`, `/elixir/algebra/functions`), same foot tag.
- Page meta: `<title>` = `Defining a struct — F3.05.1 · jonnify`; `<meta name="description">` = `defstruct over Portal.Accounts.User: the %User{} literal as sugar over a map, and the hidden __struct__ key that names the module and makes a struct an ordinary map at runtime.`

## Build instruction

To rebuild this dive, copy the `<head>…</style>`, the `header.site`, the `footer.site-foot`, and the two trailing `<script>` blocks (the figure/stamp IIFE and the reveal-on-scroll enhancer) verbatim from a recent built sibling on the F3 elixir-purple accent. Change only the `<title>`/`<meta description>`, the `route-tag` segments, the crumbs, and the `<main>` body (hero, `#reveal` figure, `#define` code + bridge, references, pager). No-invent guards: use only the real Portal surfaces as written — the branded store (`USR0NbAb1xcFCy` is a real branded learner id), the event-sourced engine behind the ONE `Portal` facade, the Phoenix web app; `Portal.Accounts.User` is the running learner record. Do not invent fields beyond `id`/`email`/`role`, nor alter the `Map.keys/1` output or the `__struct__` mechanics; cite the companion F6 (`/elixir/phoenix`) for web/OTP internals rather than re-teaching them. Voice: no first person, no exclamation marks, no emoji, and none of just/simply/obviously. Model sibling to copy from: `elixir/language/structs/defaults.html` (same module, same accent, same shared head and scripts).
