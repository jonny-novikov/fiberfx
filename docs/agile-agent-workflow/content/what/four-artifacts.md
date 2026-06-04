# A0.2.2 — The four artifacts

- **Route:** `/course/agile-agent-workflow/what/four-artifacts`
- **File:** `html/agile-agent-workflow/what/four-artifacts.html`
- **Place in the module:** the second design page of the A0.2 "What we are building" module — the framework's
  vocabulary: the four plain-text artifacts every rung is carried by, and the one distinct question each one answers.
- **Accent word (`.ex`):** "artifacts".

## Lead

Every rung is carried by four plain-text artifacts, and each answers exactly one question: a **roadmap**, a
**spec**, the **user stories**, and the **agent brief**. Four files, four questions, no overlap. Select one to see
what it answers.

(Hero eyebrow: "A0.2 · framework · design 2". Page title: "A0.2.2 — The four artifacts · Agile Agent Workflow ·
jonnify". Meta description: "The framework's vocabulary: the roadmap.md, the spec, the user stories, and the agent
brief (.llms.md) — the four artifacts every rung uses, and the distinct question each one answers.")

## Definition (the four artifacts, exactly as the page states them)

Each artifact answers exactly one question. The `roadmap.md` answers *what ships, and in what order*. The **spec**
answers *what we build and how we know it is right*. The **user stories** answer *what the user gets*, as concrete
acceptance criteria. The **agent brief** — an `.llms.md` file — answers *how the agent builds it*. Four files, four
questions, no overlap.

The `.deflist` definitions (verbatim, term → definition):

- **roadmap.md** — The delivery plan: the chapter's rungs and their order. Answers what ships, and when. Re-planned
  freely.
- **spec** — The definition and proof of one rung: the behaviour to build and the invariants that must hold. The
  single source of truth.
- **user stories** — Acceptance criteria derived from the spec — Given/When/Then examples a person can read and
  sign off.
- **agent brief (.llms.md)** — The implementation plan for a Claude agent: references, execution topology, and
  agent stories. Answers how it gets built.

## Why it matters

Keeping the questions separate keeps the artifacts honest. A spec that also lists build steps drifts from the
behaviour it should pin down; a brief that re-states acceptance criteria duplicates the stories and rots when they
change. Each artifact is derived from, or planned against, the spec — so the four stay consistent by construction,
not by diligence.

The triad: three of the four artifacts move together as a **triad** — the spec, its user stories, and its agent
brief. The spec is the contract; the stories are how a person accepts it; the brief is how the agent builds it.
Stories and brief are both *derived* from the spec, which is why a rung can be *correct by definition* — the
acceptance a human signs and the plan the agent follows come from the same source. The fourth artifact, the
roadmap, sits outside the triad: it decides *which* rung the triad is for, and when.

## Worked Portal example

None present on the page. (No `pre.code` block; no Portal-specific worked example. The page is a vocabulary/design
page; examples stay conceptual.)

## The two interactives

Both interactives are `.fig` figures driven by `.solid-select` button groups; each re-strokes SVG tiles and
rewrites a live `.geo-readout` from a fixed per-key dataset (`OUT1` / `OUT2`). Both initialize to `spec` on load
(`pick1('spec'); pick2('spec');`).

### Hero figure — "The four artifacts · select one" (the FOUR; frames the vocabulary)

- **Figure:** `aria-labelledby="a4Title"` (h4 id `a4Title`).
- **Control:** `.solid-select` id `#a4Sel` (role group, aria-label "An artifact"), four buttons:
  - `data-k="roadmap"` `data-c="blue"` → label `roadmap`
  - `data-k="spec"` `data-c="gold"` `class="active"` → label `spec` (default active)
  - `data-k="stories"` `data-c="sage"` → label `stories`
  - `data-k="brief"` `data-c="elixir"` → label `brief`
- **SVG tiles (ids + base/bright strokes from the `ART` map):** `#artRoad` (roadmap.md / the plan; base `#5a87c4`,
  bright `#9fc0ea`), `#artSpec` (spec / the definition; base `#d4a85a`, bright `#f0cd7f`), `#artStory` (.stories.md
  / the acceptance; base `#7ba387`, bright `#a7c9b1`), `#artBrief` (.llms.md / the build; base `#b39ddb`, bright
  `#cdb8f0`). SVG tile captions on the face: roadmap.md = "the plan" / "what ships, in what order"; spec = "the
  definition" / "what's built & how it's proven"; .stories.md = "the acceptance" / "what the user gets"; .llms.md =
  "the build" / "how the agent builds it".
- **Readout:** `#a4Out` (aria-live polite).
- **Pure function (verbatim signature):**

  ```js
  function pick1(k) {
    Object.keys(ART).forEach(function (key) {
      var el = document.getElementById(ART[key].id); if (!el) return;
      var on = key === k;
      el.setAttribute('stroke', on ? ART[key].bright : ART[key].base);
      el.setAttribute('stroke-width', on ? '3' : '2');
    });
    document.querySelectorAll('#a4Sel button').forEach(function (b) {
      var on = b.getAttribute('data-k') === k; b.classList.toggle('active', on); b.setAttribute('aria-pressed', on ? 'true' : 'false');
    });
    var o = document.getElementById('a4Out'); if (o) o.innerHTML = OUT1[k];
  }
  ```

- **Readout strings (`OUT1`, verbatim):**
  - `roadmap` → "The roadmap answers what ships and in what order — the chapter's rungs and their sequence. It plans
    the work; it never defines behaviour."
  - `spec` → "The spec answers what we build and how we know it is right — the rung's contract and the checks that
    prove it. It is the single source of truth." (also the static default text in `#a4Out`)
  - `stories` → "The user stories answer what the user gets — acceptance criteria, derived from the spec, that a
    person can read and sign off."
  - `brief` → "The agent brief (.llms.md) answers how the agent builds it — references, execution topology, and
    agent stories the Claude agent follows."

### Content figure — "The triad · select a face" (the TRIAD; proves spec-is-source consequence)

- **Figure:** `aria-labelledby="trTitle"` (h4 id `trTitle`), in `<section id="triad">`.
- **Control:** `.solid-select` id `#trSel` (role group, aria-label "A face of the triad"), three buttons:
  - `data-k="spec"` `data-c="gold"` `class="active"` → label `spec` (default active)
  - `data-k="stories"` `data-c="sage"` → label `stories`
  - `data-k="brief"` `data-c="elixir"` → label `agent brief`
- **SVG nodes (ids + base/bright strokes from the `TRI` map):** `#trSpec` (spec / "the contract", at top; base
  `#d4a85a`, bright `#f0cd7f`), `#trStory` (stories / "acceptance criteria"; base `#7ba387`, bright `#a7c9b1`),
  `#trBrief` (agent brief / "implementation plan"; base `#b39ddb`, bright `#cdb8f0`). Connector lines `#trcS`
  (spec→stories) and `#trcB` (spec→brief); "derived" labels `#trlS` and `#trlB`. SVG caption: "the roadmap plans
  which rung · the triad defines and builds it".
- **Readout:** `#trOut` (aria-live polite).
- **Pure function (verbatim signature):**

  ```js
  function pick2(k) {
    Object.keys(TRI).forEach(function (key) {
      var el = document.getElementById(TRI[key].id); if (!el) return;
      var on = key === k;
      el.setAttribute('stroke', on ? TRI[key].bright : TRI[key].base);
      el.setAttribute('stroke-width', on ? '3' : '2');
    });
    var cS = document.getElementById('trcS'), cB = document.getElementById('trcB');
    var lS = document.getElementById('trlS'), lB = document.getElementById('trlB');
    var sOn = (k === 'spec' || k === 'stories'), bOn = (k === 'spec' || k === 'brief');
    if (cS) { cS.setAttribute('stroke', sOn ? '#a7c9b1' : '#2a3252'); cS.setAttribute('stroke-width', sOn ? '3' : '2'); }
    if (cB) { cB.setAttribute('stroke', bOn ? '#cdb8f0' : '#2a3252'); cB.setAttribute('stroke-width', bOn ? '3' : '2'); }
    if (lS) lS.setAttribute('fill', sOn ? '#a7c9b1' : '#6b7494');
    if (lB) lB.setAttribute('fill', bOn ? '#cdb8f0' : '#6b7494');
    document.querySelectorAll('#trSel button').forEach(function (b) {
      var on = b.getAttribute('data-k') === k; b.classList.toggle('active', on); b.setAttribute('aria-pressed', on ? 'true' : 'false');
    });
    var o = document.getElementById('trOut'); if (o) o.innerHTML = OUT2[k];
  }
  ```

  Note: selecting `spec` lights *both* connectors/derived-labels (`sOn` and `bOn` both true); `stories` lights only
  the spec→stories connector; `brief` lights only the spec→brief connector.

- **Readout strings (`OUT2`, verbatim):**
  - `spec` → "The spec is the rung's contract: the behaviour to build and the invariants that must hold. The
    stories and the brief are both derived from it." (also the static default text in `#trOut`)
  - `stories` → "The user stories are the acceptance criteria — Given/When/Then examples derived from the spec that
    a person signs off."
  - `brief` → "The agent brief is the implementation plan — references, topology, and agent stories the Claude
    agent builds from, derived from the spec."

## Bridge / recap / references

- **Bridge:** No `.bridge` (`.cell.idea` → `.arrow` → `.cell.elix`) block is present on this page.
- **Take (closing `.take` of the triad section, verbatim):** "Four artifacts, one question each, and a triad that
  cannot disagree with itself: that is how a rung stays defined, accepted, and built from a single source."
- **References lead (verbatim):** "Primary sources for this design, and where it connects in the course."
- **Sources (real, verbatim):**
  - `llms.txt` — the convention for agent-facing documentation.
  - Cohn, M. — *User Stories Applied* — stories and their acceptance criteria.
  - Adzic, G. — *Specification by Example* — deriving checks from a shared spec.
- **Related in this course (label → href):**
  - "A1 · Why an agile agent workflow" → `/course/agile-agent-workflow/why`
  - "A0.2.1 · The two-layer model" → `/course/agile-agent-workflow/what/two-layer-model`
  - "Course · the six modules" → `/course/agile-agent-workflow`

## Wiring

- **Route-tag on page:** `/course/agile-agent-workflow/what/four-artifacts`.
- **Crumbs (as found):** `A0.2 · What we are building` → `/course/agile-agent-workflow/what`; sep `/`; here
  `A0.2.2 · the four artifacts` (no link). Note: the crumb trail is two-level (parent module + here); there is no
  separate chapter (A0) or brand crumb.
- **toc-mini:** "What each answers" → `#answers`; "The triad" → `#triad`; "References" → `#refs`.
- **Pager:**
  - prev (`.btn.ghost`): "A0.2.1 · the two-layer model" → `/course/agile-agent-workflow/what/two-layer-model`
  - next (`.btn`): "A0.2 · module overview" → `/course/agile-agent-workflow/what`
- **Header brand href:** `/elixir`. Nav "Course" → `/course/agile-agent-workflow`.
- **Build stamp:** `#stampId` = `TSK0NgLsudp1TU`; static `#st-ts` placeholder = `2026-06-03 16:31:19 UTC`.

## Anomalies / notes (recorded as-is, not fixed)

- **Header brand and footer fbrand link to `/elixir`, not the course or `/`** — `<a class="brand" href="/elixir">`
  and `<a class="fbrand" href="/elixir">`. This is the shared shell convention but the brand points at the
  companion course root.
- **Crumbs are two-level only** — they start at the module (`A0.2 · What we are building`), with no jonnify / AAW /
  chapter-A0 ancestry crumbs. This matches A0's flat exception (the `/what` module is a flat sibling of `/intro`),
  but differs from the deeper crumb trail described for A1+ lesson pages in the format model.
- **SVG tile labels use file-name forms that differ from the deflist terms** — the hero SVG tiles read
  `.stories.md` (acceptance) and `.llms.md` (build), while the deflist names them "user stories" and "agent brief
  (.llms.md)". The roadmap tile uses `roadmap.md`. Consistent with the page's own usage; flagged for fidelity.
- **No worked Portal code example and no `.bridge` block** on this page (unlike the lesson format model
  `two-layers/source.md`). This page is a module *design* page (eyebrow "framework · design 2"), so those sections
  are legitimately absent — recorded so the md is not "padded" with sections the HTML lacks.
- **The `.reveal` scroll-reveal machinery and Snowflake decoder are present in script** but no element on the page
  carries the `.reveal` class, so nothing animates in; the second `<script>` runs harmlessly.
