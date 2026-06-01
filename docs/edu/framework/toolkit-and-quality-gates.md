# Toolkit & Quality Gates

The machinery that turns the [principles](course-creation-principles.md) into shippable pages and keeps them at an A+ bar. The toolkit is a set of Python generators that emit self-contained static HTML, a Python math verifier, a preflight scanner, and a headless validator harness. Everything runs locally; the deliverables are the HTML files themselves.

## 1. Architecture at a glance

```text
style.py                 design system: palette, <head>, CSS, shared JS engines
build_home.py            the hub page
build_chapter_landing.py CHAPTERS = [ {chapter configs} ]
build_module.py          MODULES  = [ {module configs} ] + interactive HTML/JS constants
build_quiz.py            QUIZZES  = [ {chapter-quiz configs} ]   (reuses the shared engine)
build_final.py           finale landing + final test (isolated scoring engine)
verify_*.py              assert-based math checks — run BEFORE any page is coded
preflight.py             static scan of built HTML (KaTeX chars, nested <a>, structure)
validator/               headless Playwright harness + one suite per page family
docs/                    content map, status journal, progress tracker, design notes
```

> **Config-as-data.** Every page is a dictionary of fields; each generator is a pure mapping from that data to HTML. Authoring a page means adding a dictionary, not writing markup. This is what makes the catalog consistent and the gates meaningful.

## 2. The design system (`style.py`)

A single module owns the look and the shared behaviour, so every page across every course is cut from the same cloth.

- **`PALETTE`** — a map from slug to `(accent, bright, deep, "r,g,b")`. One entry per chapter plus a global default and a finale colour. `head()` injects the per-page accent as CSS variables, so a page's colour is entirely a function of its slug.
- **`head(title, desc, slug)`** — emits the `<head>`, meta description, fonts, the full stylesheet, and the per-page colour variables.
- **`FONTS`, `CSS`** — the typography and the component classes (below).
- **`NAV_JS`** — progress bar, scroll-spy section-nav, and "to top" behaviour, shared by every page.
- **`QUIZ_JS`** — the shared quiz engine used by modules and chapter quizzes (localStorage-backed, per-question reveal, score line, reset).

### 2.1 Component class catalogue

The CSS ships a fixed vocabulary so generators never hand-roll styles:

`calc-grid / calc-field / calc-btn / calc-result` (with `cr-big`, `cr-t`) · `seg` (with `on`) · `audit-list / audit-item / audit-btn / audit-result` (with `ar-count`, `ar-text`) · `formula-box` (with `fb-cap`) · `callout` (with `warn`) · `quiz / quiz-q / q-opt` (with `correct`, `incorrect`, `disabled`) · `quiz-foot / quiz-reset / quiz-score` · `ch-tile / ch-grid` · `nav-card` (with `prev`, `next`) · `to-top` · `safety-banner` · `section-nav` · `appl-table` · `takeaway-item` · `project-cta`.

> **Byte-stability rule.** Adding a `PALETTE` key, a new module config, or a new interactive constant must **not** change the rendered bytes of any existing page. Generators read their own slug/config; new data is inert to old pages. This rule is what makes the regression gate (§7) trustworthy.

## 3. The strict build cycle

Every iteration runs this sequence end to end. Nothing is delivered until every step is green.

```text
1. verify        python verify_*.py            # prove every displayed number
2. fill          edit generators               # add configs / interactives
3. build         python build_*.py             # emit HTML
4. preflight     python preflight.py <pages>    # static scan
5. validate      node validator/suite.*.js      # headless behavioural checks
6. regression    md5sum -c <snapshot>           # existing pages byte-identical?
7. docs          edit content map + journal     # status, newest-on-top
8. progress      rewrite progress tracker        # reader-facing snapshot
9. katex-scan    regex over docs                # no stray math chars
10. deliver      copy to outputs + present       # hand over the new pages
```

The ordering is deliberate: math is proven before any HTML exists, and regression is checked before the work is considered done.

## 4. Math verification (`verify_*.py`)

A flat list of assertions, one per figure the course will display, run before the page is coded.

```python
def check(name, got, exp):
    ok = abs(got - exp) <= abs(exp) * 1e-6 + 1e-9
    print(f"  [{'OK ' if ok else 'FAIL'}] {name:42s} got={got:.4g} exp={exp:.4g}")
    assert ok, name

# every number that will appear on a page gets a line:
check('Счёт 200 кВт·ч * 5 руб -> 1000', 200 * 5, 1000.0)
check('Перегруз 3000/230 -> 13.04 А',   3000 / 230, 13.0434783)
```

> **The figure on the page and the figure in the verifier are the same number.** A calculator's default output, a worked example, and a quiz answer are all proven here first. If the math changes, the verifier changes, and it fails loudly until the page agrees.

## 5. KaTeX strict-mode rules

Math is rendered by KaTeX in strict mode. The rules below are absolute and apply to every page and every doc.

> **Never put units, currency, or non-ASCII typographic characters inside `$...$` or `$$...$$`.** Units (В, А, Ом, Вт, кВт·ч, мА·ч, Гц, руб, проценты) and typographic glyphs are rendered as plain text *outside* the math delimiters.

Inside math, use Latin letters, digits, and LaTeX commands only:

```text
allowed in math : \cdot \frac \sum \eta \to \pm \le \ge \approx \%
                  \text{ascii-only}   ASCII subscripts like _1 or _{\text{nom}}
plain text only : В А Ом Вт руб %  and every glyph in the forbidden set below
```

The forbidden set (never inside math delimiters):

```text
№  ₽  «  »  “  ”  „  …  •  —  –  ·  ×  ÷  ≤  ≥  ≠
```

Two language-specific traps:

- **Double-backslash in Python dict strings.** A formula written in a Python string needs `\\frac`, `\\cdot`, `\\pm`, `\\%` — the single backslash is consumed by Python before KaTeX sees it.
- **Result strings carry no math.** A calculator's output string uses no `$` and localises decimals with a comma (`'…' + x.toFixed(2).replace('.', ',')`).

### 5.1 The pre-delivery scan

Before any page or touched doc is delivered, a regex sweeps for math spans containing a forbidden character:

```python
import re
BAD = set('№₽«»“”„…•—–·×÷≤≥≠')
hits = [m.group(0) for m in re.finditer(r'\$[^$\n]+?\$', text)
        if any(c in BAD for c in m.group(0))]
assert not hits, hits
```

A clean sweep is a release gate, not a suggestion.

## 6. Preflight scanner (`preflight.py`)

A fast static pass over the *built* HTML that flags three classes of defect:

1. **Forbidden KaTeX characters inside `$...$`** (the §5 set) — and only inside math; the same glyphs are fine in prose.
2. **Nested anchors** (`<a>` inside `<a>`) — invalid HTML that browsers "repair" by doubling the DOM.
3. **Structural sanity** — the presence of the expected `<body>` / `<footer>` scaffolding.

Preflight runs on every page, every iteration, and must report zero problems.

## 7. The validator harness (Playwright, zero-image budget)

A headless browser opens each page and asserts its behaviour. The harness exposes a small, composable API:

`open · title · noKatexErrors · noHorizontalOverflow · expectCount(sel, op, n) · expectText(sel, text) · expectVisible · fill · click · computedStyle · expectStyle · settle · expectStored`

> **Zero-image budget.** The validator asserts that **no** images are embedded or requested. Checks read the DOM and computed styles — never screenshots. This keeps pages fast and the gate objective.

### 7.1 The per-module assertion template

Every module is checked against the same contract, which is exactly the 4 + 1 + 5 rule made executable:

```text
.progress-bar            == 1
.section-nav a           == 4        # four scroll-spy links
.sect[id]                == 4        # four anchored sections
.takeaway-item           == 4
.task-block              == 1        # exactly one interactive
.quiz-q                  == 5        # five questions
.q-opt                   == 20       # five questions x four options
.safety-banner           visible
.to-top                  visible
.nav-card                == 2        # prev + next
.nav-card.prev[href=…]   == 1        # correct chain links
.nav-card.next[href=…]   == 1
.brand-sub               ~ "Глава N" # correct chapter label
.breadcrumb .current     ~ "N.M"     # correct module number
+ per-interactive checks (default state, a click, the result string)
+ first-quiz-answer (click option 0 -> score "1 / 5", explanation visible)
```

### 7.2 Suite organisation

Suites mirror the page families: `home`, `landings`, `modules` (sample), `sample`, `quizzes`, one per chapter (`ch2`, `ch3`, …), and `final`. Each suite reports `PASS / FAIL` and the embedded-image count. The release bar is the whole battery green with zero images and zero failures.

## 8. Regression discipline (`md5sum`)

The byte-identical guarantee is enforced mechanically:

```bash
md5sum $(find site -name '*.html' | sort) > /tmp/pre.txt   # snapshot before
# … rebuild …
md5sum -c /tmp/pre.txt | grep -v ': OK'                    # what changed?
```

> **An unexpected diff is a bug; an expected one is named.** Adding a chapter or rewiring navigation legitimately changes a few pages — confirm those are *exactly* the pages you intended and that everything else is untouched. Pure additions (a new palette key, a new module) must change nothing pre-existing.

## 9. Non-negotiable invariants

The checklist every page satisfies, enforced by the gates above:

- Root-relative links; no nested anchors.
- localStorage keys are course-prefixed (no cross-course collisions).
- Zero images; the page is fully self-contained.
- Every page has: progress bar, four-link scroll-spy section-nav (readings), previous/next cards, "to top", breadcrumb, safety banner.
- Every displayed number is verified in code.
- All math is KaTeX-strict-clean (the §5 scan passes).

## 10. Hard-won pitfalls

Mistakes that have actually bitten, and how the toolkit guards against them:

> **The `def build` clip.** When shrinking a `MODULES = [...]` or `QUIZZES = [...]` block by string replacement, it is easy to clip the `def build(...)` that follows it. Re-insert it, and prefer exact-string edits over regex.

> **Identical "next" lines.** Two chapters can have byte-identical `nxt=(…)` lines; a unique string replace needs the preceding line for context, or it fails as ambiguous.

> **Nested-anchor doubling.** A card that contains an inner link must use a `div` as its outer element, not an `<a>` — otherwise the browser's adoption-agency algorithm doubles the node and the validator's counts go wrong.

> **localStorage collisions.** Two courses on one origin will overwrite each other's progress unless every key is course-prefixed. (See principles §9.)

> **Fragile generator splicing.** When porting a generator between courses, replace exact strings rather than regex patterns — a partial substitution can leave stale, course-specific text behind.
