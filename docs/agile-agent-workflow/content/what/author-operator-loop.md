# A0.2.3 — The Author/Operator loop

- **Route:** `/course/agile-agent-workflow/what/author-operator-loop`
- **File:** `html/agile-agent-workflow/what/author-operator-loop.html`
- **Place in the module:** the third design of A0.2 ("What we are building") — the framework's *motion*: the loop
  between the two roles, and the spec where they meet. This is the CANONICAL page that A1.03 grounds its roles in.
- **Accent word (`.ex`):** "loop".

## Lead

The framework moves as a loop between two roles. The **Operator** — the human — sharpens, reviews, and accepts; the
**Author** — the Claude agent — specifies, builds, and ships. One thin rung at a time, and feedback edits the spec.
Select a role to see which stages it drives.

(Page eyebrow: "A0.2 · framework · design 3". Meta description: "The framework's motion: a loop between two
roles — the Operator (human) who sharpens, reviews, and accepts, and the Author (Claude agent) who specifies,
builds, and ships — meeting on the spec, with feedback editing it each turn.")

## Definition (the two roles + the loop, verbatim canon)

These are the course's canonical role definitions — extracted verbatim from the page's `#roles` prose and `.deflist`.

From the prose:

- The **Operator** is the human: the source of intent, decomposition, and judgement. They decide what the next thin
  rung should be, demo and review what comes back, and accept it or send it round again. The Operator never writes
  the code — their scarce, valuable attention goes to deciding what matters and whether it was met.
- The **Author** is the Claude agent: the source of production. It turns a sharpened rung into a spec, derives the
  stories and the agent brief, builds the increment, and ships it — fast, exact, and tireless. The Author has no
  taste for what matters, so it never sets the goal; given a clear spec, it does the work a person would find slow
  and repetitive.
- Run alone, each role fails: an Operator without an Author ships nothing, and an Author without an Operator ships
  the wrong thing, confidently. Paired over thin, provable rungs they compound — the human's judgement at the start
  and end of every rung, the agent's throughput in the middle.

From the `.deflist` (verbatim `dt`/`dd`):

- **Operator (human)** — Intent, decomposition, judgement, acceptance. Sharpens the next rung; demos, reviews, and
  signs off. Writes no code.
- **Author (agent)** — Production. Drafts the spec, derives the stories and brief, builds, and ships — thin but
  robust. Decides no goals.
- **The pairing** — Neither ships reliable software alone. Judgement at the ends of each rung; throughput in the
  middle.

The loop's six stages (from the hero SVG, each with its one-line gloss and owning role):

1. **sharpen** — state intent · agree the spec — *operator*
2. **build** — implement from spec + brief — *author*
3. **ship** — thin but robust, behind the facade — *author*
4. **demo** — run it against the stories — *operator*
5. **review** — does it meet acceptance? — *operator*
6. **feedback** — capture what's missing — *operator*

A dashed arc returns from *feedback* back to *sharpen*, labelled "adapt · feedback edits the spec".

## Why it matters

Run alone, each role fails — the Operator ships nothing, the Author ships the wrong thing confidently. Paired over
thin, provable rungs they compound: the human's judgement at the start and end of every rung, the agent's
throughput in the middle. The discipline is one loop with a clean meeting point.

## Where the roles meet: the spec (`#meet`)

The two roles meet on one artifact: the **spec**. The Operator's sharpened intent becomes a spec; the Author builds
from that spec and nothing else; and when the increment is demoed and reviewed, feedback edits the spec — never the
code directly. The spec is the contract, and it is the only thing both sides commit to.

That single meeting point is what keeps the handoffs clean. *Sharpen* hands a settled spec from Operator to Author;
*ship* hands a running increment from Author back to Operator; and *adapt* routes every correction back through the
spec, so the next turn of the loop starts from one agreed truth. Select a side to see what it owns.

(No `pre.code` worked Portal example is present on this page — the page is design/conceptual, not code.)

## The two interactives (different teaching moves)

Both shells use `.solid-select` button groups, an inline `<svg>`, and a live `.geo-readout`. The readout strings
are computed by small pure functions that map a key to a fixed string/state — always truthful.

### Hero figure — "One rung · select a role" (the loop, by role)

- **Title:** `#lpTitle` = "One rung · select a role".
- **Control:** `.solid-select` `#lpSel`, `role="group"`, three buttons by `data-k`:
  - `data-k="all"` · `data-c="gold"` · class `active` — label "the loop"
  - `data-k="operator"` · `data-c="blue"` — label "operator"
  - `data-k="author"` · `data-c="elixir"` — label "author"
- **SVG node ids:** `#loopSharpen`, `#loopBuild`, `#loopShip`, `#loopDemo`, `#loopReview`, `#loopFeedback`; per-node
  role tags `#rtSharpen`/`#rtBuild`/`#rtShip`/`#rtDemo`/`#rtReview`/`#rtFeedback`.
- **Pure function:** `pick3(k)` — for `k === 'all'`, sets all Operator nodes (`OP_NODES`) bright at width 2.5 and all
  Author nodes (`AU_NODES`) bright at 2.5; for `'operator'`, Operator nodes bright at 3 and Author nodes DIM at 1.5;
  else (author) Author nodes bright at 3 and Operator nodes DIM at 1.5. Toggles `.active`/`aria-pressed` on the
  buttons and writes `OUT3[k]` into `#lpOut`. Helper `setNode(id, stroke, w)` sets `stroke`/`stroke-width`.
  - `OP_NODES = ['loopSharpen', 'loopDemo', 'loopReview', 'loopFeedback']`
  - `AU_NODES = ['loopBuild', 'loopShip']`
  - Colors: `OP_BASE = '#5a87c4'`, `OP_BRIGHT = '#9fc0ea'`, `AU_BASE = '#b39ddb'`, `AU_BRIGHT = '#cdb8f0'`,
    `DIM = '#3d4663'`.
- **Readout `#lpOut` (aria-live=polite), strings (`OUT3`):**
  - `all`: "One rung runs as a loop. The Operator (human) sharpens, demos, reviews, and gives feedback; the Author
    (agent) builds and ships. Feedback edits the spec, and the loop runs again." (also the static initial markup)
  - `operator`: "The Operator is the human: the source of intent, judgement, and acceptance. They sharpen the next
    rung, demo and review what returns, and decide whether it is done. They never write the code."
  - `author`: "The Author is the Claude agent: the source of production. It turns the sharpened rung into a spec,
    builds the increment from the spec and brief, and ships it — fast and exact. It never decides the goal."
- **Initial state:** `pick3('all')` on load.

### Content figure — "The handoff · select a side" (where the roles meet)

- **Title:** `#mtTitle` = "The handoff · select a side".
- **Control:** `.solid-select` `#mtSel`, `role="group"`, three buttons by `data-k`:
  - `data-k="operator"` · `data-c="blue"` · class `active` — label "operator"
  - `data-k="author"` · `data-c="elixir"` — label "author"
  - `data-k="spec"` · `data-c="gold"` — label "the spec"
- **SVG node ids:** `#opCol` (Operator column), `#auCol` (Author column), `#spMid` (the central "spec / the contract"
  node).
- **Pure function:** `pick4(k)` — sets `#opCol` to `OP_BRIGHT` width 3 when `k==='operator'` else `OP_BASE` width 2;
  `#auCol` to `AU_BRIGHT` width 3 when `k==='author'` else `AU_BASE` width 2; `#spMid` to `'#f0cd7f'` width 3 when
  `k==='spec'` else `'#d4a85a'` width 2. Toggles `.active`/`aria-pressed` on the buttons and writes `OUT4[k]` into
  `#mtOut`.
- **Readout `#mtOut` (aria-live=polite), strings (`OUT4`):**
  - `operator`: "The Operator (human) owns intent, decomposition, and acceptance. They sharpen the next rung and
    judge what returns — but never write the code." (also the static initial markup)
  - `author`: "The Author (Claude agent) owns production. It drafts the spec, derives the stories and brief, builds
    the increment, and ships it — fast and exact, but it never decides the goal."
  - `spec`: "The spec is the contract both roles meet on. The Operator's intent becomes a spec the Author builds
    from; neither side proceeds on anything else."
- **Initial state:** `pick4('operator')` on load.

## Bridge / recap / references

- **take (`.take` on `#meet`):** "Two roles, one contract, one loop: the human decides and accepts, the agent
  specifies and builds, and the spec is where they meet. That is the whole engine of the workflow."
- **Note on `.bridge`:** this page carries NO `.bridge` block (no `.cell.idea` → `.arrow` → `.cell.elix`). Flag as a
  deviation from the standard lesson anatomy — see Anomalies.

### References (`#refs`, verbatim)

Lead-in prose: "Primary sources for this design, and where it connects in the course."

**Sources:**

- Hunt, A. & Thomas, D. — *The Pragmatic Programmer* — tracer bullets and tight feedback.
- Beck, K. — *Extreme Programming Explained* — the planning/feedback loop and small releases.
- `llms.txt` — the convention for the agent brief the Author follows.

**Related in this course:**

- A1 · Why an agile agent workflow → `/course/agile-agent-workflow/why`
- A0.2.1 · The two-layer model → `/course/agile-agent-workflow/what/two-layer-model`
- A0.2.2 · The four artifacts → `/course/agile-agent-workflow/what/four-artifacts`

## Wiring

- **route-tag on page:** `/course/agile-agent-workflow/what/author-operator-loop`
- **Crumbs (`.crumbs`, hrefs as-found):**
  - `A0.2 · What we are building` → `/course/agile-agent-workflow/what`
  - sep `/`
  - here (`.here`, no link): `A0.2.3 · the Author/Operator loop`
- **toc-mini:** `#roles` ("The two roles"), `#meet` ("Where they meet"), `#refs` ("References").
- **Pager (`.pager`):**
  - prev (`.btn.ghost`): `A0.2.2 · the four artifacts` → `/course/agile-agent-workflow/what/four-artifacts`
  - next (`.btn`): `A0.2 · module overview` → `/course/agile-agent-workflow/what`
- **Header:** brand `jonnify` → `/elixir`; nav `Course` → `/course/agile-agent-workflow`.
- **Footer:** "Modules" col lists A1 (link → `/why`) + A2–A7 as static `.it` spans; "The course" col links
  Course home (`/course/agile-agent-workflow`), Module A1 overview (`/course/agile-agent-workflow/why`),
  Companion · Functional Programming (`/elixir/course`), jonnify home (`/elixir`).
- **Build stamp:** `#stampId` = `TSK0NgMcmHK5nU`; static timestamp shown `2026-06-03 16:41:40 UTC`.

## Anomalies / notes

- **No `.bridge` block.** The page closes `#meet` with a `.take` but has no principle→practice `.bridge` cell pair
  that the lesson anatomy describes. Recorded as-is.
- **No `pre.code` / no worked Portal code example.** This is a conceptual design page; there is no code block.
- **No `.note` forward-pointer block** (the standard `.note` blue-rule forward pointer is absent); forward motion is
  carried only by the pager (next → the A0.2 module overview) and the related-links list.
- The hero figure's static `#lpOut` markup already matches `OUT3.all`; the content figure's static `#mtOut` markup
  already matches `OUT4.operator` — so the page degrades correctly with JS off.
