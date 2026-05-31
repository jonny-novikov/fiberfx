# Authoring Skills — Functional Programming in Elixir

Binding rules for every article and lesson in this course. Two skills apply to
every page: **Technical Writer** (the words) and **Visualization Master** (the
visuals). They are not suggestions; a lesson that breaks them is not done.

---

## Skill 1 — Technical Writer (expert voice)

**Audience.** Working developers and technically literate readers. Assume
competence. Never condescend, never pad with motivational filler, never explain
what a variable is.

**Voice.**
- Precise, confident, plain. Active voice. Short declarative sentences.
- State the idea, then support it. Lead with the conclusion, not the build-up.
- One idea per section. Concrete before abstract; the example earns the rule.
- Calm authority. The reader should feel they are being levelled with by someone
  who has shipped this, not sold to.

**Accuracy is non-negotiable.**
- Every technical claim is correct and checkable. If unsure, verify or cut it.
- All code is idiomatic Elixir, compiles, and is minimal. Show output with `# => ...`.
- Use terminology exactly: *function* ≠ *procedure*; *expression* ≠ *statement*;
  *bind* ≠ *assign*; *pattern match* ≠ *compare*. Define notation on first use.
- Math is rigorous and readable. Use KaTeX `$...$`. Define every symbol.

**Honesty.**
- Name trade-offs, edge cases, and limits. Say when a thing does **not** apply.
- No false certainty, no "always/never" unless literally true.
- When the BEAM/Elixir reality differs from the textbook ideal, say so.

**Concision.** Cut every word that carries no weight. If a sentence survives
deletion without loss, delete it.

**The bridge (this course specifically).** Each algebra/CS idea is paired
*explicitly* with its Elixir counterpart. The reader should always see the
correspondence, not infer it.

**Forbidden.**
- Hype words: *revolutionary, blazing-fast, magical, simply, just, obviously,
  effortless*. (`simply/just/obviously` are dismissive — never aim them at the reader.)
- Marketing exclamation. Emojis (unless explicitly requested).
- Hand-waving ("somehow", "it turns out") in place of an explanation.
- Reproducing copyrighted text; all prose is original.

**Structure of a lesson.**
1. Lead: the one thing this lesson nails, in two sentences.
2. The idea, defined precisely.
3. Worked detail with a correct example.
4. The Elixir form (code + output).
5. Why it matters downstream (what later lessons depend on it).
6. Recap: 3–5 crisp bullets.
7. Prev / Next navigation.

---

## Skill 2 — Visualization Master (extra skill)

**Premise.** Every non-trivial concept gets something *seen*, not only read. The
visual is the argument, not decoration.

**Correctness.** Diagrams are geometrically/mathematically accurate. An arrow
that lies is worse than no arrow. Interactives compute the real thing and are
tested with synthetic events before shipping.

**Interactives must teach.**
- Respond to input, update live, and isolate one idea.
- Carry a clear prompt, a live readout (mono, `--gold-bright`), and a one-sentence
  takeaway *after* the widget.
- Counterexamples teach: show what the concept is **not** (e.g. "not a function").
- Pure inline JS, no external libraries, no `localStorage`/`sessionStorage`.
- Degrade gracefully: content is visible without JS; reveal-on-scroll only adds the
  fade via JS (`IntersectionObserver`).
- Respect `prefers-reduced-motion` for any looping animation.

**Craft.**
- SVG only (no raster), `viewBox`-based and fluid. Clean line-art, labelled axes/nodes.
- Use the design tokens below. Accent colour carries meaning, never random.
- Subtle motion at high-impact moments; never gratuitous.

**Design tokens (jonnify).**
- Ink `#0a0e1a` / `--ink-2 #10162b`; cream `#ece4d0` / `--cream-soft`.
- Gold `#d4a85a` / `--gold-bright #f0cd7f` (primary accent, results).
- Blue `#5a87c4` / `--blue-bright #9fc0ea`; sage `#7ba387` / `--sage-bright`;
  burgundy `#c4504c` (warnings/counterexamples); **Elixir `--elixir #b39ddb`** (FP/code accent).
- Lines `--line #2a3252`. Fonts: Cormorant Garamond + PT Serif (serif),
  Manrope (sans), JetBrains Mono (mono; ligatures render `|>` and `==` natively).

**Standard interactive shells.**
- `.solid-select` toggle buttons (`.active` uses the meaning colour).
- `.fold-ctrl` slider rows (`label` min-width + range, `accent-color`).
- `.geo-readout` live readout line.
- `.drag-svg [data-drag]` for draggable handles (pick nearest within ~26px,
  map via `getScreenCTM().inverse()`, support mouse + touch).
- Each widget sits inside prose: text -> widget -> takeaway. Never two widgets back to back.

---

## Build discipline

- Build every page with `build_page.py` (`extract-head` once, then `build`). Treat
  any `STATUS: FAIL` as a stop. Common failure: an unclosed `<div class="wrap">`
  in a section — close it before `</section>`.
- 0 links to `/future` from course pages. Prev/Next must point at real routes.
- Render-test each page (desktop + ~390px mobile) and exercise every interactive
  with synthetic events before presenting.
