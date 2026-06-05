# F3.05 — Structs, maps & keyword lists (module hub)

- Route (served): `/elixir/language/structs`
- File: `elixir/language/structs/index.html`
- Place in the chapter: the fifth module of F3 · The Elixir Language. It frames the three containers for key-and-value data — the `map`, the `keyword list`, and the `struct` — then takes the struct apart over three deep dives (`define` → `defaults` → `matching`). It follows F3.04 (`enum & streams`) and leads into F3.06 (`protocols`), where the struct tag becomes the basis for polymorphism.
- Accent: elixir (purple), `--elixir:#b39ddb` / `--elixir-bright:#cdb8f0`.
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F3 · Data & shape · module 5`

Hero `h1` (verbatim): Shaping data with `structs`

Hero lede (verbatim):

> The collections walked in F3.04 were maps — loose bags of keys and values. That works until a value needs a guaranteed shape: a learner is always an id, an email, and a role, never something else. Elixir gives three containers for key-and-value data — the **map**, the **keyword list**, and the **struct** — and the skill is knowing which one a situation calls for.

Kicker line (verbatim):

> The portal's `Portal.Accounts.User` is the running example. The same learner data fits all three shapes; this module shows what each one guarantees and gives up, then takes the struct apart over three deep dives.

## What the page frames

The hub teaches one section (`#shapes`, "Three shapes, one record") then lists the three dives (`#dives`, "Three deep dives"). The dives, in order:

- F3.05.1 · Defining a struct — `defstruct` over `Portal.Accounts.User`, the `%User{}` literal, and the `__struct__` key that makes a struct a map. Route: `/elixir/language/structs/define`. Built.
- F3.05.2 · Enforcing keys & defaults — `@enforce_keys` for required fields and default values in `defstruct` — what fills in, and what fails. Route: `/elixir/language/structs/defaults`. Built.
- F3.05.3 · Matching on a struct's type — the `%User{}` pattern, dispatch by struct tag across function clauses, and the `is_struct/2` guard. Route: `/elixir/language/structs/matching`. Built.

The dives carry no status pill (they are plain link cards, not `.mod` pills); each card shows its `F3.05.N` number, title, and one-line summary. The cards are left-bordered by accent: define = `--elixir`, defaults = `--blue`, matching = `--gold`.

Running example: `Portal.Accounts.User` — the same learner data (`id`, `email`, `role`) rendered as a map, a keyword list, and a struct.

The bridge cells (idea → Elixir) read: "F2.07 · product types" — "A product type holds several fields together — a name and a fixed shape, all present at once." → "F3 · the struct" — "A struct is a product type with a name: a fixed set of fields over a map, tagged with its module."

The closing `.note`: start with `/elixir/language/structs/define`, then `/elixir/language/structs/defaults`, then `/elixir/language/structs/matching`. Next module: **F3.06 — Protocols & behaviours**, where the struct tag becomes the basis for polymorphism.

## The interactives

### Hero figure — "Reaching one field"

- `<figure>` `aria-labelledby="acTitle"`; figcaption label (id `acTitle`): "Reaching one field".
- Control group: two buttons. `id="acBtn"` label "▸ next container" (entity `&#9656;`); `id="acReset"` label "reset" (class `hp-btn ghost`).
- SVG element ids: the redrawn access-path group `id="acPath"`; the caption readout `id="acCap"` (`aria-live="polite"`) with spans `.lst` (container name) and `.ohint` (cost hint).
- The cycle is data-driven by the JS `STEPS` array (no named pure function); the `render(animate)` function rebuilds the path rows from the current step. `btn` advances `idx = (idx + 1) % STEPS.length`; `reset` returns `idx = 0`.
- The three steps' readout strings VERBATIM (`.lst` line / `.ohint` line):
  - map: `map · hashed access` / `Any key, resolved at run time · about O(log n).`
  - keyword list: `keyword list · linear scan` / `Ordered pairs, walked one by one · O(n).`
  - struct: `struct · fixed key set` / `Keys settled at compile time · a bad field fails the build.`
- Each step's row labels VERBATIM (label / sub / note):
  - `MAP · %{role: :student}` / `hash :role → one bucket` / `any key, checked at run time`
  - `KEYWORD LIST · [role: :student]` / `scan pairs in order` / `walk until a key matches`
  - `STRUCT · %User{role: :student}` / `fixed key set, known at compile time` / `a wrong key is a compile error`
- Degrade: the SVG ships a static initial state in the markup (the map path — hashed lookup, value `:student`), so it reads without JS. The default caption in markup is `map · hashed access` / `Any key, resolved at run time · about O(log n).` Under `prefers-reduced-motion: reduce`, the `.hp-row.hp-new` slide-in `animation:none` (the `hpIn` keyframe is suppressed).

### Section figure — "The same record, three shapes · select one"

- `<figure>` `aria-labelledby="shTitle"`; heading (id `shTitle`): "The same record, three shapes · select one".
- Control group `id="shSel"` (`role="group"`, `aria-label="Data shape"`), three buttons (data-k / data-c / label):
  - `data-k="map"` `data-c="elixir"` (active) — "map"
  - `data-k="kw"` `data-c="blue"` — "keyword list"
  - `data-k="struct"` `data-c="gold"` — "struct"
- SVG element ids: `shBox` (the literal box, stroke recoloured per shape), `shBoxT` (the literal text), property dots `shP0` (order is kept), `shP1` (duplicate keys allowed), `shP2` (key set is fixed at compile time); readout `id="shOut"` (`aria-live="polite"`).
- Driving function: `pick(k)` — sets the active button, recolours `shBox`, writes the literal into `shBoxT`, fills the three property dots from `SHAPE[k].props`, and writes `SHAPE[k].out` into `shOut`. `setDot(el, on)` toggles each dot fill/stroke. On load `pick('map')`.
- Per-shape literals (`shBoxT`) VERBATIM:
  - map: `%{email: "ada@portal.dev", role: :student}`
  - keyword list: `[email: "ada@portal.dev", role: :student]`
  - struct: `%User{email: "ada@portal.dev", role: :student}`
- Property booleans (`order`, `duplicate keys`, `fixed key set`): map `[false, false, false]`; kw `[true, true, false]`; struct `[false, false, true]`.
- Readout strings (`shOut`) VERBATIM:
  - map: `A <b style="color:var(--elixir-bright)">map</b> takes any keys and lets you add or drop them at runtime. Keys are unique and unordered, and nothing fixes the shape — reach for it when the keys are open-ended.`
  - kw: `A <b style="color:var(--blue-bright)">keyword list</b> is an ordered list of <code class="inl">{atom, value}</code> pairs; order is kept and keys may repeat. That is why function options are passed this way.`
  - struct: `A <b style="color:var(--gold-bright)">struct</b> fixes its key set at compile time and tags the value with its module. Under the hood it is a map with a <code class="inl">__struct__</code> key — the only one a compiler can check.`
- Takeaway (`.take`, verbatim): "No shape is best everywhere: a map for open-ended data, a keyword list for ordered options, a struct when a value must always carry the same fields. A struct is the only one of the three that a compiler can check."

### Footer build-stamp

- `id="stampId"` text: `TSK0NbNoUyVvns`. The `decodeBranded` decoder (base-62, epoch `1704067200000`) yields: namespace `TSK`, snowflake `319515439996600320`, node `0`, seq `0`, timestamp **`2026-05-31 16:40:17 UTC`** (matching the static `st-ts` placeholder in markup). Click / Enter / Space toggles the `.panel` open.

## References (#refs, verbatim)

Intro line: "Primary sources for this lesson, and where it connects in the course."

Sources:
- `https://hexdocs.pm/elixir/keywords-and-maps.html` — Keywords and maps — Elixir documentation — choosing a data shape.
- `https://hexdocs.pm/elixir/structs.html` — Structs — Elixir documentation — named, typed maps.
- `https://hexdocs.pm/elixir/Map.html` — `Map` — Elixir documentation — the map module.

Related in this course:
- `/elixir/functional/adt` — F2.07 · Algebraic data types
- `/elixir/language/structs/define` — F3.05.1 · Defining a struct
- `/elixir/language` — F3 · The Elixir Language

## Wiring

- route-tag (verbatim): `/ elixir / language / structs` — `structs` is the current segment (`.rcur`); `elixir` links `/elixir`, `language` links `/elixir/language`.
- crumbs (verbatim): `F3 · The Elixir Language` (links `/elixir/language`) / `F3.05 · structs` (here).
- toc-mini: `#shapes` "Three shapes, one record"; `#dives` "Three deep dives".
- pager: prev → `/elixir/language/enum-streams` "F3.04 · enum & streams"; next → `/elixir/language/structs/define` "Start · defining a struct".
- footer: three columns. Chapters — `/elixir/algebra` "F1 · Algebra", `/elixir/functional` "F2 · Functional Programming", `/elixir/language` "F3 · The Elixir Language", `/elixir/algorithms` "F4 · Algorithms & Data Structures", `/elixir/pragmatic` "F5 · Pragmatic Programming", `/elixir/phoenix` "F6 · Phoenix Framework". The course — `/elixir` "Course home", `/elixir/course` "Contents & history", `/elixir/algebra/functions` "Start · F1.01". Foot tag: "Functional Programming in Elixir — functional thinking taught twice: first as mathematics, then as idiomatic Elixir."
- Page meta: `<title>` = `Structs, maps & keyword lists — F3.05 · jonnify`; `<meta name="description">` = `Three containers for key-and-value data — the map, the keyword list, and the struct — and when each fits, with the portal's User as the running example.`

## Build instruction

To rebuild this hub, copy the `<head>…</style>`, the `header.site`, the `footer.site-foot`, and the two trailing `<script>` blocks (the figure/stamp IIFE and the reveal-on-scroll enhancer) verbatim from a recent built sibling on the F3 elixir-purple accent — the cleanest model is the chapter landing `elixir/language/index.html` for the hub shell, or any sibling F3 module hub. Change only the `<title>`/`<meta description>`, the `route-tag` segments, the crumbs, and the `<main>` body (hero, `#shapes` figure, `#dives` card list, references, pager). No-invent guards: use only the real Portal surfaces as written — the branded store (`USR…` ids), the event-sourced engine behind the ONE `Portal` facade, the Phoenix web app; `Portal.Accounts.User` is the running learner record. Do not invent struct fields, module names, or readout strings beyond what the page shows; cite the companion F6 (`/elixir/phoenix`) for OTP/web internals rather than re-teaching them. Voice: no first person, no exclamation marks, no emoji, and none of just/simply/obviously. Model sibling to copy from: `elixir/language/structs/define.html` (same chapter, same accent, same shared head and scripts).
