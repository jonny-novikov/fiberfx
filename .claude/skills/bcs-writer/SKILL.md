---
name: bcs-writer
description: Author and revise articles in the Branded Component System (BCS) series and the echo_data measured-article docs to the established A+ quality gates. Use this skill whenever the user asks to write, continue, extend, review, or fix a BCS article or chapter (bcsN.md), the preface, TOC, or roadmap, or asks for a "comprehensive article" on any architecture, storage, queueing, or ID topic in this project — even when the word BCS is absent. Also use it for series restructures, supersession amendments, and figure or voice audits of existing articles. It enforces the voice gates, NO-INVENT grounding, search-verified references, derivation-before-measurement benchmarking, figure cross-checks against committed outputs, and the ship loop (sweep, TOC update, archive refresh, present).
---

# BCS Writer

Authors two families to the same bar — measured, grounded, voice-gated. The **manuscript** is the measured article series (`bcsN.md`); the **course** is the served HTML at `/bcs` that teaches it. Both ground every claim in the committed tree and ship through a gate. The sections below cover the manuscript loop, then course authoring; the grounding law is shared and absolute.

## Step 0 — Orient before writing a word

1. Read `docs/bcs/bcs.toc.md` in the project tree. Two things live there: the chapter's scope row, and the **Standing decisions** section — read both. Standing decisions supersede everything, including examples in this skill (precedent: the storage target changed mid-series; the TOC amendment was the record).
2. Read `docs/bcs/bcs.preface.md` once per session for the thesis and voice register.
3. If the article touches the identity contract, ground in `contract/contract.md` and `contract/vectors.json` — never restate the contract from memory.

## The authoring loop

1. **Ground (NO-INVENT).** Every module, file, chapter, rung, and figure named must exist in the tree, an upload, or a committed output. Future surfaces are written "this chapter builds". Read `references/conventions.md` for the full grounding and linking rules.
2. **Verify externals.** Every claim about software, history, or design that did not originate in this project gets a web_search or web_fetch hit in the current session before it is written, and a numbered reference. Primary sources over aggregators. No verified URL, no claim.
3. **Measure before writing.** If the article makes performance or size claims: probe the environment, build what is needed, run the benchmark, and commit the `.out` files first. Record versions and allocators in the `.out` header. Derive what the design predicts before showing what it measured.
4. **Author.** Start from `references/article-template.md`. Writerside markdown, `# BCS · Title`, `<show-structure depth="2"/>`, prose-led, measured tables verbatim in fenced blocks, quotes under 15 words and one per source.
5. **Gate.** Run the sweep and do not ship a failure:

   ```bash
   python3 scripts/sweep.py path/to/article.md \
     --figures "65,23,40960" --outs path/a.out,path/b.out
   ```

   It checks the forbidden-voice list, exclamation marks, reference bijection (every `[n]` cited has a listed `n.` and vice versa), relative-link resolution, quote length, and — with `--figures` — that every quoted number exists verbatim in the committed outputs.
6. **Integrate and ship.** Flip the chapter's TOC status to live and link the file; record any supersession as an inline TOC amendment naming what it replaces; refresh the production archive with the exclusion list in `references/conventions.md`; copy deliverables to `/mnt/user-data/outputs/`; `present_files` with the article first, evidence files after.

## Course authoring (the served `/bcs` pages)

The course is HTML pages on the **BCS contract sheet** (`references/sheet.css`: light engineering-document, monospace-forward, the 3/11 id palette — the dark-editorial sibling courses are out of bounds). Build them with the toolkit, never by hand:

```python
import sys; sys.path.insert(0, "scripts")
import build_course as bc          # owns the sheet, the shell, the doors, slug routes
# ... define the page's hero, interactive figure, body, refs, pager ...
open(out, "w").write(bc.page(...))  # one self-contained file
```

Then gate it and do not ship a failure:

```bash
python3 scripts/course_lint.py page.html --repo /path/to/repo
```

**Four laws the toolkit and the lint enforce — memorize them, because the last build broke all but one:**

1. **Structure.** A **Chapter** (`B[N]`, landing at `/bcs/<chapter>`) holds **6 Modules** (`B[N].[M]`, hub at `/bcs/<chapter>/<module>`); each **Module** holds **3 Dives** (`/bcs/<chapter>/<module>/<dive>`). It is never "a chapter of dives." A chapter landing maps its six modules; a module hub maps its three dives.
2. **Slug routes.** Every internal link is a semantic slug — `/bcs/ideas/identity-contract`, never `/bcs.1.2`, `bcs.1.2.html`, or a numeric segment. The file on disk may be `bcs.1.2.html`; the `href` it emits is the slug. Use `bc.route(chapter, module, dive)`.
3. **One interactive figure per page**, the `.anat` pattern (`g[data-seg]` + `.segbar` + `.readout`, pure lookup, degrades with script off). Use `bc.figure(...)`.
4. **Grounding is mechanical.** A number reaches a page only if it is verifiable in the committed repo: a real `.out` file, or source that asserts it (the `self_check!` contract vectors in `branded_id.ex` — `placement(USR0KHTOWnGLuC)` is `234878118`, the parse and decode vectors). **A benchmark with no committed `.out` is forbidden** — the snapshot has none, so `bench/branding-vs-decimal` and `bench/valkey-id` numbers (the encode ratios, the byte-per-key rows, the stream-entry rows) do not appear. There are **no gate-dump blocks** (`PASS n/n`, `G1 … ok` ladders) — describe the idea and, when a number is grounded, show it in a captioned `.frozen` block whose cited path resolves. `bc.cite_guard(numbers, repo)` raises on a thin figure before render.

The three doors are `/echomq`, `/redis-patterns`, `/echo-persistence` (the `/elixir` door is retired). The chapter map runs B0–B9 with the Persistence Floor at B5. Read `references/course.md` for the full course spec.

## Hard gates (memorize; the sweep enforces)

No: revolutionary, blazing, magical, simply, just, obviously, effortless, actually, genuinely, honestly, easy, seamless, powerful, honest/honesty. No exclamation marks. Losses recorded beside wins. Every figure traceable to a committed `.out` — on a course page, an ungrounded benchmark is dropped, not softened. Every reference verified this session. Links resolve or are prose; course links are slug routes.

## Bundled resources

- `references/conventions.md` — the complete gate set, measurement protocol, standing-decisions rule, and the ship-loop tail with the archive command.
- `references/article-template.md` — the manuscript section skeleton with inline guidance.
- `references/course.md` — the course spec: the chapter→6 modules→3 dives map, the slug scheme, the page shells, the interactive-figure pattern, and the grounding rule.
- `references/sheet.css` — the BCS contract sheet (the course design system, single source of truth).
- `scripts/sweep.py` — the manuscript gate; exit 0 is the only shippable state.
- `scripts/build_course.py` — the course toolkit: the sheet, the shell, slug routing, the interactive figure, the doors, and `cite_guard`.
- `scripts/course_lint.py` — the course gate: slug routes, one interactive figure, no gate dumps, the door, the no-thin-number grounding rule, tag balance.
