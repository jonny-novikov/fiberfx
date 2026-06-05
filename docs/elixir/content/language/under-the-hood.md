# F3 — Under the hood (front-matter reading 3)

- **Route (served):** `/elixir/language/under-the-hood`
- **File:** `elixir/language/under-the-hood.html`
- **Place in the chapter:** the third of three optional front-matter readings the F3 landing routes the reader through "before the lessons" (reading 3 of 3). It shows the compile pipeline (source → bytecode → BEAM) so that macros later in the chapter are less mysterious; it follows reading 2 (`/elixir/language/timeline`) and hands off to the first lesson, `/elixir/language/values`.
- **Accent:** elixir (purple); the `<h1>` accent word `hood` is the `<span class="ex">`.
- **Status:** built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow: `F3 · before the lessons · reading 3`

`<h1>`: Under the `hood`

Lede (verbatim):

> Elixir is a compiled language. Source files become bytecode for the BEAM, the same virtual machine Erlang runs on. Knowing the few steps in between makes the rest of the chapter — especially macros — far less mysterious.

No `.kicker` line is present on this reading.

## Sections

In order: `#pipeline` ("From source to bytecode" — first interactive), `#codeasdata` ("Code is data" — second interactive).

- **From source to bytecode (`#pipeline`):** the compilation pipeline figure, stepping the expression `1 + 2` through six stages.
- **Code is data (`#codeasdata`):** prose on the AST / quoted form being an ordinary `{form, metadata, arguments}` tuple, the second figure (`quote · select an expression`), and a `.bridge` from "Homoiconicity" to "Macros".
- **Running example:** none of the Portal domain; the page works with the literal expression `1 + 2` and small quoted forms.
- **`.take` (verbatim):** "Only one of these steps is unusual: macros run during compilation and can rewrite the tree before it becomes bytecode. That is the feature the next idea explains."
- **`.note` (verbatim):** "A compiled `.ex` file becomes a `.beam` module on disk; an `.exs` script is evaluated without writing one. Everything is an expression, and everything ultimately runs as lightweight processes on the BEAM. Next: **F3.01 — Values, types & IEx**, where the lessons begin."

## The interactives

### Figure 1 — "The compilation pipeline · select a stage" (`#pipeline`)
- **Markup:** `<figure class="fig" aria-labelledby="plTitle">` titled "The compilation pipeline · select a stage"; an `<svg viewBox="0 0 1000 120">` with six `<g class="pl-node" data-i="0..5" role="button" tabindex="0">` stage boxes (source · tokens · AST · expanded · bytecode · BEAM VM), a live `pre.code#plCode`, and a `.geo-readout#plNote` (both `aria-live="polite"`).
- **Pure function:** `renderPl()` — highlights the `plSel` stage box (stroke `#cdb8f0`, fill `#1a1530`), writes the stage's `code` into `#plCode.textContent`, and writes `#plNote` as `<b>stage N / 6</b> — note`. Wired via `click`/`keydown` on each `.pl-node`; default `plSel = 0`.
- **`STAGES` dataset (verbatim code/note per stage):** `1 + 2` / "What you write in a .ex file — Elixir source text."; `[{:int, 1}, {:op, :+}, {:int, 2}]` / "The tokenizer splits the text into tokens: two integers and an operator."; `{:+, [line: 1], [1, 2]}` / "The parser builds the quoted form — a {form, metadata, arguments} tuple. This is the AST."; `{:+, [line: 1], [1, 2]}` / "Macros run here, rewriting the tree. 1 + 2 uses no macros, so it passes through unchanged."; `{gc_bif, :+, [x0, x1] => x2}   # schematic` / "Compiled to compact BEAM bytecode and written to a .beam module on disk."; `3` / "The bytecode runs on the BEAM virtual machine and produces a value."

### Figure 2 — "quote · select an expression" (`#codeasdata`)
- **Markup:** `<figure class="fig" aria-labelledby="aTitle">` titled "quote · select an expression"; a `.controls > .solid-select#astSel` group of three buttons, an `<svg viewBox="0 0 720 140">` with three labelled tuple boxes (`#astForm`, `#astMeta`, `#astArgs` under FORM / METADATA / ARGUMENTS), a live `pre.code#astCode`, and a `.geo-readout#astNote`.
- **Control buttons (`#astSel`):** `data-k="add" data-c="elixir"` ("1 + 2", starts `active`); `data-k="call" data-c="blue"` ("sum(1, 2)"); `data-k="match" data-c="gold"` ("x = 2").
- **Pure function:** `renderAst(key)` — toggles each `#astSel` button's `active`/`aria-pressed`, writes the `form`/`meta`/`args` `<text>` nodes, rebuilds `#astCode` as the highlighted tuple, and writes `#astNote.innerHTML = e.note`. Wired via `click` per button.
- **`EXPR` dataset (verbatim form/meta/args/note):** add → `:+` / `[]` / `[1, 2]` / "An operator call — + is a function named :+ applied to 1 and 2."; call → `:sum` / `[]` / `[1, 2]` / "A function call — the form is the function name as an atom."; match → `:=` / `[]` / `[{:x, [], Elixir}, 2]` / "= is a call to the := form; the left side is a variable node, itself a tuple."
- **Degrades:** the six pipeline stage boxes and the three quote-expression buttons (with the default `1 + 2`/`:+`/`[]`/`[1, 2]` tuple in static markup) are present without JS; the prose and the `.bridge` ("Homoiconicity" → "Macros") carry the content. No browser storage; `prefers-reduced-motion` respected globally.

### Footer build-stamp decoder (`#stamp`)
- **Stamp id:** `TSK0Nb9nIqLN2G` (in `#stampId`); panel `#st-ts` hard-codes "2026-05-31 13:24:06 UTC". The `decodeBranded` function (epoch `1704067200000`) decodes it to `ns=TSK · node=0 · seq=0 · 2026-05-31 13:24:06 UTC`, matching `#st-ts`. Toggle on click / Enter / Space.

## References (#refs, verbatim)

This reading carries no `#refs` References block (the `.refs` styles are absent from its `<style>`; only `values` and `playground` carry one). The compile-pipeline and AST facts are cited inline in the prose.

## Wiring

- **route-tag:** `<span class="rsep">/</span><a href="/elixir">elixir</a><span class="rsep">/</span><a href="/elixir/language">language</a><span class="rsep">/</span><span class="rcur">under-the-hood</span>`.
- **crumbs:** `F3 · The Elixir Language` → `/elixir/language` · sep `/` · here `Under the hood` (no link).
- **toc-mini:** `#pipeline` ("Source to bytecode") · `#codeasdata` ("Code is data").
- **pager:** prev → `/elixir/language/timeline` ("← The timeline"); next → `/elixir/language/values` ("Start the lessons · F3.01 →").
- **footer (`.foot-nav`, three columns):** Chapters → `/elixir/algebra`, `/elixir/functional`, `/elixir/language`, `/elixir/algorithms`, `/elixir/pragmatic`, `/elixir/phoenix`; The course → `/elixir`, `/elixir/course`, `/elixir/algebra/functions`; brand + foot-logo both → `/elixir`.
- **Page meta:** `<title>` "Under the hood — F3 · jonnify"; `<meta name="description">` "How Elixir source becomes BEAM bytecode: tokenizing, parsing to the quoted AST, macro expansion, and the Erlang VM that runs the result."

## Build instruction

To rebuild this front-matter reading, copy the `<head>`…`</style>`, `<header class="site">`, `<footer class="site-foot">`, and the two trailing `<script>` blocks verbatim from a recent BUILT sibling on the elixir (purple) accent — the closest model is the sibling reading `elixir/language/history.html` (same eyebrow form `F3 · before the lessons · reading N`, same `.solid-select` select figure, and like this page no `.refs` block) — then change only `<title>`/`<meta>`, the route-tag, and the `<main>` body. Keep both interactives (`renderPl`/`STAGES` and `renderAst`/`EXPR`) and the branded-stamp decoder. Preserve clamp-spacing (`clamp(2.7rem,1.9rem + 4.2vw,5.1rem)`; spaces around `+` are load-bearing). No-invent guards: describe only the real compile stages and quoted-form tuples as written; the chapter's running example is a learning `Portal` whose only real surfaces are a branded store, an event-sourced engine behind ONE `Portal` facade, and a Phoenix web app — invent no others, and cite the companion course for OTP/BEAM internals rather than re-teaching them. Voice: no first person, no exclamation marks, no emoji, and none of *just*/*simply*/*obviously*. Model sibling to copy from: `elixir/language/history.html` (front-matter reading), or this page `elixir/language/under-the-hood.html`.
