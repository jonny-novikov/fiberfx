# Course Creation Principles

How to design a chapter, its modules, and its quizzes so that the result is consistent, trustworthy, and pleasant to learn from. This document is about *content and structure*; the machinery that enforces it lives in [Toolkit & Quality Gates](toolkit-and-quality-gates.md).

## 1. Pedagogy first

Five principles drive every authoring decision. They matter more than any template.

> **Concrete before abstract.** Open with the thing the reader already lives with — a socket, a bill, a battery — and only then name the formula. The order is always *phenomenon → analogy → formula → calculator → application*, never the reverse.

> **One formula does a lot.** Each chapter is anchored by a single iconic equation (the *hero formula*). Most of the chapter is that one relationship seen from different angles. Reuse the same formula across modules whenever it genuinely applies — repetition of a small, true core beats a parade of new symbols.

> **A calculator beats a paragraph.** Wherever a reader would rather *try a number* than read about it, give them an interactive instead of prose. Every module has exactly one hands-on moment for this reason.

> **Prove every number before it ships.** No displayed figure — not in prose, not in a worked example, not in a quiz answer — appears until it has been verified in code. Trust is the product's main asset, and it is built one correct number at a time.

> **Safety and wellbeing are design constraints, not disclaimers.** For any hazardous subject, teach *models and rules*, never operational instructions. The reader should finish understanding *why* something is dangerous and *how protection works*, with no recipe for harming themselves. (See §7.)

## 2. The unit hierarchy

The course is a strict tree. Each level has a fixed job.

| Level | Job | Key surface |
|-------|-----|-------------|
| **Home** | Sell the course and route into it | Hero with anchor formulas, chapter grid, approach section, finale block, sticky section-nav |
| **Chapter landing** | Frame one big idea and list its modules | Hero formula, lead + intro, key points, module tiles, quiz CTA |
| **Module** | Teach one concept end-to-end | 4 content sections + 1 interactive + 5-question quiz + chapter navigation |
| **Chapter quiz** | Consolidate the whole chapter | 8 questions with per-answer explanations |
| **Finale** | Recap the course and certify it | Un-numbered recap landing + final test with a score tally |

The numbering is linear and the navigation is a single chain: `Home → Ch1 → … → ChN → Finale`. Inside a chapter the chain is `Landing → 1.1 → 1.2 → … → Chapter quiz → next chapter`.

## 3. Anatomy of a chapter (the landing)

A chapter landing is configured as data — one dictionary of fields — and rendered by the generator. Designing a chapter means filling that dictionary thoughtfully.

| Field | Purpose | Guidance |
|-------|---------|----------|
| `slug` | URL segment | One clear lowercase word (`tok`, `schet`, `bezopasnost`) |
| `num` | Chapter number | Linear; the finale is the only un-numbered node |
| `pal` | Palette key | One distinct accent colour per chapter (see §3.1) |
| `h1` | On-page title | The plain idea, with one emphasised phrase |
| `hero_formula` | The chapter's anchor equation | The single most memorable relationship of the chapter |
| `lead` / `intro` | Two framing paragraphs | Lead = the hook; intro = what the chapter will do |
| `points[4]` | Four "what you'll get" bullets | Concrete promises, each tied to a module |
| `modules[]` | Module tiles | `(num, slug, title, one-line topic)` per module |
| `prev` / `nxt` | Navigation | The chapter's place in the linear chain |

The landing's only call-to-action beyond the module tiles is the **chapter quiz** at `/{slug}/kviz`.

### 3.1 One accent per chapter

Each chapter owns a colour from a shared palette (electric blue, amber, green, red, purple, rose, teal …). The accent threads through the hero, formula chips, interactive controls, and navigation, so a reader always knows which chapter they are in. When you add a chapter, pick a hue that is visibly distinct from every existing one — distinctiveness is the priority, not theme-matching. Adding a palette entry must never change the rendered output of existing pages (see the toolkit's byte-stability rule).

### 3.2 The hero formula

Choose the one equation the chapter is *about*. Examples from the physics course:

- Ток / Ohm: $U = I R$
- Мощность: $P = U I$
- Счёт: $S = E \cdot p$
- Трансформаторы: $\frac{U_1}{U_2} = \frac{N_1}{N_2}$

The hero formula appears once in the landing hero as a chip and is restated in the relevant module's formula box. Keep it short; if a chapter seems to need two hero formulas, it is probably two chapters.

## 4. Anatomy of a module

A module is the workhorse. It obeys one rule above all:

> **The 4 + 1 + 5 rule.** Every module has **4** content sections, **1** interactive, and a **5**-question quiz. The fixed shape makes modules interchangeable to build and predictable to learn from.

### 4.1 The four content sections

Each section is a `kicker → h2 → lead`, followed by either a prose block (a short paragraph, a tight list, an optional callout) or a **formula box**. The four sections move from *why this matters* to *the rule* to *seeing it work* to *what to do with it*. A typical arc:

1. **Framing** — why the concept matters in daily life.
2. **The rule** — the formula box plus a worked example.
3. **The interactive** — the hands-on moment (see §5).
4. **Application / nuance** — myths, edge cases, or a practical checklist.

Sections are anchored for a sticky scroll-spy navigation; there are always exactly four anchors.

### 4.2 The single interactive

One — and only one — interactive per module. It is the "do it yourself" beat that a paragraph cannot replace. Its design is drawn from a small, reusable taxonomy (§5). Whatever the type, it follows the interactive conventions in §5.1.

### 4.3 The five-question quiz

Five questions close the module. Authoring conventions:

- **One fact per question.** Each question checks a single idea from the module.
- **Correct answer first.** By convention the correct option is authored at index `0`; the generator/validator relies on this. Display order can be shuffled later if desired, but the data keeps the answer first.
- **Explanation leads with the key term in bold**, then one sentence of *why*. The explanation teaches, it does not merely confirm.
- **Plausible distractors.** Wrong options should be things a confused learner might actually believe, not jokes.

### 4.4 Navigation furniture (every module)

A module is never a dead end. It always carries: a progress bar, a breadcrumb with the chapter and module number, a safety banner, a sticky four-link scroll-spy section-nav, previous/next navigation cards that form the chapter chain, and a "to top" control. These are not optional — they are part of what makes the catalog feel like one product, and they are checked by the validator on every page.

### 4.5 Module configuration fields

| Field | Purpose |
|-------|---------|
| `slug`, `num`, `name` | Identity and breadcrumb label |
| `chapter`, `chnum`, `chname`, `pal` | Which chapter it belongs to (drives breadcrumb + accent) |
| `h1`, `lead` | On-page title and hook |
| `hero_formula` | The rendered chip (chapter anchor or a module-specific relation) |
| `secnav[4]` | The four scroll-spy labels |
| `sections[4]` | The four section bodies (prose/formula boxes + the interactive) |
| `takeaway[4]` | Four one-line summaries shown at the end |
| `quiz[5]` | The five questions |
| `interactive_js` | The JavaScript for this module's interactive |
| `quiz_key` | The localStorage key (course-namespaced; see §9) |
| `prev`, `nxt` | The chapter chain links |

## 5. The interactive taxonomy

Interactives are the heart of the course, and they are not invented from scratch each time. Six patterns cover almost everything; new modules pick one and parameterise it.

| Pattern | Reader does | Output | Example |
|---------|-------------|--------|---------|
| **Calculator** | Enters numbers | A computed result + plain-language reading | Bill `= E · p`; UPS runtime `t = E/P`; transformer `U₂ = U₁·N₂/N₁` |
| **Slider model** | Drags one value | A live verdict by band | Body-current model; mains-voltage model (normal / low / high) |
| **Segmented toggle** | Picks a mode | A comparison or scenario explainer | DC vs AC; grounding on/off; protection scenarios; voltage- vs current-regulation |
| **Audit checklist** | Ticks boxes | A score out of N + a message | Home-safety checklist; battery-care checklist |
| **Appliance table** | Toggles rows, edits numbers | A sum, a current, or a ranking | The "flagship" load/cost table (sum of powers → bill or overload verdict) |
| **Animated schematic** | Watches / toggles | A visual of a process | Conventional current vs electron flow |

The **appliance table** is the recurring "flagship" — the most substantial interactive in a chapter, reused across courses by swapping the row list and the per-row computation.

### 5.1 Interactive conventions (all types)

> **Results are plain text, never math delimiters.** Computed output strings contain no `$...$`. Decimals are localised by replacing the dot with a comma in the display string, so a result reads `13,04 А`, not `13.04`.

> **Validate defensively.** Reject missing, negative, or zero-where-impossible inputs with a short, kind message rather than showing `NaN`.

> **Compute the default state on load.** Sliders and toggles show a sensible result immediately, before the reader touches anything.

> **Isolate per module.** Element IDs are prefixed per interactive (`iz-`, `tr-`, `vp-`, `sb-` …) so two interactives never collide, and each page is fully standalone.

> **Always disclaim learning calculators.** A one-line note that values are not saved or transmitted — and, for any hazardous model, an explicit "never test this on yourself" warning.

## 6. Anatomy of a quiz

There are two quiz species, and they are deliberately different.

### 6.1 Chapter quiz

Eight questions spanning the whole chapter, using the shared quiz engine. It has a progress bar and breadcrumb but **no** section-nav (it is a single activity, not a reading). Its progress is stored under a chapter-scoped localStorage key. Same authoring conventions as the module quiz (§4.3), at chapter scope.

### 6.2 Final test (the finale)

Twelve questions spanning the entire course, with one crucial difference: it runs on an **isolated engine** that adds a result panel — final score, percentage, and a grade band — revealed once every question is answered.

> **Why a separate engine.** The final test needs scoring behaviour the per-question engine does not have. Rather than modify the shared engine (which would ripple into every quiz and break the byte-identical guarantee), the finale ships its own copy with the extra panel. *Add a parallel component; never mutate a shared one to serve a single page.*

Grade bands are simple and encouraging (for example: all correct → "Отлично — полный балл"; high → "Отличный результат"; mid → "Хороший результат"; low → "Стоит перечитать главы"). The reader should always be nudged forward, never shamed.

## 7. Safety and wellbeing by design

Some subjects can hurt a reader if taught carelessly. The system treats this as a structural constraint.

- **Models, not instructions.** A hazardous topic is taught as a *calculation* and a *set of rules*. The body-current model, for instance, shows why mains voltage is deadly and carries an explicit warning never to test it — it is never a how-to.
- **First aid stays standard and conservative.** Cut the power first, do not touch a person under voltage, call emergency services. Nothing experimental.
- **No reframing toward risk.** If a request would turn a model into a recipe for harm, it is refused, not "made safe."
- **Restraint over reassurance.** When a topic is sensitive, say less and keep it factual.

These rules generalise beyond electricity to any subject touching physical risk, health, money, or vulnerable readers.

## 8. The authoring workflow (per iteration)

Courses are built in small, reviewable increments, each a complete pass through the build cycle.

> **Pace: roughly two to four modules per iteration, with review between.** Small batches keep quality high and make regressions easy to localise. Larger explicit batches are fine when the structure is well understood (e.g. finishing a chapter: remaining modules + chapter quiz in one pass).

Each iteration runs the **strict build cycle** end to end (detailed in the toolkit doc): verify the math → fill the generators → build → preflight scan → run the validator suites → check byte-for-byte regression → update the docs → rewrite the progress tracker → scan for stray math characters → deliver the new pages. Nothing is delivered until every gate is green.

### 8.1 Navigation rewiring discipline

When the structure changes — inserting a chapter, renumbering, re-pointing a "next" link — some existing pages legitimately change. The rule is to make those changes *intended and accounted for*: snapshot the site, rebuild, and confirm that exactly the pages you meant to touch changed and **every other page is byte-identical**. An unexpected diff is a bug; an expected one is named in the changelog. (Example: inserting an advanced chapter between Ch5 and the finale changed exactly three prior pages — two "next" links and one landing — and nothing else.)

### 8.2 Documentation hygiene

Three living documents travel with every course:

- a **content map** (the full table of contents with per-page status),
- a **status journal** (newest entry on top, one paragraph per iteration: what was built, what changed, the gate totals), and
- a **progress tracker** (a fresh, reader-facing snapshot rewritten each iteration).

Keeping these current is part of the cycle, not an afterthought — they are how a multi-month, multi-course effort stays coherent.

## 9. Naming and namespacing

| Thing | Convention |
|-------|------------|
| Slugs | One clear lowercase word; the route mirrors the tree (`/{course}/{chapter}/{module}`) |
| Links | Always root-relative |
| localStorage keys | **Course-prefixed**, then chapter and module: e.g. `phys-<chapter>-<module>-quiz`, `phys-<chapter>-kviz`, `phys-final-test` |
| HTML structure | No nested anchors; cards that wrap an inner link use a `div` as the outer element |

> **Why namespacing is non-negotiable.** Courses that share an origin also share `localStorage`. Without a per-course prefix, the logic course and the law course would silently overwrite each other's quiz progress. The prefix is cheap insurance against a confusing, hard-to-reproduce bug.

## 10. Adapting the system to a new subject

The same machine builds any course. Porting is a short, repeatable checklist:

1. **Name the chapters** and give each a single hero formula or core relationship.
2. **Assign a distinct palette** to each chapter.
3. **Map every topic to a verifiable interactive** from the taxonomy (§5) — if a topic has no number to compute or model, it usually belongs in prose, not an interactive.
4. **Write the math verifier first** for every figure the course will display.
5. **Build two to four modules per iteration**, running the full cycle each time.
6. **Keep the safety constraints** (§7) wherever the subject touches risk, money, or vulnerable readers.

The applied-math lineup — logic and decision-making, everyday law, personal finance, entrepreneurship, learning science — all reuse this exact structure. The unifying brand idea is *school physics and mathematics as a practical tool*, and the system's job is to make every course in that line feel like one trustworthy product.
