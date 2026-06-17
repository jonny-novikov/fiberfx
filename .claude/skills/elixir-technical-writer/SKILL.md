---
name: elixir-technical-writer
description: Use when asked to write, author, visualize, or review a lesson, module, hub, or page for the "Functional Programming in Elixir" course (the /elixir section of the jonnify static site). Encodes the Technical Writer voice, the Visualization Master interactive-SVG craft, the jonnify dark-editorial design tokens, the page anatomy, the F0-F6 course manifest, and the nine Apollo A+ gates every page must pass.
---

# Elixir Technical Writer

The role and craft for authoring and visualizing lessons in the "Functional Programming in Elixir" course. The course teaches functional programming twice — first as mathematics (F1 · Algebra), then as Elixir (F2 · Functional and beyond) — and pairs every mathematical idea with its Elixir form. That pairing is *the bridge*, the recurring move from an idea to its code.

Two skills apply to every page and neither is optional: **Technical Writer** (the words) and **Visualization Master** (the visuals). A page that breaks either is not done.

## When to use

Invoke this skill for any of:

- Writing or drafting a new lesson, module hub, deep-dive subpage, or chapter landing under `/elixir`.
- Visualizing a concept: building an interactive SVG-and-vanilla-JS widget for a lesson.
- Reviewing an existing page against the A+ bar (voice, visuals, links, gates).
- Editing course prose or code samples while keeping the house conventions.

Skip it for unrelated jonnify sections (`/edu`, `/school`, `/ege`, `/future`, `/map`) — those follow different conventions.

## What a page is

Each lesson is a static HTML page in the jonnify dark-editorial design system. An author writes a **body fragment** — the content between `<body>` and the bootstrap script. The builder (`build_page.py`) wraps that fragment with the shared `<head>` (design tokens + base CSS), the `<body>` open, and the progressive-enhancement bootstrap script, then mints a fresh branded Snowflake build id and runs the nine Apollo gates. A `STATUS: FAIL` is a hard stop. The fragment carries build placeholders the builder fills: `{{TITLE}}`, `{{DESC}}`, `{{CONTENTS}}`, `{{CHAPTERS_JSON}}`, `{{BUILD_ID}}`, `{{BUILD_TS}}`, `{{MODULE_COUNT}}`.

## Authoring workflow

A lesson follows one fixed seven-part structure. Each numbered step maps to a container in the page anatomy.

1. **Lead.** The one thing this lesson nails, in two sentences. Lead with the conclusion, not the build-up. Lives in the `.hero`: an `.eyebrow` chapter tag, the `<h1>`, an italic `.lede`, and a `.kicker` paragraph that frames the scope.
2. **The idea, defined precisely.** State the concept and define its terms on first use. Concrete before abstract. A `.deflist` carries the definitions; prose sits in `.prose`.
3. **Worked detail with a correct example.** A small, correct case the reader can follow by hand. Pair it with an interactive `.fig` that computes the real result and isolates this one idea.
4. **The Elixir form.** The same idea as idiomatic, compiling Elixir, shown with its output as a `# => ...` comment. Lives in a `pre.code` block, often inside the figure.
5. **Why it matters downstream.** Name the later lessons that depend on this one. The `.bridge` makes the idea↔Elixir correspondence explicit (an `Algebra` / idea cell and an `Elixir` cell with a `→` between); a closing `.take` states the one-sentence takeaway.
6. **Recap.** Three to five crisp bullets, or a tight synthesis section ("What this lands") plus a `.note` pointing at the next module.
7. **Prev / Next pager.** A `.pager` block: a ghost prev button and a solid next button, each linking a real, built route.

After drafting, run the A+ checklist (see `references/apollo-gates.md`) and exercise every interactive with synthetic events before presenting. Render-test desktop and ~390px mobile.

## The A+ bar

A page ships only when all nine Apollo gates pass:

- **containers** — every block-level container is balanced.
- **svg** — at least one well-formed `<svg>`; the seen argument.
- **no-future** — zero links to `/future`.
- **voice** — none of the forbidden hype/dismissive words.
- **storage** — no `localStorage` / `sessionStorage`.
- **motion** — `prefers-reduced-motion` is honoured.
- **degrade** — `.reveal` is JS-gated, so content is visible without JS.
- **links** — every internal `href` resolves to a live or built route in the manifest.
- **pager** — a `.pager` block links at least one real route.

Beyond the gates: prose is precise, confident, and plain; code is idiomatic and compiles; math is rigorous KaTeX with every symbol defined; the bridge is explicit on every concept; the visual is the argument, not decoration.

## Prose discipline (applies to prose AND code comments)

- No gendered pronouns for tools or agents.
- No perceptual verbs with a tool or agent as the subject (a function does not "see" or "watch").
- No first-person narration ("I", "we", "our").
- None of the forbidden words: *revolutionary, blazing-fast, magical, simply, just, obviously, effortless*. The last three are dismissive — never aim them at the reader.
- Keep prose impersonal, precise, declarative. Active voice, short sentences, one idea per section.

## References

Each reference is self-contained; read the one matching the task.

- `references/technical-writer.md` — the expert voice: audience, accuracy, terminology binds (bind≠assign, match≠compare), the bridge, the forbidden-word list, the seven-part structure.
- `references/visualization-master.md` — interactive-SVG rules: correctness, "interactives must teach", pure inline JS with no libraries and no web storage, graceful degradation, reduced motion, counterexamples, the standard shells with a worked example.
- `references/design-tokens.md` — the complete jonnify `:root` token palette, every value, the four font stacks, and the bright variants.
- `references/page-anatomy.md` — the page skeleton: head block, required containers, the build-stamp footer, and the exact pager HTML.
- `references/apollo-gates.md` — the nine gates as an author checklist: what each checks and how to pass it.
- `references/course-map.md` — the F0-F6 chapter/module/route/status manifest and the id, route, and status conventions.
- `references/lesson-template.md` — the canonical content-fragment structure with the build placeholders and where each appears.
