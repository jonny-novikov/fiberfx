# Technical Writer — expert voice

The binding rules for the words in every lesson of the "Functional Programming in Elixir" course. A lesson that breaks them is not done. This file is self-contained: apply it without re-reading the source briefs.

## Audience

Working developers and technically literate readers. Assume competence. Never condescend, never pad with motivational filler, never explain what a variable is. The reader knows how to program; the job is to teach the functional way of thinking and its Elixir form.

## Voice

- Precise, confident, plain. Active voice. Short declarative sentences.
- State the idea, then support it. Lead with the conclusion, not the build-up.
- One idea per section. Concrete before abstract; the example earns the rule.
- Calm authority. The reader is being levelled with by someone who has shipped this, not sold to.

## Accuracy is non-negotiable

- Every technical claim is correct and checkable. If unsure, verify it or cut it.
- All code is idiomatic Elixir, compiles, and is minimal. Show output with a `# => ...` comment on the result line. Example:

  ```
  [1, 2, 3]
  |> Enum.map(&(&1 * 2))
  # => [2, 4, 6]
  ```

- Use terminology exactly. These distinctions carry weight in a functional course:
  - *function* ≠ *procedure* — a function maps inputs to outputs; it does not "do steps".
  - *expression* ≠ *statement* — Elixir evaluates expressions to values; it has no statements.
  - *bind* ≠ *assign* — `x = 1` binds the name `x` to the value `1`; it does not assign to a mutable cell. A later `x = 2` rebinds; it does not mutate.
  - *pattern match* ≠ *compare* — `{:ok, v} = result` matches structure and binds `v`; it does not test equality. `=` is the match operator, not assignment.
- Math is rigorous and readable. Use KaTeX with `$...$` (inline) and `$$...$$` (display). Define every symbol on first use. An arrow or composite that is mathematically wrong is worse than none.

## Honesty and trade-offs

- Name trade-offs, edge cases, and limits. Say plainly when a thing does **not** apply.
- No false certainty. Avoid "always" / "never" unless the statement is literally true.
- When the BEAM or Elixir reality differs from the textbook ideal, say so. Example: `Enum.reduce/3` is a left fold and tail-recursive (constant stack space), but building a list with `acc ++ [x]` inside it is quadratic — name that cost rather than hide it.
- Prefer the honest pair: *here is the clean idea; here is what it costs in practice.*

## Concision

Cut every word that carries no weight. If a sentence survives deletion without loss, delete it. Adjectives and adverbs earn their place by adding information, not emphasis.

## The bridge

This course teaches functional programming twice — as mathematics, then as Elixir — so every algebra or CS idea is paired *explicitly* with its Elixir counterpart. The reader should always see the correspondence, not infer it. Concretely:

- After defining an idea (a mapping, a fold, a closure), show its Elixir form in the same section.
- Use the `.bridge` container: a left cell labelled with the idea (e.g. `Algebra`, or a back-reference like `F1.07 · operators`) and a right cell labelled `Elixir`, joined by a `→`. Each cell is one or two sentences.
- Example pairing: *a function sends each domain element to exactly one codomain element* (idea) ↔ *`Enum.map/2` applies the function across a collection — the same mapping, one input to one output* (Elixir).

The bridge is what makes F1's algebra and F2's code read as two views of one thing.

## Forbidden

- Hype words: *revolutionary, blazing-fast, magical, simply, just, obviously, effortless*. The Apollo `voice` gate fails on any of these in visible text. The last three (*simply / just / obviously*) are dismissive — never aim them at the reader.
- Marketing exclamation. Emojis (unless explicitly requested).
- Hand-waving ("somehow", "it turns out") in place of an explanation.
- Reproducing copyrighted text; all prose is original.
- Gendered pronouns for tools or agents. Perceptual verbs with a tool or agent as subject (a function does not "see"; a fold does not "watch"). First-person narration ("I", "we", "our"). Keep prose impersonal.

## The seven-part lesson structure

Every lesson follows this order. The bracketed container is where each part lives (see `page-anatomy.md`).

1. **Lead** [`.hero`] — the one thing this lesson nails, in two sentences. An `.eyebrow` chapter tag, the `<h1>`, an italic `.lede`, a `.kicker` framing the scope, and a `.toc-mini` of on-page anchors.
2. **The idea, defined precisely** [`.prose` + `.deflist`] — state the concept; define each term on first use.
3. **Worked detail with a correct example** [`.fig`] — a small correct case, paired with an interactive that computes the real result and isolates this one idea.
4. **The Elixir form** [`pre.code`, usually inside the `.fig`] — idiomatic compiling Elixir with `# => output`.
5. **Why it matters downstream** [`.bridge` + `.take`] — the explicit idea↔Elixir pairing, then a one-sentence takeaway; name the later modules that depend on this.
6. **Recap** [a synthesis `section` + `.note`] — three to five crisp bullets, or a tight "What this lands" paragraph, then a `.note` pointing at the next module.
7. **Prev / Next** [`.pager`] — a ghost prev button and a solid next button, each to a real built route.

A hub page (a module with deep-dive subpages) keeps parts 1–5, replaces part 6 with a card grid of its dives plus a synthesis, and its pager links forward to the first dive.
