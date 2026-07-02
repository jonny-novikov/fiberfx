---
description: spec-write — senior-author a chapter's spec system (the index + roadmap + an exemplar rung triad), then fan out spec-author subagents (general-purpose fallback) to author the remaining rung triads in parallel, adversarially gate against specs.approach.md, and sync the chapter status. The spec-system sibling of /redis-write and /agile-write.
argument-hint: <chapter-dir-or-slug> [<rungN> …]  (e.g. `docs/elixir/redlock`  ·  `phoenix f6.10,f6.11`  ·  a new chapter topic to design)
allowed-tools: Agent, Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
model: fable
---

# /spec-write — senior-author-then-fan-out for the Portal spec triads

You are scaffolding (or extending) a **spec system** under `docs/elixir/` that follows
`docs/elixir/specs/specs.approach.md`: a chapter **index** (`<chapter>.md`), a chapter
**roadmap** (`<chapter>.roadmap.md`), and a **triad per rung** (`<rung>.md` + `.stories.md` + `.llms.md`). The method is
**senior-author-then-fan-out**: the orchestrator (you) authors the chapter docs + the *first* rung triad — the work that
**locks the design** — then fans out one general-purpose subagent per *remaining* rung to apply the locked template,
then adversarially gates every file against the `specs.approach.md` quality gates and syncs the chapter status.

Two sources of truth govern, and where this command disagrees with them, they win:
1. **`docs/elixir/specs/specs.approach.md`** — the contract: the exact templates for the index, the roadmap, and the
   triad, plus the quality gates (voice · structure · traceability · fences · links · format) and the completion rule.
2. **The chapter's own index + roadmap** — once authored, they are canonical for *this* chapter's value ladder, master
   invariant, closed error set, and architecture decision. A fanned rung is built only from them; **never invent
   structure, an invariant, or a grounding a rung does not already own.**

This is the spec-system sibling of `/redis-write` (course pages) and `/agile-write`. It writes **markdown specs, not
code and not HTML** — the spec is the source of truth; code comes later, from a rung's `.llms.md` prompt.

## Arguments

```
<chapter-dir-or-slug> [<rungN> …]
```

Parse:

- **Token 1 = the chapter.** A path (`docs/elixir/redlock`), a slug under `docs/elixir/specs/` (`phoenix`, `bot`,
  `echomq`), or — if neither exists yet — a **new chapter topic** to design from scratch.
- **Tokens 2…N = the rungs to author** (e.g. `f6.10 f6.11`, or `RL2,RL3`). If omitted, author **every rung the
  chapter's value ladder names that does not yet have a triad** (the common case: scaffold the whole ladder).

If the chapter does not exist and no ladder is given, you are **designing a new chapter** — Step 1 authors the index +
roadmap + designs the ladder before any rung is written. If the arg is empty, ask in plain text which chapter; do
**not** guess a large scope.

## Step 0 — Ground the batch (read-only)

1. Read `docs/elixir/specs/specs.approach.md` — the templates (`<chapter>.md`,
   `<chapter>.roadmap.md`, the triad) and the six quality gates. This is the structure authority.
2. Read the **closest existing analog** as the house-style model — for a Portal-program chapter,
   `docs/elixir/specs/echomq/echomq.md` + `echomq.roadmap.md`; for a standalone-library chapter (a sibling of
   `specs/`, like `docs/elixir/redlock/`), the redlock index + roadmap. Match its tone and section order.
3. If the chapter's `<chapter>.md` + `<chapter>.roadmap.md` already exist, read them (the value ladder, the master
   invariant, the closed error set, the architecture decision) and **at least one built triad** as the exemplar. If
   they do not exist, Step 1 authors them.
4. For each requested rung resolve: its id (`FN.M` / `RLN` / `E[N]`), its row in the value ladder (feature · value ·
   port source / grounding), its deliverables-in-brief, and its dependency-ordered position.

## Step 0.5 — The exploration wave (read-only; for a source-grounded chapter)

When the chapter grounds in a **real source tree** — a course chapter built from real code + a corpus (the EchoMQ
course over `echo/apps/echomq` + `docs/echomq/content/`), or any spec that must cite a real surface — the design needs
a **verified** surface inventory before Step 1 can fix the grounding. Run a **calibrated exploration wave**, and keep
it distinct from the authoring wave: the two have *opposite* concurrency profiles, and conflating them is the classic
mistake.

- **Exploration wave (read-only) — HIGH concurrency.** Fan out ~3–5 `general-purpose` (or `Explore`) agents in ONE
  message, each reading a different slice (e.g. the protocol/scripts; the runtime surface + real arities; the content
  corpus; the production/ops + sibling-runtime port). Read-only agents do not write-conflict, so run them all at once.
  Each returns a COMPACT structured inventory (module → function → **verified arity**; the key/script taxonomy;
  per-chapter abstracts), not file dumps. This is where every grounding fact is captured — a depth course cannot cite
  an unverified surface, and an agent's arity guess is the exact thing that drifts.
- **Authoring wave (heavy edit) — LOW concurrency (≤2, or 1).** The fan-out that writes triads (Step 2) stays at the
  proven ≤2 ceiling; for a NEW agent's first outing, or the single most-complex rung, use **1** (a lone agent is
  safest). Never size the authoring wave like the exploration wave.

Synthesize the wave's returns into the grounding map before Step 1, and **cross-check the agents against each other** —
a surface one cites and another contradicts is unverified, so probe it (a real run caught a cluster-validator name that
existed under a different identifier than expected). Skip this step for a pure-design library spec that grounds only in
its own forward-looking modules.

## Step 1 — Senior-author the design (ORCHESTRATOR-ONLY — never delegated)

This is the phase that locks the design, so **you** do it, not a subagent. Concretely:

- **If the chapter docs do not exist, author them first** — `<chapter>.md` (the index: the value ladder table, the
  start/end handoff, the **master invariant**, the **closed error set**, per-rung abstracts + status) and
  `<chapter>.roadmap.md` (the delivery plan: what it delivers, the **architecture decision** + its reversible seam,
  the master invariant, the Author/Operator loop, "thin but robust", the milestone table + the per-rung iteration
  table `Rung · Ships · Demo · Harness · Feedback asked`, seams & open decisions, conventions). These fix the ladder,
  the invariants, the error vocabulary, and the architecture trade every rung inherits.
- **Author the FIRST rung's triad yourself** — `<rung1>.md` + `.stories.md` + `.llms.md` — to the `specs.approach.md`
  templates exactly. This triad is the **exemplar** the fan-out copies: its section order, its footer line, its id
  scheme, its traceability shape. Get it right; the fan-out only ever copies a model that is already correct.
- **Fix the closed error set and the master invariant in prose** before any fan-out, and decide the naming scheme
  (`<rung>.md`/`.stories.md`/`.llms.md`, id prefix). The footer link is `Approach: ../specs/specs.approach.md` for a
  sibling-of-`specs/` chapter, or `../specs.approach.md` for a chapter *under* `specs/` — match the analog.
- **Inject the persistent design pack** — author a `<rung>.prompt.md` (or `<chapter>.prompt.md` for a landing) that
  fixes the design durably: the deliverables, the per-item grounding from the map, the model/exemplar to copy, the gate
  command, and the no-invent guard. This pack is the orchestrator's design-lock *made persistent* — it (a) survives
  across sessions for the later build/implementation stage, (b) becomes the canonical source the `<rung>.llms.md`
  comprehensive-prompt POINTS TO (never duplicated), and (c) lets the fan-out author even the FIRST rung when a
  shape-exemplar already exists elsewhere in the repo: the orchestrator locks the design in the `.prompt.md` rather
  than hand-authoring the exemplar triad, then delegates the mechanical application. (This is how the EchoMQ E0 run
  worked — `e0.prompt.md` fixed the design and a single spec-author applied it.)

**Course-chapter mode (when the rung is a COURSE chapter — a `/redis-patterns` or `/echomq` chapter — not a code
rung).** The same three files and the same six-section / five-bullet structure apply, but three sections bind to
*pages* instead of code: **Deliverables = pages** (the chapter landing, each module hub, each dive, the home/TOC
relink); **Invariants = properties of the pages** (the master invariant holds in the PROSE · no-invention with
verified citations · the page anatomy + the ten cms gates pass · the `soon`-pill route-manifest is the one expected
`links` exception, and any cross-course back-door resolves); **Execution topology = the page-authoring DAG** (landing →
hubs → dives → relink/TOC-sync) with a `Touched files:` list spanning `html/<course>/…` (the built pages) and
`docs/<course>/markdown/…` (the route-mirror sources). The footer gains a **Roadmap** segment
(`Stories · Agent brief · Index · Roadmap · Approach`), since the grounding contract lives in the roadmap. The worked
adaptation is `docs/echomq/echomq.md` ("The spec triad for a course chapter").

Do **not** fan out until the chapter docs + the design pack (and the exemplar triad, where one is hand-authored) are
written and self-consistent.

## Step 2 — Fix each remaining rung's design, then fan out (≤2 heavy agents at a time)

For **each** remaining rung, first write — in the agent's brief — the rung's **fixed design**: its deliverables
(`<rung>-D#`), its invariants (`<rung>-INV#`), the closed-error reasons it produces, its port source / grounding, and
the one or two mechanics it adds. The agent **applies the template to this fixed design; it does not invent the
design.** This is the discipline that keeps the ladder coherent.

Then spawn the agents. Use `subagent_type: "spec-author"`; **if that errors "agent type not found"** the def is not
loaded this session — fall back to `subagent_type: "general-purpose"` (the brief below is self-contained, so it
behaves the same). `venus` is reserved for the AAW lead-team flow, not this fan-out. **Cap at ≤2 concurrent heavy
authoring agents** (the proven rate-safe ceiling; a lone agent is safest for the most complex rung) — fan out in waves
of 2, the exemplar already written. Give each agent:

- its **rung id, the three target file paths**, and its **fixed design** (deliverables, invariants, error reasons,
  port/grounding, mechanics) from above;
- the **read list**: the chapter `<chapter>.md` (master invariant + closed error set + its ladder row), the
  `<chapter>.roadmap.md` (its iteration row + the architecture decision), `specs.approach.md` (the templates + gates),
  the **`<rung>.prompt.md`** if you authored one (the fixed design the triad derives from — its Deliverables ARE that
  pack's items), and the **exemplar triad** (copy its structure/section-order/footer EXACTLY, changing only the rung
  and content — for a course chapter the shape exemplar is a clean code triad like `docs/elixir/redlock/rl1.*`, and the
  content exemplar is a built course triad like `docs/redis-patterns/specs/overview/r0.1.*`);
- the **template-fidelity rules** (these ARE the gates): the spec `.md` has **exactly six `##` sections** (Goal ·
  Rationale (5W) · Scope · Deliverables · Invariants · Definition of Done), the Rationale has **exactly five bold
  bullets** (**Why**/**What**/**Who**/**When**/**Where**), Scope has **In**/**Out**, the DoD is `- [ ]` checkboxes; the
  `.stories.md` has Connextra stories with Given/When/Then, an `INVEST — …; encodes <rung>-INV#.` line, a
  `Priority/Size/Implements` line, and a closing **Coverage line**; the `.llms.md` matches the exemplar's section order
  (References · Requirements `<rung>-R# [US: <rung>-US#]` · Execution topology = a runtime fenced block + a tasks fenced
  block + a `Touched files:` line · Agent stories `<rung>-AS# [implements <rung>-US#]` · Execution plan — first two
  stories · Comprehensive implementation prompt as a fenced block);
- the **traceability closure**: every `D#` in the Coverage line; every `R#` carries `[US: …]`; every `AS#` carries
  `[implements …]`; every `INV#` is named by ≥1 story's `encodes`;
- the **hard constraints**: voice (no `just/simply/obviously/effortless/magical/revolutionary/blazing`; no first person
  outside the stories' Connextra "I want"; no exclamation/emoji; no perceptual verb on a software component); ground
  only in REAL artifacts (cite a real file/module/script, or write the rung's own future modules forward-looking
  "`<rung>` builds", never asserted present); use the chapter's **closed error set verbatim** and add no new reason
  (a resource-side helper returns a plain atom, not the error struct); balanced code fences; **all relative links
  resolve** (link only its own `<rung>.*` siblings + `<chapter>.md` + the approach doc + real external URLs — do NOT
  link a concurrent-wave sibling rung; reference other rungs by **id/name**, the orchestrator links them in Step 4);
- **NEVER run git**; edit **ONLY** its three `<rung>.*` files; do NOT touch the chapter docs or any other rung.

## Step 3 — Adversarially verify (do NOT trust the agents' "all pass")

Run the `specs.approach.md` gates over every new file. A Python sweep is cleanest (it counts fences and resolves links
without shell-quoting hazards):

- **Structure** — each `<rung>.md` has exactly 6 `## ` sections and exactly 5 `^- \*\*(Why|What|Who|When|Where)\*\*`
  bullets; the DoD is checkboxes.
- **Voice** — no `\b(simply|obviously|effortless|magical|revolutionary|blazing[ -]?fast)\b` and no stray `\bjust\b`
  across all files; first person only inside the stories' "I want". **Strip the story-id tokens first** (`[US:…]`,
  `<rung>-US#`, `-US#`): `\bus\b` collides with the `US` id prefix and false-positives the first-person check. And the
  index/roadmap/contract that *document* the forbidden-word list (a "Voice." conventions bullet enumerating
  `revolutionary`/`magical`/`simply`/…) are expected hits, not defects — read the line before flagging.
- **Fences** — an even count of ```` ``` ```` per file.
- **Traceability** — Coverage line present; **flatten whitespace before EVERY trace check**
  (`re.sub(r'\s+',' ',text)`, per file or per bullet) — the wrap gotcha hits not only `encodes <rung>-INV#` but also
  `[US: …]` and `[implements …]`, which routinely wrap to a bullet's last line, so a single-line regex false-negatives
  all three (a real run flagged "all 6 R# missing `[US:]`" that flattening proved present); every `INV#` defined in the
  spec is encoded by some story; every `R#` carries `[US:]`; every `AS#` carries `[implements]`.
- **Links** — every relative `](…)` resolves on disk from the chapter dir (`os.path.exists`), including cross-dir links
  to `../specs/…` and `../../redis-patterns/…`.
- **Closed-error discipline** — the chapter's `%…Error{}` reason set is unchanged (no rung silently added a reason);
  a resource-side helper returns a plain atom, not the error struct.

Fix any defect yourself, deterministically (do-no-harm — change only what is wrong), then re-run the sweep.

## Step 4 — Sync the chapter docs (ORCHESTRATOR-ONLY)

In `<chapter>.md` and `<chapter>.roadmap.md`, for each newly-authored rung: link its feature cell to its `<rung>.md`
and flip its **Status** `planned`/`—` → `specced` in the value ladder; update the roadmap's **Status** line to name
the now-authored triads (e.g. "RL1–RL6 are all SPECCED (every triad authored), none built"). Re-run the links gate on
the two chapter docs — every rung link must resolve. These two files are the chapter's manifest; the fan-out agents
never touch them, so this relink is yours.

## Step 5 — Report

Summarise: the files authored (chapter docs + per-rung triads), the gate tally (structure/voice/fences/traceability/
links), any defect you fixed (especially an invented invariant, a broken closure, or a silently-widened error set), the
status relink, and the **resume point** (the lowest rung ready to build, from its `.llms.md` prompt). Note whether a
dedicated spec agent was used or the general-purpose fan-out. **Do not commit** — the operator commits batches
out-of-band; never `git add`/`commit`/`restore`, and the spawned agents must not either.

---

> The split that makes this work: the orchestrator owns the **design** (the chapter docs + the exemplar rung +
> each rung's fixed deliverables/invariants); the fan-out owns the **mechanical application** of that design to the
> template. Decisions are never delegated; template-filling always is.
