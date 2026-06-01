---
name: elixir-course
description: "Use this skill to author or continue the technical course 'Functional Programming in Elixir' on the jonnify dark-editorial design system (published at https://jonnify.fly.dev/elixir). Triggers: any request to create, continue, extend, relink, or validate a course page, module, hub, subpage, or lab in this course; to build or check pages with build_page.py; to run the Apollo A+ quality gates; to mint or decode branded Snowflake IDs (TSK… form); or to run the headless zero-screenshot validator. The deliverable is always self-contained static HTML graded A+ across nine gates, authored into the existing builder and design system — never a rebuild of the system. Do NOT use for unrelated Elixir coding, generic Word/PDF/PPTX/XLSX documents, or courses on a different design system."
---

# Authoring the "Functional Programming in Elixir" course

This skill continues a long-running course. **`build_page.py` is the single source of truth** for the
manifest, the nine gates, the routes, and the ID tools; **`course-authoring-playbook.md`** is the full
reasoning and workflow. Where this skill and the code disagree, re-read the code — it wins.

## 0. Two standing rules

1. **Reuse, do not reinvent.** The design system, the builder, the ID convention, and the validator
   exist and are proven. Author content *into* them.
2. **Validate without images.** Validation is headless and text-only. Never screenshot, never open a
   PNG — the image budget is a hard, shared constraint across a session.

## 1. Where to work

Work in `/home/claude/elixir-course/`. Layout that matters:

| Path | Role |
|---|---|
| `build_page.py` | Source of truth: manifest, assembler, nine gates, ID tools, CLI (stdlib only). |
| `content/` | Hand-authored page fragments — one per page. |
| `*.html` (root) | Built pages, written flat by the builder; these render in the client. |
| `_head.html` | Cached `<head>` injected into every page. Regenerate from `HEAD_CSS` with `extract-head`. |
| `validator/` | Headless zero-screenshot validation harness (`validator.js`, `suite.elixir.js`, `visual.js`). |
| `functional-programming-in-elixir.md` + `_gen_course_md.py` | Course outline + its generator. |
| `elixir-references.md` + `_gen_refs_md.py` | Curated references + its generator. |
| `course-authoring-playbook.md` | The complete brief (read it for anything not covered here). |

Final deliverables are copied to `/mnt/user-data/outputs/` and surfaced with `present_files`.

## 2. The product and the running project

A course is interconnected **static HTML** pages: no framework, no runtime, no CDN, no browser storage.
Each page = a shared head + one hand-authored fragment + one inline `<script>` + one or more inline SVG /
HTML interactives. Scope is **six numbered chapters, fifty-four modules, plus an optional history chapter**
(say exactly that; `module_count()` returns 54).

A single real-world project threads through every example so they accumulate instead of resetting: the
reader is building **the learning portal they are reading on** — magic-link auth, progress tracking, later
Phoenix LiveView and telemetry. Reuse this domain; do not invent new ones.

| Context | Functions | Sample entity |
|---|---|---|
| `Portal.Accounts` | `get_user/1`, `get_user_by_email/1`, `register/1` | `%User{id: "USR0NbAb1xcFCy", email: "ada@portal.dev"}` |
| `Portal.Auth` | `request_link/1`, `verify/1`, `start_session/1`, `current_user/1` | `%Session{id: "SES0NbAb29FnXc"}` |
| `Portal.Catalog` | `list_courses/0`, `list_lessons/1`, `get_lesson/1` | `%Lesson{id: "LSN0NbAb2Lk9GS"}` |
| `Portal.Progress` | `complete/2`, `completed?/2`, `progress_for/1`, `percent_complete/1` | progress records keyed by user + lesson |

## 3. The non-negotiables (a page is not done until all hold)

- **A+ on all nine Apollo gates.** No partial grades ship.
- **Voice.** Visible prose never contains: *revolutionary, blazing-fast, magical, simply, just, obviously,
  effortless*. No exclamation marks, no emoji. Run the voice sweep and **read its output**.
- **Accessibility + degradation.** Static content is present and readable with JS disabled; interactives
  enhance but are not required. All animation respects `prefers-reduced-motion`. Every interactive has an
  accessible label.
- **No browser storage.** No `localStorage` / `sessionStorage`. State lives in the DOM and JS variables.
- **No external dependencies in pages.** Vanilla JS only.
- **Branded Snowflake build stamp.** Every page carries the footer stamp + decoder (Appendix A of the playbook,
  copied verbatim).

## 4. The design system (jonnify dark-editorial)

Quiet editorial dark theme: deep ink backgrounds, warm cream text, one accent family per chapter, serif
display over a sans body scale. All colours are CSS custom properties in `HEAD_CSS` (~15.7 KB).

| Token | Value | Use |
|---|---|---|
| `--ink` / `--ink-2` / `--ink-3` | `#0a0e1a` / `#10162b` / `#161d38` | page, panel, raised panel |
| `--cream` / `--cream-soft` / `--cream-dim` | `#ece4d0` / `#d7cfb9` / `#a39c89` | body, secondary, muted |
| `--gold` / `--gold-bright` | `#d4a85a` / `#f0cd7f` | F1 accent; literals & atoms in code |
| `--blue` / `--blue-bright` | `#5a87c4` / `#9fc0ea` | F0 and F6 accent |
| `--sage` / `--sage-bright` | `#7ba387` / `#a7c9b1` | F4 and F5 accent; strings in code |
| `--elixir` / `--elixir-bright` | `#b39ddb` / `#cdb8f0` | F2 and F3 accent; keywords & module names |
| `--burgundy` (text `#e08f8b`) | `#c4504c` | warnings, the "not yet" state |
| `--line` | `#2a3252` | hairlines, inactive strokes |

Fonts: `--serif-display` Cormorant Garamond (headings), `--serif` PT Serif (prose), `--sans` Manrope
(labels/UI), `--mono` JetBrains Mono (code/readouts). Mobile breakpoint `@760px`.

## 5. Page anatomy (every fragment, in order)

1. A skip link, then the site `<header>` with brand + nav carrying a `.route-tag` with this page's route.
2. A `.hero`: `.crumbs`, an `.eyebrow` (chapter + position), an `<h1>` with the accent word in `<span class="ex">`,
   a `.lede`, a `.kicker`, a `.toc-mini`.
3. One or more `<section>`s. A teaching section pairs `.prose` with a `.fig` (the interactive), a `pre.code`
   block where relevant, a `.geo-readout` live region, and a closing `.take` (one-sentence takeaway). Concept
   pairings use `.bridge` (`.cell.idea` → `.arrow` → `.cell.elix`). A `.note` carries the forward pointer.
4. A `.pager` (`.btn.ghost` back, `.btn` forward, `.spacer`).
5. The site footer with `.stamp` + decoder script.

Code-token spans (there is **no `.kw`** class — keywords use `.op`):
`.op` keywords/operators · `.fn` function names · `.fn.blue|.sage|.gold|.elixir` module names by family ·
`.res` literals/atoms · `.cmt` comments · `.str` strings.

**Escape gotcha:** `create_file` does not interpret escapes, so a literal `\u2014` inside HTML appears
verbatim — use `&mdash;` or a real `—`. The same escape inside a JS string literal *is* interpreted, so
those are fine.

## 6. The interactive contract

Each page carries ≥1 interactive. Every one must: be inline SVG or inline HTML driven by vanilla JS;
**perform the real operation** and show its actual result (not a canned animation); expose a live
`.geo-readout` (`aria-live`); carry a one-sentence `.take`; **degrade** (controls + SVG present in static
markup, JS populates state); respect `prefers-reduced-motion`; never use browser storage. Compute the
displayed result from a fixed dataset with small pure functions so the readout is always truthful.

## 7. The nine Apollo gates

`containers` (balanced structural tags) · `svg` (≥1 well-formed) · `no-future` (no `/future` links) ·
`voice` (no forbidden words in visible prose) · `storage` (no web storage) · `motion`
(`prefers-reduced-motion` honoured) · `degrade` (static content visible without JS) · `links` (every
internal href ∈ `allowed_routes()`) · `pager` (well-formed pager present). `python3 build_page.py check
FILE.html` prints the per-gate result; ship only at **A+**.

## 8. Branded Snowflake IDs

Integer Snowflakes with a namespaced base62 string form: 3-letter uppercase namespace + base62(snowflake)
left-padded to 11 = 14 chars. Epoch `1704067200000` (2024-01-01 UTC); layout `ts(41)<<22 | node(10)<<12 |
seq(12)`. Verified: `TSK0KHTOWnGLuC` ⇄ `274557032793636864` ⇄ `2026-01-27 15:11:37 UTC`. Use `id mint` /
`id decode`. Every page's footer decoder fills `#st-ns`, `#st-snow`, `#st-node`, `#st-seq`, `#st-ts`; a
broken stamp fails validation (the validator asserts namespace `TSK` + numeric snowflake).

## 9. The CLI

```
python3 build_page.py build --page KEY     # assemble one page, run gates, write the file
python3 build_page.py build --all          # build every registered page
python3 build_page.py check FILE.html      # run the nine gates, print the grade
python3 build_page.py manifest             # print the chapter/module manifest
python3 build_page.py routes               # print every allowed route
python3 build_page.py id mint              # mint a branded Snowflake id
python3 build_page.py id decode ID         # decode a branded id
python3 build_page.py extract-head         # rewrite _head.html from HEAD_CSS (after HEAD_CSS edits)
```

**Build-order gotcha:** `_assemble()` reads `_head.html`, not the live `HEAD_CSS`. After any `HEAD_CSS`
edit, run `extract-head` then rebuild, or the CSS change will not appear.

## 10. The authoring workflow (run for every new module)

1. **Author the fragment(s)** in `content/` — hub + subpages for a module with deep dives.
2. **Promote** the module to `status="built"` in `MODULES`.
3. **Register subpages** in `SUBPAGES[module_id]` (or `CHAPTER_SUBPAGES[chapter_id]` for front-matter).
4. **Register pages** in `PAGES` — hub key + one key per subpage, each with a **unique output filename**.
5. **Relink the previous module** — update its `.note` and pager forward; drop any "in production" wording.
6. **Light up the chapter landing** — flip the new module's journey-node stroke `#2a3252` → `#cdb8f0`, add
   its route + "available now" to the landing's `MODS` JS object, turn the directory entry into a link.
7. **Verify routes** with a short Python check against `allowed_routes()`: new routes present, the next
   still-planned module absent.
8. **Validate with zero images**, in order:
   - Voice sweep (read it): `grep -nE '\bjust\b|\bsimply\b|\bobviously\b|\beffortless\b|\bmagical\b|\brevolutionary\b|\bblazing\b' content/FRAG.html`
   - Build: `python3 build_page.py build --page KEY` (+ rebuild relinked pages and the landing).
   - Gates: `python3 build_page.py check OUT.html` → expect A+ and nine passes.
   - JS: extract the longest `<script>` per page and run `node --check` on it.
   - Headless validator: append a tagged block to `validator/suite.elixir.js`, run with `ONLY=<tag>`.
9. **Deliver** with `present_files`, primary page first, then a brief summary.

> If the user re-sends an identical request mid-task, do not re-author — execute the remaining
> `present_files` and summary.

## 11. Headless validation

```bash
BASE_URL="file:///home/claude/elixir-course" node validator/suite.elixir.js
# scope to one module (small output):
BASE_URL="file:///home/claude/elixir-course" ONLY="enum-streams" node validator/suite.elixir.js
```

Playwright + chromium resolve in this environment without installation for the DOM checks. Each page block
opens the page, runs `base(...)` (title, ≥1 SVG, decoded stamp, no horizontal overflow, no console errors),
then exercises the interactive with `click` + `settle` + `expectText`/`expectAttr`. A mobile pass repeats
overflow + console checks at 390px. The suite exits non-zero on any failure. Append one tagged block per new
page (Appendix B of the playbook).

## 12. Documentation deliverables

Regenerate as modules build: `python3 _gen_course_md.py` (outline + Mermaid) and `python3 _gen_refs_md.py`
(references). Both run the voice gate on their output.

## 13. Course map and resume point

| Chapter | Title | Accent | Route | Status |
|---|---|---|---|---|
| F0 | History (also the contents page) | blue | `/elixir/course` | live |
| F1 | Algebra | gold | `/elixir/algebra` | live |
| F2 | Functional Programming | elixir | `/elixir/functional` | live |
| F3 | The Elixir Language | elixir | `/elixir/language` | live |
| F4 | Algorithms & Data Structures | sage | `/elixir/algorithms` | planned |
| F5 | Pragmatic Programming | sage | `/elixir/pragmatic` | planned |
| F6 | Phoenix Framework | blue | `/elixir/phoenix` | planned |

**Resume at F3.05, Structs.** Thread the running project: the maps `Enum`/`Stream` walked in F3.04 gain a
name and a shape — a struct. Likely subpages: defining a struct over a Portal entity; enforcing keys and
defaults; pattern-matching on a struct's type. Then `protocols` (the Enumerable protocol from F3.04 pays
off), `processes`, `otp`, and the `playground` lab. F6 adds Phoenix LiveView; F5 adds telemetry.

See `course-authoring-playbook.md` Appendices A–D for the fragment skeleton, the validator block template,
the command cheat-sheet, and the verified facts the course rests on.
