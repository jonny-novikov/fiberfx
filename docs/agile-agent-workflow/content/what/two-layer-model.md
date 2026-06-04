# A0.2.1 — The two-layer model

- **Route:** `/course/agile-agent-workflow/what/two-layer-model`
- **File:** `html/agile-agent-workflow/what/two-layer-model.html`
- **Place in the module:** the first design page of the A0.2 framework module — the framework's structure: a
  roadmap layer that plans delivery over a spec layer that defines and proves each rung, both sitting on the
  framework-free domain core, and why the spec is the single source of truth.
- **Accent word (`.ex`):** "model".

## Lead

The framework has two layers, and keeping them apart is the whole discipline. A roadmap plans how a chapter's
rungs ship; a spec defines each rung and proves it. Both sit on the framework-free domain core. The spec is the
single source of truth, and only feedback edits it. Select a layer to see what it owns.

## Definition

From the `.deflist` in the "Roadmap over specs" section:

- **Roadmap layer** — Delivery: milestones, iterations, and the order of rungs. Lives in a `roadmap.md`.
  Re-planned freely; defines no behaviour.
- **Spec layer** — Definition and proof: the spec, its user stories, and the agent brief. The single source of
  truth; edited only by feedback.
- **Domain core** — The framework-free logic the rungs build, behind the Portal facade. Every surface above
  depends on it; it depends on nothing above.

## Why it matters

The two layers answer different questions. The roadmap layer answers *how we deliver*: it cuts a chapter's work
into thin, robust rungs and orders them so value lands early and often. The spec layer answers *what we build and
how we know it is right*: for each rung, a precise definition and the checks that prove it. Beneath both sits the
framework-free domain core the rungs accrete into, behind the Portal facade.

They change at different rates and for different reasons. A roadmap is re-planned often — priorities move, a rung
splits, an estimate slips — without touching a single definition of behaviour. A spec changes only when the
behaviour itself changes, and when it does, the roadmap re-plans around it. Conflating the two is how projects
drift: a plan that also defines behaviour cannot be reordered without fear, and a spec that also tracks the
schedule rots the moment the schedule moves.

One rule makes the two layers stable: the spec is the single source of truth, and only feedback edits it. The
roadmap plans the spec; the user stories and the agent brief are *derived* from it; and when a demo or a review
surfaces something, the change lands in the spec — never in a story or a brief on its own. Everything downstream
is regenerated from that one edit. This is what makes a rung *correct by definition*. Because the stories and the
brief are views of the spec, they cannot silently disagree with it; because feedback edits the spec rather than
the code, the definition and the implementation stay in step. The diagram shows the four relationships — plan,
derive, derive, and edit — that every rung runs through.

## Worked Portal example

No standalone worked Portal example block (no `pre.code`) is present on this page. The Portal is referenced only
through the "Domain core … behind the Portal facade" wording in the definition list and the SVG/readouts.

## The two interactives

### Hero figure — the two-layer stack (frames the idea)

- **Control:** `.solid-select` `#tlSel` with three buttons — `data-k="road"` (`data-c="blue"`), `data-k="spec"`
  (`data-c="gold"`, initial `class="active"`), `data-k="core"` (`data-c="sage"`).
- **SVG targets:** stacked rects `#tlRoad` (roadmap layer), `#tlSpec` (spec layer, marked "the single source of
  truth"), `#tlCore` (domain core). Readout live region `#tlOut` (`aria-live="polite"`).
- **Pure function:**
  ```js
  function pick1(k) {
    Object.keys(ID1).forEach(function (key) {
      var el = document.getElementById(ID1[key]); if (!el) return;
      var on = key === k;
      el.setAttribute('stroke', on ? L1[key].bright : L1[key].base);
      el.setAttribute('stroke-width', on ? '3' : '2');
    });
    document.querySelectorAll('#tlSel button').forEach(function (b) {
      var on = b.getAttribute('data-k') === k; b.classList.toggle('active', on); b.setAttribute('aria-pressed', on ? 'true' : 'false');
    });
    var o = document.getElementById('tlOut'); if (o) o.innerHTML = OUT1[k];
  }
  ```
  Fixed datasets: `L1` (per-key `{base, bright}` colours), `ID1 = { road: 'tlRoad', spec: 'tlSpec', core: 'tlCore' }`,
  `OUT1` (readout strings). Initial call: `pick1('spec')`.
- **Readout strings (`OUT1`):**
  - `road` — "The roadmap layer plans how a chapter's rungs ship — milestones, iterations, the Author/Operator loop. It points at the spec; it never defines behaviour."
  - `spec` — "The spec layer is the single source of truth: the spec, its user stories, and the agent brief. Feedback edits the spec — never the other way around." (also the static markup default in `#tlOut`)
  - `core` — "The domain core is framework-free and sits behind the Portal facade. Every layer above adds surface; none reaches into the core."

### Content figure — the four relationships (proves the consequence)

- **Control:** `.solid-select` `#ssSel` with three buttons — `data-k="plan"` (`data-c="blue"`, initial
  `class="active"`), `data-k="derive"` (`data-c="sage"`), `data-k="adapt"` (`data-c="gold"`).
- **SVG targets:** four connector lines `#arP` / `#arE` / `#arS` / `#arB`; four edge labels `#lbP` / `#lbE` /
  `#lbS` / `#lbB`; node rects `#ndRoad` (roadmap.md), `#ndFb` (feedback), `#ndSpec` (spec — single source of
  truth, centre), `#ndStory` (stories), `#ndBrief` (agent brief). Readout live region `#ssOut`
  (`aria-live="polite"`).
- **Pure function:**
  ```js
  function pick2(k) {
    ['arP', 'arE', 'arS', 'arB'].forEach(function (id) {
      var e = document.getElementById(id); if (e) { e.setAttribute('stroke', '#2a3252'); e.setAttribute('stroke-width', '2'); }
      var l = document.getElementById(LABS[id]); if (l) l.setAttribute('fill', '#6b7494');
    });
    ['ndRoad', 'ndFb', 'ndStory', 'ndBrief'].forEach(function (id) {
      var e = document.getElementById(id); if (e) { e.setAttribute('stroke', NODE_BASE[id]); e.setAttribute('stroke-width', '2'); }
    });
    var g = GROUP[k];
    if (g) {
      g.conns.forEach(function (id) {
        var e = document.getElementById(id); if (e) { e.setAttribute('stroke', g.col); e.setAttribute('stroke-width', '3'); }
        var l = document.getElementById(LABS[id]); if (l) l.setAttribute('fill', g.col);
      });
      g.nodes.forEach(function (id) {
        var e = document.getElementById(id); if (e) { e.setAttribute('stroke', NODE_BRIGHT[id]); e.setAttribute('stroke-width', '3'); }
      });
    }
    document.querySelectorAll('#ssSel button').forEach(function (b) {
      var on = b.getAttribute('data-k') === k; b.classList.toggle('active', on); b.setAttribute('aria-pressed', on ? 'true' : 'false');
    });
    var o = document.getElementById('ssOut'); if (o) o.innerHTML = OUT2[k];
  }
  ```
  Fixed datasets: `LABS = { arP: 'lbP', arE: 'lbE', arS: 'lbS', arB: 'lbB' }`; `NODE_BASE` and `NODE_BRIGHT`
  (per-node colours); `GROUP` mapping each key to `{ conns, nodes, col }` —
  `plan: { conns: ['arP'], nodes: ['ndRoad'], col: '#9fc0ea' }`,
  `derive: { conns: ['arS', 'arB'], nodes: ['ndStory', 'ndBrief'], col: '#a7c9b1' }`,
  `adapt: { conns: ['arE'], nodes: ['ndFb'], col: '#e0938f' }`; `OUT2` (readout strings). Initial call:
  `pick2('plan')`.
- **Readout strings (`OUT2`):**
  - `plan` — "The roadmap plans the spec — it sequences which rungs ship and when. It points at the spec; it never defines behaviour." (also the static markup default in `#ssOut`)
  - `derive` — "The user stories and the agent brief are derived from the spec — two views of the same truth. Change the spec and they change; never edit them on their own."
  - `adapt` — "Feedback from the demo and review edits the spec — the one place change lands. The roadmap re-plans, and the derived artifacts follow."

## Bridge / recap / references

- **take (closing the "truth" section):** "Two layers, one source of truth: plan in the roadmap, define in the
  spec, derive the rest, and let feedback edit only the spec. That asymmetry is what keeps an agent-built system
  honest."
- **note (forward pointer):** Deep dive — *Anatomy of a roadmap.md*
  (`/course/agile-agent-workflow/what/two-layer-model-roadmap-anatomy`) dissects the roadmap layer in the
  concrete: its milestones, the rungs that ship value, and a definition of done.
- **No `.bridge` block** (`.cell.idea` → `.arrow` → `.cell.elix`) is present on this page.
- **Sources (as on the page):**
  - `roadmap.md` & `spec.md` — the two layer artifacts this design names.
  - Beck, K. — *Extreme Programming Explained* — small batches and the cost-of-change curve.
  - Adzic, G. — *Specification by Example* — a single, living source of truth.
- **Related in this course (as on the page):**
  - Deep dive · Anatomy of a roadmap.md — `/course/agile-agent-workflow/what/two-layer-model-roadmap-anatomy`
  - A0 · Why an agile agent workflow — `/course/agile-agent-workflow/intro`
  - A0.2.2 · The four artifacts — `/course/agile-agent-workflow/what/four-artifacts`
  - Course · the six modules — `/course/agile-agent-workflow`

## Wiring

- **route-tag (on page):** `/course/agile-agent-workflow/what/two-layer-model`
- **Crumbs (as-found):**
  - `A0 · Why an Agile Agent Workflow` → `/course/agile-agent-workflow/intro` — **ANOMALY: this `/intro` route is
    now a 404 (the A0 `/intro` landing was removed). Recorded as-is; do not fix.**
  - `A0.2.1 · the two-layer model` (`.here`, current page, no link)
- **Eyebrow:** `A0.2 · framework · design 1`
- **toc-mini:** `#layers` (Roadmap over specs), `#truth` (Single source of truth), `#refs` (References)
- **Pager:**
  - prev (`.btn.ghost`) → `/course/agile-agent-workflow/intro` — "A0 · chapter overview" (also lands on the
    removed `/intro` route — same anomaly as the breadcrumb)
  - next (`.btn`) → `/course/agile-agent-workflow/what/four-artifacts` — "Next · the four artifacts"
- **Build stamp:** `#stampId` = `TSK0NgQDWuXRSK`; timestamp shown `2026-06-03 17:31:57 UTC`.
- **Shell:** `.hero-split` (hero text left, the two-layer-stack `.fig` figure right; stacks on mobile). Head,
  `<header class="site">`, footer, and the two trailing `<script>` blocks are the standard shared course shell.
