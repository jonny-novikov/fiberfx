# Authoring technical courses on the jonnify system — a playbook for Claude agents

This document is a complete, self-contained brief for any Claude agent picking up this project in a
new session. It describes the design principles, the build system, the conventions, the quality bar,
and the exact workflow used to produce the course *Functional Programming in Elixir*. Follow it to
continue that course, or adapt it to build a different technical course on the same foundation.

A resuming agent has no memory of prior sessions. Treat the attached `build_page.py` as the single
source of truth for the manifest and the gates; treat this document as the reasoning and the
workflow around it. Where the two ever disagree, the code wins — re-read it.

## 1. How to use this playbook

Read sections 2 through 5 to understand what is being built and why. Read 6 through 16 to learn the
machinery. Section 17 is the workflow you run for every page; section 18 is a worked recipe. Section
20 tells you the current state and what comes next. The appendices are copy-paste material: a
fragment skeleton, a validator block template, a command cheat-sheet, and the verified facts the
course rests on.

Two standing rules govern everything:

1. **Reuse, do not reinvent.** The design system, the builder, the ID convention, and the validator
   already exist and are proven. Author new content into them; do not rebuild them.
2. **Validate without images.** Validation is headless and text-only. Do not take screenshots and do
   not open PNGs. The image budget is a hard, shared constraint across a long-running session.

## 2. The product

A course is a set of interconnected static HTML pages rendered with the **jonnify** dark-editorial
design system. There is no framework and no runtime — each page is self-contained HTML, inline CSS
delivered from a shared head, one inline `<script>`, and one or more inline SVG or HTML interactive
components. Pages are flat files; the navigation between them is by route.

The course currently has six numbered chapters plus an optional history chapter, and fifty-four
modules in total. When you describe the scope to a reader, say "six chapters, fifty-four modules,
plus an optional history chapter." Do not compute a different total.

Every page is built from a hand-authored **fragment** in `content/` plus a shared head and a set of
template tokens. The builder assembles the fragment into a finished page, runs nine quality gates,
and writes the result as a flat HTML file.

## 3. Pedagogy and the running project

Three ideas shape the content.

**One idea per page.** A module page (a hub) introduces a concept; its subpages each take one facet
deeper. A reader should be able to name the single thing a page taught them.

**Every concept has a bridge.** Each lesson pairs the idea with its concrete counterpart in the
language being taught. On these pages the pairing is rendered with the `.bridge` component: an *idea*
cell on the left, an arrow, and an *Elixir* cell on the right. The bridge is not decoration; it is
the moment the abstract becomes executable.

**Every page computes something real.** Each page carries at least one interactive component that
performs the actual operation under discussion — not an animation of it, the operation itself — with
a live readout and a one-sentence takeaway. See section 14 for the full contract.

A single real-world project threads through the entire course so that examples accumulate instead of
resetting. The reader is building the very portal they are reading on: a learning platform with
magic-link authentication and progress tracking, later gaining Phoenix LiveView and telemetry. Reuse
this domain in examples rather than inventing new ones. The shape, stable across the course:

| Context | Functions | Sample entity |
|---|---|---|
| `Portal.Accounts` | `get_user/1`, `get_user_by_email/1`, `register/1` | `%User{id: "USR0NbAb1xcFCy", email: "ada@portal.dev"}` |
| `Portal.Auth` (magic link) | `request_link/1`, `verify/1` → `{:ok, claims}` \| `{:error, :expired \| :invalid}`, `start_session/1`, `current_user/1` | `%Session{id: "SES0NbAb29FnXc"}` |
| `Portal.Catalog` | `list_courses/0`, `list_lessons/1`, `get_lesson/1` | `%Lesson{id: "LSN0NbAb2Lk9GS"}` |
| `Portal.Progress` | `complete/2`, `completed?/2`, `progress_for/1`, `percent_complete/1`; emits `{:lesson_completed, user_id, lesson_id}` | progress records keyed by user and lesson |

## 4. The non-negotiables

These are the contract. A page is not done until all hold.

- **A+ on all nine Apollo gates.** No exceptions, no partial grades shipped. See section 15.
- **Voice.** The visible prose never contains: *revolutionary, blazing-fast, magical, simply, just,
  obviously, effortless*. No exclamation marks, no emoji. The forbidden-word check is part of every
  page's validation and you must read its output.
- **Accessibility and degradation.** Static content is present in the HTML and readable with
  JavaScript disabled; interactives enhance it but are not required to understand the page. All
  animation respects `prefers-reduced-motion`. Every interactive has an accessible label.
- **No browser storage.** No `localStorage`, no `sessionStorage`. State lives in the DOM and in
  JavaScript variables for the life of the page.
- **No external dependencies in pages.** Vanilla JavaScript only. No libraries, no CDNs, no network
  calls from a page.
- **Branded Snowflake build stamp.** Every page carries the footer stamp and the decoder. See
  section 13.

## 5. Repository layout

Work in `/home/claude/elixir-course/`. The shape that matters:

| Path | Role |
|---|---|
| `build_page.py` | Single source of truth: the manifest, the assembler, the nine gates, the ID tools, and the CLI. ~1460 lines, standard library only. |
| `content/` | Hand-authored page fragments (the body of each page). One fragment per page. |
| `*.html` (repo root) | Built pages, written flat by the builder. These render in the client. |
| `_head.html` | Cached `<head>` the assembler injects into every page. Regenerated from `HEAD_CSS` by `extract-head`. |
| `validator/` | The headless, zero-screenshot validation harness. See section 16. |
| `functional-programming-in-elixir.md` + `_gen_course_md.py` | The course outline document and its generator. |
| `elixir-references.md` + `_gen_refs_md.py` | The curated references document and its generator. |

Built outputs are also copied to `/mnt/user-data/outputs/` when presented to the reader.

## 6. The builder: the manifest model

`build_page.py` holds the entire course structure as Python data. Five structures matter.

**`CHAPTERS`** — a list of dicts, one per chapter, each with `id` (e.g. `"F3"`), `title`, `slug`,
`route`, `status`, `one` (a one-line summary), `reuses`, and `accent` (the chapter's colour family).
`ROOT_ROUTE` is `/elixir`.

**`MODULES`** — a dict keyed by chapter id, mapping to a list of module dicts. Each module has `id`
(e.g. `"F3.04"`), `title`, `one`, `slug`, `status`, and `lab` (a boolean marking the chapter's
capstone lab). `module_count()` returns 54 (the six numbered chapters at nine modules each; the
history chapter's modules are not counted in that total).

**`SUBPAGES`** — a dict keyed by *module* id, mapping to a list of subpage dicts (`slug`, `title`,
`one`). A module with subpages is a hub; its subpages are the deep dives. Subpages are not modules
and are not counted as modules.

**`CHAPTER_SUBPAGES`** — a dict keyed by *chapter* id, mapping to front-matter subpages that sit
under the chapter route rather than a module. These are how front-matter such as the "Elixir for C#
developers" onramp and the F3 history pages are attached.

**`PAGES`** — a dict keyed by a short page key (e.g. `"f3-4"`), mapping to a tuple of
`(fragment_path, output_filename, title, description)`. This is what the builder reads to assemble a
page. Hub and subpage keys are registered here; output filenames must be unique across the whole
site, so when a slug repeats across chapters give the pages distinct output filenames.

The status vocabulary is `live`, `built`, `planned`. `LINKABLE = {"live", "built"}`. Only linkable
chapters, modules, and subpages produce routes the link gate will accept; a `planned` module is
described on its chapter landing as "in production" and is not linked anywhere.

## 7. The builder: routes and linkability

`allowed_routes()` computes the set of internal routes a page may link to. It includes the root
route; each chapter route whose chapter is linkable; each module route whose module is linkable;
each module-subpage route whose parent module is linkable; and each chapter-subpage route whose
chapter is linkable. The link gate (section 15) rejects any internal `/`-prefixed href not in this
set. External `https://` links are exempt from the link gate.

Two consequences to internalise. First, you cannot link a page that is still `planned` — promote it
to `built` first. Second, when you build a dynamic href in JavaScript, construct it so the literal
route string appears in the source for the gate to see; the pattern used throughout is
`'<a href=' + JSON.stringify(route) + '>'`.

Helper functions you will use: `_module_route(mid)` returns a module's `(route, status)`;
`subpages_of(mid)` and `chapter_subpages_of(cid)` return the registered subpages.

## 8. The builder: assembly tokens and generators

`_assemble()` injects the cached head and then replaces a set of template tokens that may appear in
any fragment:

- `{{CONTENTS}}` → the rendered contents directory (every chapter with its modules).
- `{{CHAPTERS_JSON}}` → the chapter data as JSON (history chapter excluded).
- `{{BUILD_ID}}` → a freshly minted branded Snowflake ID for this build.
- `{{BUILD_TS}}` → a human-readable build timestamp.
- `{{MODULE_COUNT}}` → 54.

Because these are replaced on every page, any fragment may use any of them. The landing page and the
history/contents page use `{{CONTENTS}}`; the footer stamp on every page uses `{{BUILD_ID}}` and
`{{BUILD_TS}}`.

`render_contents()` emits the directory: per chapter, a heading with the chapter id and title, an
"open chapter" link if the chapter is linkable (otherwise a status pill) and its one-liner, then a
card per module. Chapter-level subpages are not shown in the directory, so front-matter such as the
C# onramp is reachable only from the page that links it directly (the contents page).

There is a build-order gotcha. `_assemble()` reads the `<head>` from the cached `_head.html`, not
from the live `HEAD_CSS` constant. After any edit to `HEAD_CSS`, run `python3 build_page.py
extract-head` and then rebuild, or your CSS change will not appear.

## 9. The builder: the CLI

```
python3 build_page.py build --page KEY     # assemble one page, run gates, write the file
python3 build_page.py build --all          # build every registered page
python3 build_page.py check FILE.html      # run the nine gates on a built file, print the grade
python3 build_page.py manifest             # print the chapter/module manifest
python3 build_page.py routes               # print every allowed route
python3 build_page.py id mint              # mint a branded Snowflake ID
python3 build_page.py id decode ID         # decode a branded ID to its parts
python3 build_page.py extract-head         # rewrite _head.html from HEAD_CSS (run after HEAD_CSS edits)
```

## 10. The jonnify design system

The look is a quiet, editorial dark theme: deep ink backgrounds, warm cream text, a single accent
family per chapter, and serif display type over a sans body scale. All colours are CSS custom
properties defined in `HEAD_CSS` (roughly 15.7 KB of tokens and component styles).

Colour tokens:

| Token | Value | Use |
|---|---|---|
| `--ink` / `--ink-2` / `--ink-3` | `#0a0e1a` / `#10162b` / `#161d38` | page, panel, raised panel |
| `--cream` / `--cream-soft` / `--cream-dim` | `#ece4d0` / `#d7cfb9` / `#a39c89` | body text, secondary, muted |
| `--gold` / `--gold-bright` | `#d4a85a` / `#f0cd7f` | F1 accent; literals and atoms in code |
| `--blue` / `--blue-bright` | `#5a87c4` / `#9fc0ea` | F0 and F6 accent |
| `--sage` / `--sage-bright` | `#7ba387` / `#a7c9b1` | F4 and F5 accent; strings in code |
| `--elixir` / `--elixir-bright` | `#b39ddb` / `#cdb8f0` | F2 and F3 accent; keywords and module names in code |
| `--burgundy` (text `#e08f8b`) | `#c4504c` | warnings, the "not yet" state |
| `--line` | `#2a3252` | hairlines, inactive strokes |

Fonts: `--serif-display` Cormorant Garamond (headings), `--serif` PT Serif (prose), `--sans` Manrope
(labels and UI), `--mono` JetBrains Mono (code and readouts). The mobile breakpoint is `@760px`.

## 11. Page anatomy

Every page fragment follows the same spine, in this order:

1. A skip link, then the site `<header>` with the brand and a nav that carries a `.route-tag`
   showing this page's route.
2. A `.hero`: `.crumbs` (the breadcrumb trail), an `.eyebrow` (chapter and position), an `<h1>` with
   the accent word wrapped in `<span class="ex">`, a `.lede`, a `.kicker`, and a `.toc-mini`.
3. One or more `<section>`s. A teaching section pairs prose (`.prose`) with a `.fig` containing the
   interactive, a code block (`pre.code`) where relevant, a `.geo-readout` live region, and a
   closing `.take` (the one-sentence takeaway). Concept pairings use `.bridge`. A `.note` carries the
   forward pointer to the next module.
4. A `.pager` with a ghost button back and a solid button forward.
5. The site footer with the `.stamp` and the decoder script.

The contents and landing pages add the directory components (`.contents`, `.chap`, `.chap-head`,
`.cid`, `.mods`, `.c-one`, `.chap-link`) and, on the landing only, the journey motif
(`.hero-motif`, `.arc-flow`, `.arc-node` with `.num` and `.nm`, `.arc-readout`).

## 12. Components and code-token spans

Reusable component classes include: `.solid-select` (a button group; each button takes
`data-c=blue|sage|gold|elixir|burg` for its accent and gains `.active` when selected); `.fold-ctrl`;
`.geo-readout` (a live readout, with `.dim` for a muted variant); `.take`; `.fig`; `.deflist` with
`dt`/`dd`; `.note`; `.bridge` (a grid of `.cell.idea` and `.cell.elix` separated by `.arrow`, each
cell labelled with `.lbl`); the pager set (`.pager`, `.btn`, `.ghost`, `.spacer`); `.stamp`; and the
inline code mark `code.inl`.

Code blocks use `pre.code` with hand-applied token spans. The vocabulary:

| Span | Colour | For |
|---|---|---|
| `.op` | elixir-bright | every keyword and operator: `def`, `defp`, `case`, `do`, `end`, `when`, `with`, `for`, `if`, `&lt;-`, `\|&gt;`, `-&gt;`, `=`, `&`, and so on |
| `.fn` | cream | function names |
| `.fn.blue` / `.fn.sage` / `.fn.gold` / `.fn.elixir` | elixir-bright | module names, tinted by family |
| `.fn.burg` | `#e08f8b` | module names in a warning context |
| `.res` | gold-bright | literals and atoms (`true`, `:ok`, numbers) |
| `.cmt` | cream-dim | comments |
| `.str` | sage-bright | strings |

There is no `.kw` class. Do not invent one; keywords use `.op`.

## 13. Branded Snowflake IDs

IDs are integer Snowflakes with a namespaced, base62-encoded string form. Use the integer form for
keys and the branded string as a human-facing, cross-system pivot. The branded form is a three-letter
uppercase namespace followed by the base62 encoding of the Snowflake, left-padded to eleven
characters — fourteen characters in total.

The constants (in `build_page.py` and in the footer decoder):

- Epoch: `1704067200000` ms (2024-01-01 UTC).
- Layout: `timestamp(41) << 22 | node(10) << 12 | seq(12)`, with masks `NODE = 0x3FF`, `SEQ =
  0xFFF`, and shifts `TS = 22`, `NODE = 12`.
- Base62 alphabet: `0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz`.

The convention is verified by a worked example: `TSK0KHTOWnGLuC` decodes to the Snowflake
`274557032793636864`, which is `2026-01-27 15:11:37 UTC`. `python3 build_page.py id mint` produces
valid `TSK…` IDs; `id decode` reverses one.

Every page carries the footer stamp and a decoder script that fills `#st-ns`, `#st-snow`,
`#st-node`, `#st-seq`, and `#st-ts` from `#stampId`. Copy the decoder block verbatim into each
fragment (it is in Appendix A). The validator asserts that the namespace decodes to `TSK` and the
Snowflake to a numeric string, so a broken stamp fails validation.

## 14. The interactive component contract

Each page carries at least one interactive. Every one must:

- be an inline SVG or an inline HTML widget, driven by vanilla JavaScript with no libraries;
- perform the real operation under discussion and show its actual result, not a canned animation;
- expose a live readout (`.geo-readout`, an `aria-live` region) that updates as the reader interacts;
- carry a one-sentence `.take` stating what the interaction demonstrates;
- degrade: the surrounding HTML must teach the point on its own with scripting disabled, and the
  interactive's controls and SVG must be present in the static markup (JavaScript populates state,
  it does not create the page);
- respect `prefers-reduced-motion`;
- never use browser storage.

The patterns in use: a `.solid-select` button group whose handler reads `data-*` attributes and
recomputes a readout, a code box, and an SVG state; SVG figures drawn once in the static markup and
mutated by attribute (stroke, opacity, text content) on interaction; and small pure functions that
compute the displayed result from a fixed data set so the readout is always truthful.

A frequent self-inflicted defect: `create_file` does not interpret escapes, so a literal `\u2014`
written inside HTML appears verbatim instead of as an em dash — use `&mdash;` or a real `—` in HTML.
The same escape written inside a JavaScript string literal *is* interpreted at runtime, so those are
fine.

## 15. The Apollo A+ quality gates

`apollo(doc)` runs nine gates and grades A+ only if all pass. The gates and what each enforces:

| Gate | Enforces |
|---|---|
| `containers` | the expected structural containers are present |
| `svg` | at least one well-formed SVG |
| `no-future` | no links to a `/future` route (nothing links ahead of where it should) |
| `voice` | none of the forbidden words appear in visible prose |
| `storage` | no `localStorage` / `sessionStorage` |
| `motion` | `prefers-reduced-motion` is honoured |
| `degrade` | static content is visible without JavaScript (JS-populated interactives are acceptable) |
| `links` | every internal href is in `allowed_routes()` |
| `pager` | a well-formed pager is present |

Run `python3 build_page.py check FILE.html` to see the per-gate result and the grade. A page ships
only at A+.

## 16. The headless validator

Validation that screenshots and opens images does not scale across a long session; it consumes a
shared image budget. The `validator/` package replaces that step entirely with headless,
text-reporting checks.

- `validator/validator.js` — a `Validator` class that drives headless Chromium through Playwright,
  reads the live DOM, computed styles, attributes, element counts, visibility, and horizontal
  overflow, and prints PASS/FAIL as text. It captures no images. Key methods: `start`, `stop`,
  `open(path)`, `title`, `noHorizontalOverflow`, `expectText`, `expectTextEquals`, `expectStyle`,
  `expectAttr`-style attribute reads, `expectCount`, `expectVisible`, `click`, `fill`, `settle`,
  `report`.
- `validator/visual.js` — an optional `VisualTester` that adds pixel-diff regression. It writes
  baseline, current, and diff PNGs to disk and reports the diff as text; it embeds nothing, so it
  also consumes no image budget. It needs `pixelmatch` and `pngjs`, installed once with
  `npm install` in `validator/`. The DOM validator is the default workhorse; visual regression is
  for when an intentional layout change needs a pixel guard.
- `validator/suite.elixir.js` — the adopted course suite. It subclasses `Validator` into a
  `CourseValidator` that adds console and page-error capture (`noConsoleErrors`), an attribute
  assertion (`expectAttr`), a branded-stamp assertion (`expectDecoded`, which checks the namespace is
  `TSK` and the Snowflake is numeric), and a `base(titleSub)` helper bundling the universal gates:
  title, at least one SVG, decoded stamp, no horizontal overflow, and no console errors. A `block(v,
  label, fn)` runner converts a thrown error into a recorded failure and honours an `ONLY`
  environment variable: only blocks whose label contains the `ONLY` substring run.

Playwright resolves in this environment without installation for the DOM checks. Run the suite with:

```bash
BASE_URL="file:///home/claude/elixir-course" node validator/suite.elixir.js
# validate only the page(s) you built (small output):
BASE_URL="file:///home/claude/elixir-course" ONLY="enum-streams" node validator/suite.elixir.js
```

Each page's block opens the page, runs `base(...)`, then exercises its interactive with `click` +
`settle` + `expectText`/`expectAttr`, reproducing as text exactly what a screenshot would have shown.
A mobile pass repeats the overflow and console checks at 390px. The suite exits non-zero on any
failure.

## 17. The authoring workflow

Run this for every new module. Steps 1 to 7 promote and wire the page; step 8 validates it without
images; step 9 delivers it.

1. **Author the fragment(s)** in `content/`. Hub plus subpages for a module with deep dives.
2. **Promote the module** to `status="built"` in `MODULES`.
3. **Register subpages** in `SUBPAGES[module_id]` (or `CHAPTER_SUBPAGES[chapter_id]` for
   front-matter).
4. **Register pages** in `PAGES`: the hub key and one key per subpage, each with a unique output
   filename.
5. **Relink the previous module**: update its `.note` and pager to point forward to the new module,
   and drop any "in production" wording.
6. **Light up the chapter landing**: on the landing fragment, change the new module's journey node
   stroke from `#2a3252` to the lit `#cdb8f0`, add the route and an "available now" status to the
   landing's `MODS` JavaScript object, and turn the directory entry from plain text into a link
   marked available.
7. **Verify routes** with a short Python check against `allowed_routes()`: confirm the new routes are
   present and that the next, still-planned module is absent.
8. **Validate with zero images**, in this order:
   - Voice sweep and read the output:
     ```bash
     grep -nE '\bjust\b|\bsimply\b|\bobviously\b|\beffortless\b|\bmagical\b|\brevolutionary\b|\bblazing\b' content/FRAG.html
     ```
     A clean sweep prints nothing; an echo of "CLEAN" only means the grep found nothing. Read it.
   - Build: `python3 build_page.py build --page KEY` (and rebuild the relinked pages and the
     landing).
   - Gates: `python3 build_page.py check OUT.html` — expect grade A+ and nine passes.
   - JavaScript: extract the longest `<script>` per page and run `node --check` on it.
   - Headless validator: append a tagged block to `validator/suite.elixir.js`, then run it with
     `ONLY=<tag>`.
9. **Deliver** with `present_files`, primary page first, then a brief summary.

The user on this project has at times re-sent an identical request mid-task. If that happens, do not
re-author the work; execute the remaining `present_files` and summary.

## 18. Worked recipe: a new module with three subpages

This is the shape of the F3.04 build, generalised.

1. Decide the hub and the three facets. The hub introduces the concept and carries an interactive
   that frames it; each subpage takes one facet deeper with its own interactive. Order the facets so
   the most distinctive idea lands last.
2. Author the hub fragment: header with the module route tag; hero; a framing interactive; a
   "deep dives" section of three cards linking the subpages; a `.bridge` to the relevant earlier
   chapter; a `.note` pointing to the next module; pager back to the previous module and forward to
   the first subpage; footer stamp.
3. Author each subpage fragment: header with the subpage route tag; hero; the facet's interactive
   with a live readout and a `.take`; a static code block grounding it in the running project; a
   `.bridge`; a `.note`; pager linking the sibling subpages, with the last subpage's forward pager
   returning to the chapter overview.
4. Promote, register, relink, light up, verify, validate, deliver — section 17.

A concrete example of "compute the real thing": the F3.04 streams subpage demonstrates eager versus
lazy traversal by counting how many records each strategy actually examines. The interactive walks a
fixed eight-record history; the eager path reports examining all eight, the lazy path stops at the
third match and reports five; both return three results. The readout states the count, and the
`.take` states the lesson. Nothing is faked — the counts are computed from the data and the pattern.

## 19. Voice and writing guide

The prose is calm, precise, and concrete. Lead with the idea, ground it immediately in the running
project, and close the section with a single-sentence takeaway. Avoid hype; the forbidden words in
section 4 are a hard filter, but the spirit is broader — let the mechanism be interesting rather than
announcing that it is.

The standard rhythm of a teaching section: a `.lede` states the idea in two or three sentences; a
`.kicker` connects it to the portal; the interactive lets the reader operate it; the `.take` names
the lesson; a `.bridge` pairs the idea with its Elixir form; a `.note` points forward. Keep code
blocks short and use the token spans so they read as code, not as plain text.

## 20. Course map and what comes next

The chapters, accents, and routes:

| Chapter | Title | Accent | Route | Status |
|---|---|---|---|---|
| F0 | History (also the contents page) | blue | `/elixir/course` | live |
| F1 | Algebra | gold | `/elixir/algebra` | live |
| F2 | Functional Programming | elixir | `/elixir/functional` | live |
| F3 | The Elixir Language | elixir | `/elixir/language` | live |
| F4 | Algorithms & Data Structures | sage | `/elixir/algorithms` | planned |
| F5 | Pragmatic Programming | sage | `/elixir/pragmatic` | planned |
| F6 | Phoenix Framework | blue | `/elixir/phoenix` | planned |

Current module state:

- **F0** — both modules built (`fp-evolution`, `beam-evolution`); chapter subpage `csharp` (the
  "Elixir for C# developers" onramp) built; the chapter landing doubles as the contents page.
- **F1** — all nine built (`functions`, `substitution`, `composition`, `immutability`,
  `collections`, `recursion`, `higher-order`, `pattern-matching`, `plotting-lab`).
- **F2** — all nine built (`pure`, `persistence`, `higher-order`, `recursion`, `folds`, `closures`,
  `adt`, `composition`, `pipeline-lab`).
- **F3** — `values`, `match`, `modules`, `enum-streams` built; chapter subpages `history`,
  `timeline`, `under-the-hood` built. Still planned: `structs`, `protocols`, `processes`, `otp`,
  `playground` (the lab).
- **F4, F5, F6** — all modules planned.

**Resume here.** The next module is **F3.05, Structs**. Thread the running project: the maps that
`Enum` and `Stream` walked in F3.04 gain a name and a shape — a struct. Likely subpages: defining a
struct over a Portal entity, enforcing keys and defaults, and pattern-matching on a struct's type.
After structs come `protocols` (where the Enumerable protocol from F3.04 pays off), `processes`,
`otp`, and the `playground` lab. F6 is where the portal gains Phoenix LiveView; F5 is where it gains
telemetry. Some modules take subpage hubs; decide per module.

Modules that have shipped subpage hubs so far: F2.04 through F2.08, F3.02, F3.03, and F3.04. Chapter
subpages exist on F0 and F3.

## 21. Course documentation deliverables

Two markdown documents accompany the pages and should be regenerated as modules build.

- `functional-programming-in-elixir.md`, from `_gen_course_md.py` — the outline, with a table per
  chapter listing modules and their subpages and a Mermaid diagram of the structure. Regenerate it
  after promoting modules so it reflects the F2.09 and F3.01–F3.04 work.
- `elixir-references.md`, from `_gen_refs_md.py` — the curated references, with URLs validated. An
  open enhancement is to wire references into the builder as a `references` manifest field with a
  `render_references()` footer rather than keeping them in a separate document.

## 22. Starting a brand-new course

The system is course-agnostic. To build a different technical course on it:

1. Replace the `CHAPTERS` and `MODULES` manifests with the new outline. Keep the status vocabulary
   and the dict shapes.
2. Choose an accent assignment per chapter from the existing colour families, or extend `HEAD_CSS`
   with a new family and re-run `extract-head`.
3. Choose a single running real-world project for the new domain and thread it through examples, the
   way the learning portal threads through this one.
4. Replace "the bridge" target if the language differs: the left cell stays the idea; the right cell
   becomes the new language's form. Keep the `.bridge` component.
5. Keep the page anatomy, the interactive contract, the branded Snowflake stamp, the nine gates, and
   the headless validator unchanged. Point the validator suite's page list and assertions at the new
   pages.

Everything in sections 11 through 17 transfers without change.

## 23. Files attached for a deferred session

To continue this course in a new session, the following are provided alongside this document:

- `build_page.py` — the manifest, assembler, gates, ID tools, and CLI. The source of truth.
- `validator/validator.js`, `validator/suite.elixir.js`, `validator/visual.js`,
  `validator/README.md`, `validator/package.json` — the headless validation harness and its suite.
- `content/f3-04-enum-streams.html` — a canonical hub fragment (framing interactive, deep-dive
  cards, bridge, pager, stamp).
- `content/f3-04-1-enum.html` — a canonical subpage fragment (computed interactive over portal data,
  static code block, bridge, pager, stamp).
- `enum-streams.html` — a fully built page, as a rendered reference of the target output.
- `_gen_course_md.py` and `_gen_refs_md.py` — the documentation generators.

Reconstruct the rest from `content/` and the manifest. The appendices below are enough to author a
new page from nothing.

---

## Appendix A — fragment skeleton

A minimal, buildable fragment. Replace the route tags, ids, copy, and the interactive body; keep the
spine and the decoder verbatim. The `data-c` accent on the selector should match the chapter family.

```html
<a class="skip" href="#main">Skip to the lesson</a>

<header class="site">
  <div class="wrap">
    <a class="brand" href="/elixir">jonnify<span class="dot"></span><span class="sub">knowledge map</span></a>
    <nav>
      <a href="/elixir/course">Contents</a>
      <span class="route-tag">/elixir/CHAPTER/MODULE/SUBPAGE</span>
    </nav>
  </div>
</header>

<main id="main" class="wrap">
  <section class="hero">
    <div class="crumbs">
      <a href="/elixir/CHAPTER">Fn</a><span class="sep">/</span>
      <a href="/elixir/CHAPTER/MODULE">Fn.NN</a><span class="sep">/</span>
      <span class="here">subpage</span>
    </div>
    <p class="eyebrow">Fn.NN &middot; part X of Y</p>
    <h1>Title with an <span class="ex">accent</span> word</h1>
    <p class="lede">Two or three sentences stating the idea.</p>
    <p class="kicker">One sentence connecting it to the learning portal.</p>
    <div class="toc-mini" aria-label="On this page">
      <a href="#one">First section</a>
      <a href="#two">Second section</a>
    </div>
  </section>

  <section id="one">
    <h2>First section</h2>
    <div class="prose"><p>Prose that teaches the point without the interactive.</p></div>

    <figure class="fig" aria-labelledby="figTitle">
      <h4 id="figTitle" style="font-family:var(--sans);font-size:.8rem;letter-spacing:.16em;text-transform:uppercase;color:var(--cream-dim);margin:0 0 1rem">Interactive &middot; select one</h4>
      <div class="controls">
        <div class="solid-select" id="sel" role="group" aria-label="Option">
          <button type="button" data-k="a" data-c="elixir" class="active">option a</button>
          <button type="button" data-k="b" data-c="blue">option b</button>
        </div>
      </div>
      <svg viewBox="0 0 720 120" role="img" aria-label="Describe what the figure shows.">
        <rect id="box" x="20" y="40" width="200" height="44" rx="11" fill="#10162b" stroke="#2a3252" stroke-width="2"></rect>
        <text id="boxT" x="120" y="68" text-anchor="middle" font-family="JetBrains Mono, monospace" font-size="13" fill="#cdb8f0">a</text>
      </svg>
      <div class="geo-readout" id="out" aria-live="polite"></div>
    </figure>
    <p class="take">One sentence naming the lesson.</p>
  </section>

  <section id="two">
    <h2>Second section</h2>
    <div class="prose"><p>More prose.</p></div>
    <pre class="code"><span class="cmt"># a short, real example</span>
result = <span class="fn elixir">Module</span>.<span class="fn">function</span>(arg)</pre>
    <div class="bridge">
      <div class="cell idea"><p class="lbl">The idea</p><p>Stated plainly.</p></div>
      <div class="arrow" aria-hidden="true">&rarr;</div>
      <div class="cell elix"><p class="lbl">In Elixir</p><p>The concrete form.</p></div>
    </div>
    <p class="note">Next: <a href="/elixir/CHAPTER/NEXT"><strong>the next module</strong></a>.</p>
  </section>

  <section>
    <nav class="pager" aria-label="Lesson navigation">
      <a class="btn ghost" href="/elixir/CHAPTER/PREV"><span aria-hidden="true">&larr;</span>&nbsp; previous</a>
      <span class="spacer"></span>
      <a class="btn" href="/elixir/CHAPTER/NEXT">Next <span aria-hidden="true">&rarr;</span></a>
    </nav>
  </section>
</main>

<footer class="site-foot">
  <div class="wrap">
    <p class="colophon">Built with the jonnify dark-editorial design system. Every page carries a branded
      <b>Snowflake</b> build stamp &mdash; a namespaced, base62-encoded id that decodes to a millisecond timestamp.</p>
    <div class="stamp" id="stamp" role="button" tabindex="0" aria-expanded="false" aria-label="Build stamp — activate to decode">
      build <span class="id" id="stampId">{{BUILD_ID}}</span>
      <dl class="panel">
        <dt>namespace</dt><dd id="st-ns">&mdash;</dd>
        <dt>snowflake</dt><dd id="st-snow">&mdash;</dd>
        <dt>node</dt><dd id="st-node">&mdash;</dd>
        <dt>seq</dt><dd id="st-seq">&mdash;</dd>
        <dt>timestamp</dt><dd id="st-ts">{{BUILD_TS}}</dd>
      </dl>
    </div>
  </div>
</footer>

<script>
(function () {
  "use strict";
  // --- interactive ---
  var DATA = { a: 'a', b: 'b' };
  function pick(k) {
    document.querySelectorAll('#sel button').forEach(function (b) {
      var on = b.getAttribute('data-k') === k; b.classList.toggle('active', on); b.setAttribute('aria-pressed', on ? 'true' : 'false');
    });
    var t = document.getElementById('boxT'); if (t) t.textContent = DATA[k];
    var out = document.getElementById('out'); if (out) out.textContent = 'Selected ' + k + '.';
  }
  document.querySelectorAll('#sel button').forEach(function (b) { b.addEventListener('click', function () { pick(b.getAttribute('data-k')); }); });
  pick('a');

  // --- Branded Snowflake decoder (verbatim, every page) ---
  var B62 = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
  var EPOCH_MS = 1704067200000;
  function b62decode(s) { var n = 0n; for (var i = 0; i < s.length; i++) { var d = B62.indexOf(s.charAt(i)); if (d < 0) return null; n = n * 62n + BigInt(d); } return n; }
  function pad2(x) { return (x < 10 ? '0' : '') + x; }
  function decodeBranded(id) {
    if (!id || id.length < 4) return null;
    var ns = id.slice(0, 3), snow = b62decode(id.slice(3));
    if (snow === null) return null;
    var ts = snow >> 22n, node = (snow >> 12n) & 0x3FFn, seq = snow & 0xFFFn;
    var d = new Date(Number(ts) + EPOCH_MS);
    var tstr = d.getUTCFullYear() + '-' + pad2(d.getUTCMonth() + 1) + '-' + pad2(d.getUTCDate()) + ' ' + pad2(d.getUTCHours()) + ':' + pad2(d.getUTCMinutes()) + ':' + pad2(d.getUTCSeconds()) + ' UTC';
    return { ns: ns, snow: snow.toString(), node: node.toString(), seq: seq.toString(), ts: tstr };
  }
  var stamp = document.getElementById('stamp'), idEl = document.getElementById('stampId');
  if (stamp && idEl) {
    var info = decodeBranded(idEl.textContent.trim());
    if (info) { var put = function (id, t) { var el = document.getElementById(id); if (el) el.textContent = t; };
      put('st-ns', info.ns); put('st-snow', info.snow); put('st-node', info.node); put('st-seq', info.seq); put('st-ts', info.ts); }
    var toggle = function () { var open = stamp.classList.toggle('open'); stamp.setAttribute('aria-expanded', open ? 'true' : 'false'); };
    stamp.addEventListener('click', toggle);
    stamp.addEventListener('keydown', function (ev) { if (ev.key === 'Enter' || ev.key === ' ' || ev.key === 'Spacebar') { ev.preventDefault(); toggle(); } });
  }
})();
</script>
```

## Appendix B — validator suite block

Append one block per new page to `validator/suite.elixir.js`, tagged so `ONLY` can target the
module. Pass assertions that mirror what a screenshot would have confirmed.

```js
// ── Fn.NN · page label ──
await block(v, 'Fn.NN /OUTPUT.html', async () => {
  await v.open('/OUTPUT.html');
  await v.base('Title substring');                 // title, svg, decoded stamp, no overflow, no console errors
  await v.expectText('#readout', 'default text');  // initial state
  await v.click('#sel button[data-k="b"]'); await v.settle(150);
  await v.expectText('#boxT', 'b');                 // interaction changed the figure
  await v.expectAttr('#box', 'stroke', '#cdb8f0');  // and its attribute
});
// add the page to the mobile sweep with the same tag:
//   for (const p of ['/OUTPUT.html']) await block(m, 'Fn.NN ' + p + ' (mobile)', async () => {
//     await m.open(p); await m.noHorizontalOverflow(); await m.noConsoleErrors(); });
```

Then:

```bash
BASE_URL="file:///home/claude/elixir-course" ONLY="Fn.NN" node validator/suite.elixir.js
```

## Appendix C — command cheat-sheet

```bash
# voice sweep (read the output; silence means clean)
grep -nE '\bjust\b|\bsimply\b|\bobviously\b|\beffortless\b|\bmagical\b|\brevolutionary\b|\bblazing\b' content/FRAG.html

# build one page; build everything
python3 build_page.py build --page KEY
python3 build_page.py build --all

# gates on a built file
python3 build_page.py check OUTPUT.html

# routes and manifest
python3 build_page.py routes
python3 build_page.py manifest

# branded ids
python3 build_page.py id mint
python3 build_page.py id decode TSK0KHTOWnGLuC

# after editing HEAD_CSS, refresh the cached head, then rebuild
python3 build_page.py extract-head && python3 build_page.py build --all

# headless validation, zero images
BASE_URL="file:///home/claude/elixir-course" node validator/suite.elixir.js
BASE_URL="file:///home/claude/elixir-course" ONLY="enum-streams" node validator/suite.elixir.js
```

## Appendix D — verified facts the course rests on

These were researched and confirmed; use them rather than recalling.

**Elixir.** Created by José Valim. First commit January 2011; 1.0.0 in September 2014; roughly
six-month minor releases. The compile pipeline: source is tokenised, parsed to quoted AST (the
three-tuple `{form, meta, args}`, so `1 + 2` is `{:+, [], [1, 2]}`), macro-expanded, lowered to
Erlang Abstract Format, then compiled to BEAM bytecode. Dynamic and strongly typed; Apache 2.0.

**language-ext.** Paul Louth's pure-functional framework for C# (`github.com/louthy/language-ext`):
`Option<T>`, `Either<L,R>`, `Validation`, immutable collections, an `IO<A>` monad in v5, and the
`echo-process` actor library where an actor is `State -> Message -> State`. It is the strongest
bridge for C# developers: `Option` maps to a matched value-or-nil, `Either` to `{:ok, _} | {:error,
_}`, the actor model to a `GenServer`.

**BEAM versus the CLR.** The BEAM runs millions of lightweight processes with per-process heaps and
per-process garbage collection (no global stop-the-world), message passing by copy, "let it crash"
with supervision, and hot upgrades. The CLR runs threads and tasks over a shared heap with
generational GC, exceptions and try/catch, assemblies and JIT or NativeAOT, and a large class
library over static nominal types.
