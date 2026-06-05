# Agile Agent Workflow in Elixir — agent brief (`.llms.md`)

> Pragmatic Programming with Claude Agents — building the **Portal** platform from zero to production over thin,
> provable increments. A human **Operator** supplies judgment, decomposition, and acceptance; a Claude **Author**
> supplies fast, well-specified implementation. This is the machine-readable brief for an agent reading, navigating,
> or extending the course — links first, prose second, every reference exact.

The course is a set of hand-authored static HTML pages served at `/course/agile-agent-workflow` by the jonnify Fiber
server (folder-routed via `serveDirTree` — the URL tree mirrors `html/agile-agent-workflow/`, read from disk live).
It practises the `.llms.md` convention it teaches. Structure: chapters `A0`–`A7`; each chapter has modules
`A[N].[M]` (two-digit M); each module has ≥3 deep-dive subpages `A[N].[M].[S]`. Status legend: `✓` built (live) ·
`◐` in progress · `○` planned.

## The course, served — routes, status, abstracts

### A0 · Foundations `✓` — the on-ramp · [/course/agile-agent-workflow/what](/course/agile-agent-workflow/what)
The method in three questions (why / what / who), previewing Part I. The landing doubles as the **A0.2** module hub
(consolidated from the retired `/intro`).

- A0.2.1 · [The two-layer model](/course/agile-agent-workflow/what/two-layer-model) — a roadmap that plans *how we
  deliver* over a spec that defines *what we build and prove*; the spec is the single source of truth.
  - deep dive · [Anatomy of a `roadmap.md`](/course/agile-agent-workflow/what/two-layer-model-roadmap-anatomy) —
    milestones, the rungs that ship value, the definition of done; the thin-but-robust slice.
- A0.2.2 · [The four artifacts](/course/agile-agent-workflow/what/four-artifacts) — `roadmap.md`, the spec,
  `.stories.md`, and the `.llms.md` agent brief, and the distinct question each answers.
- A0.2.3 · [The Author/Operator loop](/course/agile-agent-workflow/what/author-operator-loop) — the two roles and
  the rung cycle they run end to end.
- `○` A0.1 Why it works · `○` A0.3 Who does the work — previews of §1.1 and §1.3.

### A1 · Why an Agile Agent Workflow `✓` · [/course/agile-agent-workflow/why](/course/agile-agent-workflow/why)
The thesis chapter: why thin, provable slices beat both vibe coding and big-bang specs. **Complete — all six modules
A1.01–A1.06 built.**

- A1.01 `✓` · [The two failure modes](/course/agile-agent-workflow/why/failure-modes) — the no-plan and over-plan
  failures, and the slice that resolves both.
  - [vibe-coding](/course/agile-agent-workflow/why/failure-modes/vibe-coding) — unspecified, unaccepted diffs.
  - [big-bang-specs](/course/agile-agent-workflow/why/failure-modes/big-bang-specs) — the spec too big, too early.
  - [thin-slices](/course/agile-agent-workflow/why/failure-modes/thin-slices) — narrow, end-to-end, provable.
- A1.02 `✓` · [Pragmatic Programming, revisited for agents](/course/agile-agent-workflow/why/pragmatic) — the canon
  re-weighted when generation is cheap.
  - [dry](/course/agile-agent-workflow/why/pragmatic/dry) — duplication as a drift surface; the single source.
  - [contracts](/course/agile-agent-workflow/why/pragmatic/contracts) — the contract is the spec.
  - [orthogonality](/course/agile-agent-workflow/why/pragmatic/orthogonality) — decoupling for a bounded blast radius.
- A1.03 `✓` · [The Author/Operator loop](/course/agile-agent-workflow/why/loop) — the two roles and the cycle.
  - [roles](/course/agile-agent-workflow/why/loop/roles) — the hard line between Operator and Author.
  - [turn](/course/agile-agent-workflow/why/loop/turn) — one rung through the six owned stages.
  - [adapt](/course/agile-agent-workflow/why/loop/adapt) — feedback edits the spec, not the code.
- A1.04 `✓` · [Two layers: roadmap and specs](/course/agile-agent-workflow/why/two-layers) — separating delivery
  from definition.
  - [roadmap](/course/agile-agent-workflow/why/two-layers/roadmap) — the coarse, re-orderable delivery plan.
  - [spec](/course/agile-agent-workflow/why/two-layers/spec) — the single source of truth the rest derives from.
  - [source](/course/agile-agent-workflow/why/two-layers/source) — only feedback edits the spec; the two cadences.
- A1.05 `✓` · [Correct by definition](/course/agile-agent-workflow/why/correct) — "done" as a closure over traced,
  executed checks.
  - [the-closure](/course/agile-agent-workflow/why/correct/the-closure) — done is a closed set, not a feeling.
  - [proven-not-asserted](/course/agile-agent-workflow/why/correct/proven-not-asserted) — the check ran, not someone's
    say-so; the traceability spine.
  - [gates](/course/agile-agent-workflow/why/correct/gates) — the mechanical gates that make "A+" repeatable.
- A1.06 `✓` · [Meet the project: Portal](/course/agile-agent-workflow/why/portal) — the running project, zero to production.
  - [domain](/course/agile-agent-workflow/why/portal/domain) — Portal as surfaces over one facade.
  - [zero-to-production](/course/agile-agent-workflow/why/portal/zero-to-production) — what "zero" is and what "production" demands.
  - [one-rung](/course/agile-agent-workflow/why/portal/one-rung) — climbing from zero, thin provable rung by rung.

### A2 · Decomposition `✓` · [/course/agile-agent-workflow/decomposition](/course/agile-agent-workflow/decomposition)
Turning a product vision into a dependency-ordered value ladder of small, valuable, testable user stories. **Complete —
landing + all seven modules A2.01–A2.07 built.**

- A2.01 `✓` · [Value, not tasks](/course/agile-agent-workflow/decomposition/value) — a story names a change in what a
  role can do, not a chore.
  - [outcome-not-chore](/course/agile-agent-workflow/decomposition/value/outcome-not-chore) — task vs. story; the
    demonstrability test.
  - [who-benefits](/course/agile-agent-workflow/decomposition/value/who-benefits) — every slice names a role and its
    value; value is the ordering key.
  - [vertical-slice](/course/agile-agent-workflow/decomposition/value/vertical-slice) — value cuts through layers; a
    usable thread, not a horizontal chore.
- A2.02 `✓` · [The Connextra form and the three Cs](/course/agile-agent-workflow/decomposition/connextra) —
  role/want/reason; card, conversation, confirmation.
  - [role-want-reason](/course/agile-agent-workflow/decomposition/connextra/role-want-reason) — the template and its
    anti-patterns.
  - [three-cs](/course/agile-agent-workflow/decomposition/connextra/three-cs) — a promise with a conversation
    attached, not a frozen contract.
  - [portal-cards](/course/agile-agent-workflow/decomposition/connextra/portal-cards) — real Portal stories in the
    form; confirmation foreshadows Given/When/Then.
- A2.03 `✓` · [INVEST: what a good story looks like](/course/agile-agent-workflow/decomposition/invest) — the six
  tests and the common smells.
  - [six-tests](/course/agile-agent-workflow/decomposition/invest/six-tests) — each letter as a yes/no question,
    scored on a Portal story.
  - [story-smells](/course/agile-agent-workflow/decomposition/invest/story-smells) — too big, untestable, coupled,
    purely technical — diagnose and rewrite.
  - [small-and-independent](/course/agile-agent-workflow/decomposition/invest/small-and-independent) — the
    Independent–Small tension; estimability follows smallness.
- A2.04 `✓` · [Acceptance criteria with Given/When/Then](/course/agile-agent-workflow/decomposition/acceptance) —
  Gherkin scenarios as the executable definition of done.
  - [given-when-then](/course/agile-agent-workflow/decomposition/acceptance/given-when-then) — context / action /
    outcome; one scenario per behaviour.
  - [examples-as-spec](/course/agile-agent-workflow/decomposition/acceptance/examples-as-spec) — concrete examples as
    the shared definition of done.
  - [scenarios-to-tests](/course/agile-agent-workflow/decomposition/acceptance/scenarios-to-tests) — happy and sad
    paths become acceptance tests.
- A2.05 `✓` · [Splitting stories that are too big](/course/agile-agent-workflow/decomposition/splitting) —
  vertical-slice patterns that keep each slice demoable.
  - [when-to-split](/course/agile-agent-workflow/decomposition/splitting/when-to-split) — the signal: a story fails
    INVEST Small/Estimable.
  - [split-patterns](/course/agile-agent-workflow/decomposition/splitting/split-patterns) — by workflow step, business
    rule, happy/sad path, operation.
  - [vertical-not-horizontal](/course/agile-agent-workflow/decomposition/splitting/vertical-not-horizontal) — slice
    through the layers, not across them.
- A2.06 `✓` · [The value ladder](/course/agile-agent-workflow/decomposition/value-ladder) — composing stories into a
  dependency-ordered, always-runnable ladder.
  - [compose-the-ladder](/course/agile-agent-workflow/decomposition/value-ladder/compose-the-ladder) — stories into one
    ordered ladder of capabilities.
  - [dependency-order](/course/agile-agent-workflow/decomposition/value-ladder/dependency-order) — each rung rests only
    on rungs below it.
  - [always-runnable](/course/agile-agent-workflow/decomposition/value-ladder/always-runnable) — every rung leaves the
    system runnable and demoable.
- A2.07 `✓` · [Workshop — decomposing Portal](/course/agile-agent-workflow/decomposition/workshop) — the capstone, on
  the Portal's REAL web surface (the F6 Phoenix chapter): nine rungs `f6.1`–`f6.9` walked via a roadmap slider
  (why/what/when/how), cross-linked to the `/elixir/phoenix` chapters that build them. References distilled in
  `docs/elixir/content/phoenix/`.
  - [vision-to-stories](/course/agile-agent-workflow/decomposition/workshop/vision-to-stories) — apply value,
    Connextra, INVEST, acceptance to the vision.
  - [split-and-test](/course/agile-agent-workflow/decomposition/workshop/split-and-test) — split the outsize stories;
    re-test INVEST.
  - [order-the-backlog](/course/agile-agent-workflow/decomposition/workshop/order-the-backlog) — order across the five
    surfaces into the backlog Part III delivers.

### A3 · The roadmap layer `✓` · [/course/agile-agent-workflow/roadmap](/course/agile-agent-workflow/roadmap)
Planning delivery as thin, robust increments. The course's first **spec-first** chapter (specs in
`docs/agile-agent-workflow/specs/`: `aaw.roadmap.md`, `a3.{md,stories.md,llms.md}`, and the `a3.progress.md` build
narrative). Landing + three orientation dives + **all nine modules A3.1–A3.9** built.
- [where-we-are](/course/agile-agent-workflow/roadmap/where-we-are) — the journey A0→A2 recapped (Where + Who).
- [the-roadmap-layer](/course/agile-agent-workflow/roadmap/the-roadmap-layer) — why a delivery layer, and what a
  `roadmap.md` is (Why + What).
- [the-road-ahead](/course/agile-agent-workflow/roadmap/the-road-ahead) — a deep overview of the eight A3 modules
  (When + How).
- A3.1 `✓` · [Agile, distilled](/course/agile-agent-workflow/roadmap/agile-distilled) — the load-bearing principles vs
  the ceremony. Dives: `the-values` · `inspect-and-adapt` · `keep-vs-ceremony`.
- A3.2 `✓` · [Extreme Programming for small batches](/course/agile-agent-workflow/roadmap/xp-small-batches) — small
  batches lower risk, raise learning; an agent makes them cheap. Dives: `small-releases` · `incremental-design` ·
  `continuous-feedback`.
- A3.3 `✓` · [Anatomy of a roadmap.md](/course/agile-agent-workflow/roadmap/roadmap-anatomy) — the six parts a real
  `roadmap.md` carries, on the F6 exemplar. Dives: `what-it-carries` · `the-iteration-table` · `open-decisions`.
- A3.4 `✓` · [Thin but robust](/course/agile-agent-workflow/roadmap/thin-but-robust) — thin is a vertical slice, not a
  shallow one; robust is the seven F6 production properties. Dives: `thin-not-shallow` · `what-robust-adds` · `always-live`.
- A3.5 `✓` · [Milestones and iterations](/course/agile-agent-workflow/roadmap/milestones) — group rungs into shippable
  milestones; the Ships/Demo/Harness/Feedback iteration; sequence by dependency and value. Dives: `shippable-milestones`
  · `the-iteration-loop` · `sequencing-the-ladder`.
- A3.6 `✓` · [The program roadmap](/course/agile-agent-workflow/roadmap/program-roadmap) — the roadmap of roadmaps; web
  and bot as parallel surfaces over one facade, on independent cadences. Dives: `roadmap-of-roadmaps` ·
  `one-core-many-surfaces` · `independent-cadence`.
- A3.7 `✓` · [Tracer bullets and walking skeletons](/course/agile-agent-workflow/roadmap/tracer-bullets) — a thin
  end-to-end thread (F6.1) before depth; tracer vs skeleton vs prototype; defer breadth. Dives: `end-to-end-first` ·
  `tracer-vs-prototype` · `defer-breadth`.
- A3.8 `✓` · [Workshop — roadmapping Portal](/course/agile-agent-workflow/roadmap/workshop) — run the whole A3 sequence
  to reproduce the real F6 `phoenix.roadmap.md`. Dives: `ladder-to-roadmap` · `choose-the-tracer` · `the-program-view`.
- A3.9 `✓` · [Glossary, references & the framework crosswalk](/course/agile-agent-workflow/roadmap/glossary) — a
  UX-friendly expandable list: term → abstract → source → where the framework implements it. Dives: `glossary` ·
  `sources` · `crosswalk`.

### A4 · The spec layer `✓` · [/course/agile-agent-workflow/spec](/course/agile-agent-workflow/spec)
Defining and proving each rung the roadmap points at — correct by definition. The course's second **spec-first**
chapter (specs in `docs/agile-agent-workflow/specs/`: `a4.{md,stories.md,llms.md}` + the `a4.progress.md` build
narrative). Landing (no orientation dives) + **all seven modules A4.1–A4.7** built, grounded verbatim on the real
F6.1 / F5.1 rung triads; every `pre.code` carries spec/stories text, never Elixir.
- A4.1 `✓` · [Specification by Example](/course/agile-agent-workflow/spec/by-example) — concrete examples become the
  executable specification; living documentation that cannot drift. Dives: `examples-as-spec` · `living-documentation`
  · `removing-ambiguity`.
- A4.2 `✓` · [The triad: spec, stories, agent brief](/course/agile-agent-workflow/spec/the-triad) — one artifact per
  question (what&why&done · who wants what · how to build); the course's own `a4.*` is the same triad. Dives:
  `which-question` · `the-real-triad` · `the-course-itself`.
- A4.3 `✓` · [Anatomy of a spec](/course/agile-agent-workflow/spec/spec-anatomy) — the six sections read verbatim on
  `f6.1.md`; constrain without over-specifying. Dives: `the-six-sections` · `the-five-ws` · `constrain-not-overspecify`.
- A4.4 `✓` · [From stories to a .stories.md](/course/agile-agent-workflow/spec/to-stories) — every deliverable realized
  by a story; the INVEST line and the Coverage map, on the real F6.1 stories. Dives: `deliverable-to-story` ·
  `the-coverage-line` · `invest-and-invariants`.
- A4.5 `✓` · [Invariants](/course/agile-agent-workflow/spec/invariants) — an invariant (true for every value, always)
  vs an acceptance check (true for one scenario); the master invariant. Dives: `invariant-vs-check` ·
  `the-master-invariant` · `always-true`.
- A4.6 `✓` · [Traceability — correct by definition](/course/agile-agent-workflow/spec/traceability) — the chain
  deliverable → story → check & invariant → requirement, and the completion rule that closes it (ties A1.05). Dives:
  `the-chain` · `the-closure` · `a-broken-link`.
- A4.7 `✓` · [Workshop — specifying Portal's engine](/course/agile-agent-workflow/spec/workshop) — run the whole A4
  sequence on the real F5.1 engine triad to reproduce a closed, acceptable spec. Dives: `the-engine-deliverables` ·
  `run-the-sequence` · `the-closed-spec`.
- A4 viewer `✓` · [The spec ladder](/course/agile-agent-workflow/spec/specimens) — an auxiliary page (not a numbered
  module): a git-iteration slider over the shipped F6.1→F6.6 ladder, reached from the inline `.specref` citation chips
  that frame each `F6.N` rung on the A4 lesson pages (click-to-expand tooltip → this viewer).

### A5 · The agent brief `◐` · [/course/agile-agent-workflow/brief](/course/agile-agent-workflow/brief)
Landing + a why/what/how orientation triptych built (grounded on the seeded triad `a5.{md,stories,llms}.md`); the
eight modules A5.1–A5.8 build next.
- A5 orientation `✓` · [why](/course/agile-agent-workflow/brief/why) — a spec is not runnable on its own; the brief
  fixes every remaining *how-to-build* decision. [what](/course/agile-agent-workflow/brief/what) — the five parts of
  an `.llms.md` and the eight modules ahead. [how](/course/agile-agent-workflow/brief/how) — write the brief, run the
  agent, review against the spec's Definition of Done, not the agent's self-report.

### A6 · Reliability and correctness `◐` · [/course/agile-agent-workflow/reliability](/course/agile-agent-workflow/reliability)
Landing + a why/what/how orientation triptych built (grounded on `aaw.roadmap.md`; modules **deferred** until the
`a6.*` triad is seeded — scope at roadmap altitude: OTP supervision, boundaries, parse-don't-validate, property tests).
- A6 orientation `✓` · [why](/course/agile-agent-workflow/reliability/why) — A5's increment is correct on the happy
  path but not proven under failure; A6 closes that gap. [what](/course/agile-agent-workflow/reliability/what) — the
  four scope pillars. [how](/course/agile-agent-workflow/reliability/how) — harden the increment; prove invariants,
  do not assert them.

### A7 · Portal exemplar (zero to production) `◐` · [/course/agile-agent-workflow/portal](/course/agile-agent-workflow/portal)
Landing + a why/what/how orientation triptych built (grounded on `aaw.roadmap.md`; the A7.01–A7.07 steps build once
the `a7.*` triad is seeded). The capstone — the whole loop run end to end on the Portal.
- A7 orientation `✓` · [why](/course/agile-agent-workflow/portal/why) — the exemplar is worth running only because
  every rung was hardened to production quality first. [what](/course/agile-agent-workflow/portal/what) — the
  zero-to-production sequence. [how](/course/agile-agent-workflow/portal/how) — the loop runs once, uninterrupted,
  with the roles unchanged.

Full per-chapter abstracts: the TOC; live per-rung completion: `specs/aaw.progress.md`.

## Sources of record — author here; the served HTML is hand-built from these
- Living table of contents + per-chapter abstracts + build status — `docs/agile-agent-workflow/agile-agent-workflow.toc.md`
- Machine route/status map + the current resume point — `.claude/skills/agile-course-writer/references/course-map.md`
- Per-page md sources (lead, definitions, both interactives, references, wiring) — `docs/agile-agent-workflow/content/<chapter>/<module>/<page>.md`
- The authoring skill — conventions, the ten gates, voice, the interactive contract, the workflow — `.claude/skills/agile-course-writer/SKILL.md`
- Shared design craft (tokens, visualization, page anatomy) — `.claude/skills/elixir-technical-writer/references/`

These three views — the served pages, the `course-map.md` table, and the TOC — must never contradict one another;
a change to one is a change to all three.

## The running project: Portal
One learning platform carried from an empty repository to production: a branded store, an event-sourced engine
behind one facade, a Phoenix web app, a Telegram bot, and a student dashboard. Every example lands on the Portal so
concepts accumulate. The Portal's Elixir/OTP internals are taught by the companion course `/elixir` — cite it, do
not re-teach. Branded ids use only `Portal.ID.generate/1` and `Portal.ID.decode/1` (`.type`, `.timestamp`); do not
invent other Portal APIs.

## Conventions an author must hold
- **The four artifacts.** `roadmap.md` (how we deliver) · the spec (what we build and prove — the single source of
  truth, edited only by feedback) · `.stories.md` (acceptance, Given/When/Then) · `.llms.md` (this brief form).
- **The Author/Operator loop.** The Operator (human) sharpens, demos, reviews, and accepts, and never writes the
  code; the Author (Claude agent) builds and ships, and never decides the goal; they meet on the spec; feedback
  edits the spec, not the code.
- **The ten gates** (ship only at `STATUS: PASS`): `containers` · `svg` · `no-future` · `voice` · `storage` ·
  `motion` · `degrade` · `links` · `pager` · `refs`.
  ```bash
  apps/jonnify-cms/bin/cms check \
    --routes-from /course/agile-agent-workflow=html/agile-agent-workflow \
    --chapter-alias a0=what,a1=why --require-refs html/agile-agent-workflow/<path>.html
  ```
- **Gate-invisible — verify by reading.** Clamp spacing must be spaced (`clamp(2.7rem,1.9rem + 4.2vw,5.1rem)`, not
  `1.9rem+4.2vw`, which is invalid CSS dropped to a UA default); a link that *resolves* may still be the *wrong*
  route (read crumbs/pager); and **every References → Sources entry must be a real, vetted external link** — the
  `refs` gate only checks the block is present. Reuse the registry below; never fabricate a URL.
- **Voice.** No first person, no exclamation marks, no emoji, no hype (`just`, `simply`, `obviously`, `effortless`,
  `magical`, `revolutionary`, `blazing`), no perceptual or interior-state verbs applied to a tool or an agent.
- **Each page.** Two interactives — one in the `.hero-split`, one in the main content — each performing the real
  operation with a live `.geo-readout`, degrading without JS, honouring `prefers-reduced-motion`, no browser
  storage; a `.bridge` (principle → Portal practice); a branded `TSK…` Snowflake build stamp.

## References — the Sources registry (real, vetted; reuse, never fabricate)
- The Pragmatic Programmer — <https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/>
- Extreme Programming Explained — <https://www.oreilly.com/library/view/extreme-programming-explained/0201616416/>
- Specification by Example — <https://gojko.net/books/specification-by-example/>
- User Stories Applied — <https://www.mountaingoatsoftware.com/books/user-stories-applied>
- Continuous Delivery — <https://continuousdelivery.com/>
- The `llms.txt` convention — <https://llmstxt.org/>
- Anthropic — Building effective agents — <https://www.anthropic.com/engineering/building-effective-agents>
- Anthropic — Claude Code best practices — <https://www.anthropic.com/engineering/claude-code-best-practices>

The full canon (Agile Manifesto, Gherkin/BDD, INVEST, Railway-Oriented Programming, parse-don't-validate,
`StreamData`, Boundaries, and more) is the **Appendix** of `agile-agent-workflow.toc.md`.

## Extending the course — the workflow
1. **Draft the md source first** under `docs/agile-agent-workflow/content/<chapter>/<module>/`.
2. **Author the module hub**, then **fan out one agile-course-writer-skilled agent per dive, in parallel** (each
   given: this skill, a model page, the exact route + numbering, the gate command, the no-invent guard — Portal API
   and real source links — and a no-git constraint).
3. **Gate every page** to `STATUS: PASS`; adversarially verify the gate-invisible bits.
4. **Relink the chapter landing** card (div → a, `soon` → `live`); confirm new routes 200 and unbuilt siblings 404.
5. **Sync the three views** — this brief, the TOC, and `course-map.md` — so they agree.

---

> Part of the jonnify toolkit. One project, carried from zero to production by a human and a Claude agent working a
> tight loop over thin, provable increments. The roadmap plans; the spec defines and proves; the agent builds; the
> gates accept.
