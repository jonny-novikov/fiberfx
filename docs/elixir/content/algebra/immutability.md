# F1.04 — Immutability & binding (dive / lesson)

- **Route (served):** `/elixir/algebra/immutability`
- **File:** `elixir/algebra/immutability.html`
- **Place in the chapter:** the fourth lesson of F1 · Algebra, opening the Structure movement. It surfaces the property the previous two lessons quietly relied on — a name keeps its value (so substitution is valid) and a function cannot alter its inputs (so composition is safe). It follows `F1.03` (composition) and precedes `F1.05` (collections).
- **Accent:** gold chapter accent (gold/elixir token palette).
- **Status:** built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F1 · Algebra`

`h1`: `Immutability & binding`

Hero lede (verbatim): "A name is a label fixed to a value, not a box you write into. Values do not change; you build new ones. And in Elixir the equals sign does not assign — it matches."

Kicker (verbatim): "This is the property the last two modules quietly relied on. Substitution is only valid because a name keeps its value, and composition is only safe because a function cannot reach back and alter its inputs. We separate three ideas that often blur together: binding a name, matching with the equals sign, and the immutability of the data itself."

## Sections

Three teaching sections, each closing with a `.bridge` and a `.take`:

1. **Names, not boxes** (`#binding`) — a binding attaches a name to a value, not a container; rebinding moves the name, not the value. A `.deflist` defines bind / rebind / immutable / pin (`^x`). Running example: `x = [1, 2, 3]`, `y = x`, `x = [0 | x]` — `y` is unchanged.
2. **Equals is a match** (`#match`) — `=` is the match operator, not assignment; the pin `^` matches the current value. Running example: four matches given `x = 1`. Bridge: a failed match raises a `MatchError`.
3. **Data that holds still** (`#immutable`) — values are immutable; an "update" returns a new value (cheap via structural sharing, referencing F0.1.3). Running example: immutable map updates on `%{a: 1, b: 2}`.

Synthesis "What this lands" closes the arc (naming F1.02, F1.03, F0.2, F4) and forwards to F1.05.

## The interactives

Three interactive figures plus the footer build-stamp decoder.

### Figure — "Binding · rebinding moves the name, not the value" (`#bindTitle`)

- Controls: a single `.fold-ctrl` slider `#bindStep` (step; min 0, max 2, step 1, value 2) with `#bindStepval` (shows `3 / 3`). No `.solid-select`.
- SVG (`viewBox="0 0 720 200"`): names `x` / `y`, arrows `#arrX` / `#arrY`, value boxes `#gValBot` (the new `[0, 1, 2, 3]`) and the original `[1, 2, 3]`, group `#gY`. Code block `#bindCode`, readout `#bindOut`.
- Pure function: `renderBind()` shows statements `['x = [1, 2, 3]', 'y = x', 'x = [0 | x]']` up to the chosen step (the current line wrapped in `.rdx`), toggles the y group / new-value visibility and the `#arrX` target, and writes the readout. Initial call `renderBind()`.
- Readout `#bindOut` (verbatim default, step 2): `x = [0, 1, 2, 3] · y = [1, 2, 3] · y is unchanged — rebinding x did not touch it`.

### Figure — "The match operator · given x = 1" (`#matchTitle`)

- Control group `#matchSel` ("Choose a match"), four buttons: `data-m="check" data-c="sage"` "1 = x" (active); `data-m="fail" data-c="elixir"` "2 = x"; `data-m="destr" data-c="gold"` "{a, b} = {1, 2}"; `data-m="pin" data-c="blue"` "^x = 2".
- SVG (`viewBox="0 0 720 120"`): expression box `#mExpr`, verdict badge `#mBadgeText` in `#mBadgeBox`, `#mVerdict`. Code block `#matchCode`, readout `#matchOut`.
- Pure function: `renderMatch()` reads `MATCHES` (`check` ok → "matches"; `fail` → "no match" / `MatchError`; `destr` ok → binds a=1, b=2; `pin` → "no match", pinned x is 1) and sets the expression, ✓/✗ badge, verdict text, code, and note. Initial call `renderMatch()`.
- Readout `#matchOut` (verbatim default): `match ✓ · 1 equals the current value of x · nothing new is bound`.

### Figure — "Immutable update · the original is never touched" (`#immTitle`)

- Control group `#immSel` ("Choose an operation"), three buttons: `data-op="add" data-c="gold"` "Map.put(m, :c, 3)" (active); `data-op="over" data-c="blue"` "Map.put(m, :a, 9)"; `data-op="del" data-c="elixir"` "Map.delete(m, :b)".
- SVG (`viewBox="0 0 720 210"`): original map beside the updated map, updated rows `#uA`/`#uAt`, `#uB`/`#uBt`, `#uC`/`#uCt`. Code block `#immCode`, readout `#immOut`.
- Pure function: `renderImm()` reads `IMM` (each op's code, the `updated` map literal, and per-row `{show, val, changed}`), sets the three updated rows via `setRow`, writes the code, and the readout. Initial call `renderImm()`.
- Readout `#immOut` (verbatim default): `original = %{a: 1, b: 2} (unchanged) · updated = %{a: 1, b: 2, c: 3} · a and b are shared`.

### Degrade behaviour

Controls, SVGs, and the default readouts render in static markup; `#bindCode`, `#matchCode`, `#immCode` are filled by JS on init. The page respects `prefers-reduced-motion` globally; no browser storage.

### Footer build-stamp decoder (`#stamp`)

- Stamp id: `TSK0NZJIrJnJi4` (in `#stampId`); panel `#st-ts` hard-codes "2026-05-30 10:41:57 UTC" (the decoded UTC timestamp).
- Pure functions: `b62decode(s)`, `pad2(x)`, `decodeBranded(id)` (`ns = id.slice(0,3)`, `snow = b62decode(id.slice(3))`; `ts = snow >> 22n`, `node = (snow >> 12n) & 0x3FFn`, `seq = snow & 0xFFFn`; `EPOCH_MS = 1704067200000`). Toggle on click / Enter / Space.

## References (#refs, verbatim)

No `#refs` References section is present on this page. The lesson's cross-links are the crumbs, toc-mini, `.note`, pager, and footer (see Wiring); the prose names F0.1.3 (structural sharing), F0.2 (processes), F1.02, F1.03, F1.08, and F4.

## Wiring

- **route-tag:** `<span class="rsep">/</span><a href="/elixir">elixir</a><span class="rsep">/</span><a href="/elixir/algebra">algebra</a><span class="rsep">/</span><span class="rcur">immutability</span>`.
- **crumbs:** `F1 · Algebra` → `/elixir/algebra` · sep `/` · `F1.03` → `/elixir/algebra/composition` · sep `/` · here `F1.04` (no link).
- **toc-mini:** `#binding` ("Names, not boxes") · `#match` ("Equals is a match") · `#immutable` ("Data that holds still").
- **pager:** prev → `/elixir/algebra/composition` ("← F1.03 · composition"); next → `/elixir/algebra` ("More in F1 · Algebra →"). (The synthesis `.note` names F1.05 as "(planned)".)
- **footer:** identical three-column footer — brand → `/elixir`; `Chapters` F1–F6; `The course` `/elixir`, `/elixir/course`, `/elixir/algebra/functions`.
- **Page meta:** `<title>` "Immutability & binding — F1.04 · jonnify"; `<meta description>` "A name is a fixed value, not a box: binding versus rebinding, the match operator and the pin, and immutable data whose updates return new values."

## Build instruction

To (re)build this lesson, copy the `<head>…</style>`, `<header class="site">`, `<footer class="site-foot">`, and the two trailing `<script>` blocks verbatim from a recent built gold-accent sibling — the model is `elixir/algebra/composition.html` (F1.03, the same lesson template: crumbs, toc-mini, three figures, the step-slider and `.rdx` highlight pattern, `.bridge`/`.take` rhythm) — then change only `<title>`/`<meta>`, the route-tag, the crumbs, and the `<main>` body. No-invent guards: use only the real Portal surfaces as written (branded store, event-sourced engine behind one `Portal` facade, Phoenix web app); this lesson is pure algebra and names no engine internals — cite the companion course for OTP internals, do not re-teach. Voice rules: no first person, no exclamation marks, no emoji, none of just/simply/obviously.
