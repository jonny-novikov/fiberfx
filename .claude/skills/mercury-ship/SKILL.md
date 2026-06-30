---
name: mercury-ship
description: >-
  Use this skill to ship ONE spec-driven rung of MERCURY — the token-driven, presentational React design
  system in the pnpm monorepo at mercury/ (packages @mercury/core · @mercury/ui · @mercury/effector, apps
  under mercury/apps/*) — any rung whose slug matches mx.* (mx.1 … mx.N), OR to RECONCILE a Mercury spec
  triad against the as-built code. It is /x-mode with the Mercury context pre-loaded, run LIGHT (Mercury is
  a focused design-system program, not the full Venus/Mars/Apollo lead-team): it binds the laws to the
  Mercury ISLAND — the packages/* boundary, the @mercury/ui barrel master-invariant, the hand-authored
  <Name>.prompt.md contract law (D-7), the pnpm --filter gate ladder, and the mercury/… pathspec commit —
  and SCOPES OUT the rest of the jonnify monorepo (echo/ html/ elixir/ go/ infra/ node/ tradex/ mcp/ bin/
  scripts/ memory/ — everything except docs/ and mercury/). The INPUT is the rung's
  docs/mercury/specs/<rung>/ triad; the canon is docs/mercury/mercury.design.md + mercury.roadmap.md; the
  workflow is docs/aaw/aaw.framework.md + the contract-set method docs/aaw/aaw.architect-approach.md.
  Triggers: "ship mx.2", "mercury-ship <rung>", "reconcile mx.N", "run/launch the mx.N pipeline", "as
  Director ship the Mercury rung". Do NOT use for the echo_mq bus (/echo-mq-ship), the codemojex game
  (/codemojex-ship), the echo_graft engine (/graft-ship), the static-HTML courses (the *-course-writer
  skills), or generic documents.
argument-hint: <rung> (mx.1 … mx.N) · "reconcile <rung>" (spec↔code differ; append "post" for as-built→spec) · empty (the next unshipped rung per the roadmap)
---

# MERCURY-SHIP — ship a Mercury design-system rung via the LIGHT supervised loop

Ship ONE spec-driven rung of **Mercury** — a structural rung (`mx.1`), the contract layer (`mx.2`), or a
Storybook rung (`mx.3+`) — end to end through the AAW loop, Director-supervised, to one ratifying **commit
when the Operator asks**. It is **`/x-mode` with the Mercury context pre-loaded, run LIGHT**: it adds nothing
to the laws — it binds them to the Mercury island so the run does not re-derive them, and it trims the
ceremony because Mercury is a focused design-system program, not the full lead-team.

**It is a binding layer, not a re-implementation.** Defer to the sources of truth:

1. **`.claude/commands/x.md` + the `/x-mode` skill** — the LAWS (CLAUDE_LAWS 1/1a/2/3/4), the pipeline
   (architect reconcile/author + Arms → Director rules the Arms via `AskUserQuestion` → implementor build +
   self-verify → Director verify → implementor harden → Director ship; the verifier on a high-risk rung), the
   §5 spawn protocol, the §6 audit tools, the §10 commit rules. **Read the `/x-mode` skill first** —
   everything in it applies; the deltas below are the Mercury binding, and the topology router (§ below)
   collapses it to a Duo/Trio for most rungs.
2. **The AAW framework** — `docs/aaw/aaw.framework.md` (the loop, the roles, the rung, the standing laws) +
   the architect's two instruments `docs/aaw/aaw.architect-approach.md` (forks + **the contract set** — the
   method for hand-authoring `<Name>.prompt.md` as hypotheses that feed each other). The contract format note
   is `docs/mercury/contracts.md` (the frozen `D-7` template).
3. **The Mercury canon + the rung's spec** — `mercury/CLAUDE.md` + the per-package `mercury/packages/*/CLAUDE.md`
   (the boundary, the gate, the laws), the canon `docs/mercury/mercury.design.md` (the topology, the token
   vocabulary, the `D-` decisions) + the single roadmap `docs/mercury/mercury.roadmap.md` (the `mx.N` ladder,
   the three Movements) + the dashboard `docs/mercury/mercury.progress.md`, and the rung triad under
   `docs/mercury/specs/<rung>/` (`<rung>.md` body **authoritative**, `.stories.md`, `.llms.md`). The operating
   manual is `docs/mercury/program/mercury.program.md`.

## Arguments & scope

```
$ARGUMENTS
```

- **A RUNG** — `mx.1` … `mx.N` → ship it through the loop. Internally the aaw `scope` (only if the rung goes
  Squad and stands up an aaw team) is the **dashed** slug (`mx-2`, never `mx.2` — `tool_x_*` / `TeamCreate`
  require `^[a-z0-9][a-z0-9-]*$`, and a dot split-brains the registry). The slug matches the on-disk ledger
  filename when one is kept.
- **`reconcile <rung>`** (optionally `… post`) → run the **reconcile mode** only (the § below): the spec↔code
  ground-truth differ over the rung's triad, no build. `post` = the as-built→spec direction.
- **Empty** → read `docs/mercury/mercury.roadmap.md` (the rung ladder) + `mercury.progress.md`, and ship the
  next **unshipped** rung in program order; if that is ambiguous, ask in plain text (do not guess a large scope).

## THE BOUNDARY — Mercury is an island in the jonnify monorepo (read this first)

The git root is **`jonnify`** (the PARENT), and it holds **≥10 unrelated programs** that share nothing with
Mercury but the directory: a Mercury rung must treat the rest of the tree as if it did not exist.

**IN bounds — the only places a Mercury rung reads, searches, or edits:**

- `mercury/**` — the design system + its apps (the build + edit surface). Specifically:
  - `mercury/packages/mercury-core/` · `mercury/packages/mercury-ui/` · `mercury/packages/mercury-effector/` —
    the three design-system packages (the edit surface for a component/package rung).
  - `mercury/apps/{showcase,echomq,mobile,catalogue,docs}/` — the five composing apps (grounding for
    contracts + the `apps/*` build gate; **apps only compose — never house a reusable component**).
  - `mercury/codemojex-node/apps/{economy,api}/` — a sub-workspace whose `economy` app is a grounding source;
    **its build state is independent and may be broken** — never let it into the gate (use `--filter`, below).
- `docs/mercury/**` — the canon, the program manual, the specs (`docs/mercury/specs/<rung>/`).
- `docs/aaw/**` — the workflow framework + the architect's contract-set method (**read-only reference**).
- `/Users/jonny/.claude/projects/-Users-jonny-dev-jonnify/memory/` — the agent memory index (background only).

**OUT of bounds — DO NOT read, `Glob`, `Grep`, `find`, build, or touch (everything else in the root):**

```
echo/   html/   elixir/   go/   infra/   node/   tradex/   mcp/   bin/   scripts/
github.local/   temp.local/   memory/   …and any other top-level dir that is not docs/ or mercury/
```

`echo/` is the **echo_mq / BCS Elixir stack** (a different language, owned by `/echo-mq-ship` & friends);
`html/` `elixir/` are the static-HTML courses; `go/` is the agent-OS; the rest are infra/vendor. **A Mercury
agent that greps the whole root burns tokens on Elixir/Go/HTML it can never use, and risks a cross-program
edit no one can review.** Enforce it mechanically:

- **Every `Glob`/`Grep`/`find` roots at `mercury/` or `docs/mercury/`** — never a bare search from the jonnify
  root. (`Grep` with `path: "mercury"`, `find mercury/… `, `Glob` `mercury/**`.)
- **The gate uses `pnpm --filter`, never a blind `pnpm -r`** — `-r` walks into the `codemojex-node`
  sub-workspace (sometimes-broken) and is the wrong scope.
- **The commit is a `mercury/…` (and `docs/mercury/…`) pathspec** — re-verify `git diff --cached --name-only`
  is purely Mercury before committing (the §LAW below).
- **`TMPDIR=/tmp` is an Elixir-only rule — it does NOT apply here.** Mercury is Node (≥22) + pnpm (≥10.17).

## Navigate the island (where everything lives)

| Need | Path |
|---|---|
| UI-free foundation (headless hooks, `cx`/`date`/`types`, the reuse barrel) | `mercury/packages/mercury-core/src/` |
| The component library, grouped Claude-Design-way | `mercury/packages/mercury-ui/src/components/<group>/<Name>/` |
| **The public barrel (the master invariant)** | `mercury/packages/mercury-ui/src/index.ts` |
| The tokens (the `.mx-*` recipes + `--token` vars) | `mercury/packages/mercury-ui/src/styles/` |
| State adapters (theme · toast · form · strength · cooldown) | `mercury/packages/mercury-effector/src/` |
| The composing apps (contract grounding + the `apps/*` build gate) | `mercury/apps/*/src/` + `mercury/codemojex-node/apps/economy/src/` |
| The app vite aliases (`@mercury/*` → source) | `mercury/apps/*/vite.config.ts` + `tsconfig` paths |
| The canon / ladder / dashboard | `docs/mercury/mercury.{design,roadmap,progress}.md` |
| The contract format note (`D-7` template) | `docs/mercury/contracts.md` |
| The rung's spec triad | `docs/mercury/specs/<rung>/<rung>.{md,stories.md,llms.md}` |
| The workflow + the contract-set method | `docs/aaw/aaw.framework.md` + `docs/aaw/aaw.architect-approach.md` |
| The generated design-sync seeds (WRITE-ONLY, regenerable; **never the contract source**) | `mercury/ds-bundle/` + `mercury/.design-sync/` |

## What is different from a generic /x-mode run (the Mercury binding)

- **The team is GENERIC and LIGHT.** There are no `mercury-*` role skills. Spawn each peer
  `subagent_type: "general-purpose"` and adopt its `.claude/agents/<role>.md` charter, mapped to the AAW-light
  roles (`docs/aaw/aaw.framework.md`):
  - **the architect / spec-steward** = `venus` — reconciles the triad lag-1 against as-built `mercury/`,
    authors the build brief, frames forks as four-part Arms (Rationale/5W/Steelman/Steward), and **authors the
    contract set** (the `<Name>.prompt.md` hypotheses — the method is `aaw.architect-approach.md`). Edits ONLY
    the spec triad + the co-located contracts.
  - **the implementor** = `mars` — builds to the brief inside `mercury/packages/*`, cites the spec/source for
    every public call, invents nothing, runs the gate. Two-pass (build, then harden). Edits code + tests + the
    co-located contracts, never the spec body.
  - **the verifier + team mentor** = `apollo` — re-runs the gate, reconciles spec↔code (post), renders
    BUILD-GRADE / BLOCKED. **Mandatory as the in-pipeline verifier only on a high-risk rung** (below); but
    **on EVERY rung Apollo is the team's standing MENTOR** (Operator-directed) — after the ship it folds the
    rung's craft / contract / **spawn-resilience** findings forward into `.claude/agents/{venus,mars}.md` + the
    retrospective (one guardrail per recurring finding, Director-ratified, PROPOSE-ONLY; the harness fences a
    peer's self-edit, so Apollo proposes the diff and the Director applies it). On a normal rung that is a
    short, post-ship, read-only mentoring pass — never skipped.
  The peers self-register via `mcp__aaw__agent_register` from their own context (LAW-1; no narrated spawns).
  The "## The Mercury facts" block below is the pre-loaded context they would otherwise re-derive.
- **Spawn resilience — the write-ready dispatch (x.md §5 LAW-1b).** A spawned peer dies to `ECONNRESET` on a
  long, read-heavy run (files on disk survive; the final report does not). So the Director **pre-grounds** every
  dispatch — front-load the exact signatures, file paths, the import convention, a usage sketch, and the gate
  into the spawn prompt (or the Venus brief) so the peer's FIRST actions are writes, not a subsystem read; cap
  its required reading at ≤2–3 named files. **Split a heavy component into short sequential waves** (the mx.7.2
  "two waves" precedent — e.g. a date component = wave 1 the `@mercury/core` composable, wave 2 the
  `@mercury/ui` home), each peer skeleton-first + heart-beating per file. When a spawn dies, **recover from the
  tree** (read the on-disk files), never the lost message. The Director (resilient main loop) absorbs the heavy
  grounding read; the peer still writes the code (LAW-1a holds).
- **The boundary is `mercury/packages/*`** — `mercury-core` / `mercury-ui` / `mercury-effector` — **plus** the
  `mercury/apps/*/vite.config.ts` (+ `tsconfig` paths) aliases when a package rung adds or moves a package. A
  reusable component lands ONLY in a package; an app only composes. A change reaching outside `mercury/` (any
  OUT-of-bounds dir above) is a diff no one can review — STOP and re-scope.
- **The master invariant binds every rung: the `@mercury/ui` public export surface holds.** Every name
  exported from `mercury/packages/mercury-ui/src/index.ts` before a rung is still exported after it —
  **additions OK; removals/renames NOT**. The mechanical check is the **barrel-diff**, and because the barrel
  is `export * from "./components/…"`, a **text-diff of `index.ts` is INSUFFICIENT** — resolve the full export
  name set:
  ```bash
  # fast first-line check (the re-exported names that ARE spelled in the barrel):
  diff <(git show HEAD:packages/mercury-ui/src/index.ts | grep -oE 'export .*') \
       <(grep -oE 'export .*' packages/mercury-ui/src/index.ts)
  # authoritative when export * is in play — resolve the real export set from the built types
  # (TS getExportsOfModule, or introspect packages/mercury-ui/dist/index.d.ts after a build): 0 removed/renamed.
  ```
  An additive rung adds export lines; a removal/rename is a **breaking change → STOP and surface to the
  Operator** (the canon §2 / `mercury/CLAUDE.md`).
- **The contract law (`D-7`).** Every `@mercury/ui` component carries a co-located, **hand-authored**
  `<Name>.prompt.md` — the six-section shape in `docs/mercury/contracts.md`, grounded in three truths (the
  `.tsx` source · real call sites in `apps/showcase` + `economy` · the sibling contracts it cross-links). A
  generated design-sync stub (in `ds-bundle/`) is a **seed for the prop list only**, never the contract — drop
  the `window.MercuryUI` / `_ds_bundle` runtime framing. A rung that adds/changes a component **adds/updates
  its contract in the same change** (a `.tsx` whose prop set drifts from its `.prompt.md` is a reconcile delta).
- **Token discipline.** Style components through enum props; style layout with `rgb(var(--token))`; never
  author the private `.mx-*` classes or reach for a utility-class framework (canon §6). A contract names the
  **token family** (`--bg-brand`, the status families) an enum resolves to, never a raw hex/RGB.
- **The gate ladder is the Mercury one, run from `mercury/`** (NEVER a blind `pnpm -r`). Hold each stage
  against it (`mercury/CLAUDE.md` · `docs/mercury/program/mercury.program.md`):
  ```bash
  pnpm --filter "./packages/*" typecheck     # every package clean
  pnpm --filter "./packages/*" build         # every package builds
  pnpm --filter "./apps/*" build             # all 5 apps build (resolve @mercury/* from source via alias)
  # barrel-diff (above) — the @mercury/ui export name set: 0 removed/renamed
  ```
  Node ≥22, pnpm ≥10.17. **No `TMPDIR=/tmp`** (Elixir-only). A docs/contract-only rung (e.g. `mx.2`) adds **no
  export and must not perturb `tsc`/`vite`** — the gate proves the build is undisturbed, plus the
  contract-coverage + no-extractor-framing checks in `mx.2.llms.md`.
- **The risk tier decides the verify depth + the formation** (below). A barrel-touching restructure, a
  package-topology move (extract/rename/delete a package), a component deletion/rename, or a token-pipeline
  change is **high-risk** → Squad, verifier mandatory, the Director's verify deepens (the full barrel-diff via
  the resolved export set + a mutation spot-check). A docs/contract rung or an additive component is **normal**.

## Topology router — right-size the LIGHT formation (rigor constant, ceremony scales)

The formation is **routed, not habitual**. Mercury is light, so most rungs are a Duo or a Trio:

| Formation | Active roles | Use when |
|---|---|---|
| **Duo** | Director + **one** peer | A single-concern increment — a **docs/contract-only rung** (`mx.2`: Director + the architect, fanning out contract authors in waves), a pure spec author or **reconcile**, or an already-green rung needing only the independent verify. |
| **Trio** | Director + architect + implementor *(two-pass)* | The standard **component / package rung**: architect reconcile/author + Arms → Director rules → implementor build + self-verify → Director verify → implementor harden. The Director's solo verify is the gate; no dedicated verifier. |
| **Squad** | Director + architect + implementor(-1/-2) + **verifier** | The **HIGH-risk** rung (a barrel-touching restructure, a package extract/rename/delete, a component delete/rename, a token-pipeline change). Adds the dedicated verifier (post-build reconcile + adversarial barrel-diff + BUILD-GRADE) + the deepened verify. |

**Apply at Bootstrap (§0), before any spawn:** floor by risk (HIGH → Squad, verifier mandatory); collapse by
build-state (a built-and-green increment re-spawns **no builder** — only the remaining verify/harden/ship legs).
If the rung stands up an aaw team, `mcp__aaw__status(scope)` must then show EXACTLY the chosen tier's peers.
A Duo contract/reconcile rung needs **no aaw team at all** — the Director + one architect agent (or direct
authoring) is the whole formation.

## The contract fan-out (the `mx.2` shape, and any contract-heavy rung)

When the deliverable is the **contract set** (authoring many `<Name>.prompt.md`), the architect lands the
**exemplar pair + the format note first** (`docs/mercury/contracts.md` + the `actions/Button` ↔
`foundations/Icon` exemplars), then fans out **author agents in waves, ≤2 heavy authors concurrent** (the AAW
cadence — `aaw.architect-approach.md` "author the exemplar first, then fan out"). Each author agent:

- is `general-purpose`, scoped to **one group**, and reads `docs/mercury/contracts.md` + the exemplars + the
  per-component grounding inventory in `docs/mercury/specs/mx.2/mx.2.llms.md` (the real prop usage, captured);
- grounds every prop against the **live `.tsx`** (not the `ds-bundle/` seed), every example against a **real
  call site** (cited), and cross-links siblings by **real relative path**;
- emits **docs only** — no export, no `.tsx` edit (INV-1 forbids removals/renames, not additions; a contract
  perturbs neither `tsc` nor `vite`).

The Director **reconciles + gates each wave** (the coverage count, the no-extractor-framing grep, the
cross-link resolution, the undisturbed build) before launching the next.

## The reconcile mode (`mercury-ship reconcile <rung>` — bind `/reconcile`)

The spec↔code ground-truth differ, Mercury-grounded. Run the generic `/reconcile` algorithm
(`.claude/commands/reconcile.md`) with the claim-extraction tuned to Mercury surfaces:

- **`@mercury/ui` exports** the spec names → exist in the resolved barrel export set (the master invariant)?
- **Every prop** in a `<Name>.prompt.md` table → exists in `<Name>.tsx` with the documented type + default?
- **Every cross-link** (`Composes` / `Composed by`) → resolves to a real co-located `.prompt.md`?
- **Every `## Examples` snippet** → is a real usage at the cited call site in `apps/showcase` / `economy`?
- **The component→group mapping** in the canon §4.1 → matches the filesystem under `components/<group>/<Name>/`?

Classify each as `MATCH` / `STALE` / `INVENTED` / `MISSING` / `DEFERRED`; emit the delta table (claim →
`file:line` → verdict) + the numbered correction work-order + the **BUILD-GRADE / BLOCKED** verdict.
**Pre-build** (default) = the architect's lag-1 step before building rung N. **`post`** = the verifier's
close gate after building (catches the build drifting from the contract). **Apply corrections only with an
explicit `apply` ask** — otherwise report and let the architect apply (never edit a spec the same turn you
judge it). The reconcile mode is a **Duo** (Director + one architect, or direct) — it builds nothing.

## The Mercury facts (the pre-loaded context for the peers)

- **The three packages** (canon `mercury.design.md`): `@mercury/core` (UI-free foundation — headless hooks,
  the reuse barrel, `cx`/`date`/`types`; **zero JSX**; React a peer; source-consumed) → `@mercury/ui` (the
  component library, Claude-Design grouped; tokens live here; builds to `dist/`) + `@mercury/effector`
  (Effector state adapters — theme · toast · `createForm` · strength · cooldown; components stay
  presentational). Apps resolve all three **from source** via a vite alias + tsconfig `paths` — a package edit
  is live in dev, no prebuild.
- **The component library** — **33 components across 9 groups** under
  `mercury/packages/mercury-ui/src/components/<group>/<Name>/` (each `<Name>.tsx` + `index.ts` + the
  hand-authored `<Name>.prompt.md`): `actions` (Button · Link) · `foundations` (Icon · Divider) · `inputs`
  (Input · Textarea · Search · Select · AuthCode) · `selection` (Checkbox · Radio · Switch · Segmented ·
  Slider · Toggle) · `feedback` (Alert · Progress · PasswordStrength) · `data-display` (Chip · Tag · Badge ·
  Avatar · Card · Table · Stat · Chart · Checklist) · `navigation` (Tabs · Accordion · Pagination) · `overlay`
  (Modal · Tooltip) · `layout` (AuthLayout). **NO-INVENT:** ground every component / prop / token in a real
  `.tsx` or a canon §; forward-tense ("mx.N adds …") for an unshipped surface.
- **The three Movements** (`mercury.roadmap.md`): **I** — modular foundation & Claude-Design structure
  (`mx.0` docs ✅, `mx.1` the structural rung ✅ BUILT — `@mercury/core` extracted, `mercury-ui` regrouped,
  `mercury-ds` deleted). **II** — **the authored contract layer** (`mx.2`: hand-author every component's
  `<Name>.prompt.md`). **III** — the Design System Storybook (`mx.3` host → `mx.4` component stories → `mx.5`
  effector stories → `mx.6` build/deploy + design-sync reconcile). Re-sequencing is Operator-ruled.
- **The decisions** (`mercury.design.md` §7): `D-1` core scope = utils/types/hooks only · `D-2` `mercury-ds`
  ephemeral → salvaged then deleted · `D-3` core source-consumed, React a peer · `D-7` the hand-authored
  contract (the 6-section shape) · `D-8` the app/library split ratified (marginal candidates kept internal).
- **The git posture.** The root is `jonnify`; the Operator pre-stages out-of-band, so the tree is routinely
  entangled with sibling programs. The rung commit is the rung's **measured surface ONLY**.

## 0. Bootstrap (Director, before any spawn)

Read the rung's spec triad + the canon `mercury.design.md` + the roadmap + the program manual + `mercury/CLAUDE.md`
(+ the per-package `CLAUDE.md` the rung touches) + **the `/x-mode` skill** + `docs/aaw/aaw.framework.md`
(+ `aaw.architect-approach.md` for a contract/fork rung). **Confirm every search/read so far stayed inside the
island** (§Boundary). Declare the mode (**AAW-light**) and **triage the topology router** (Duo / Trio / Squad)
from the rung's **risk tier × build-state**, recording the chosen tier as the formation decision. Deep-reason
the rung (the `/x-mode` §0: the 5W, the solution space incl. a do-nothing baseline, the invariants as runnable
gates — the barrel-diff, the contract-coverage, the undisturbed build — the smallest change that preserves
correctness). **Confirm the Stage-1 gate is reachable** — the triad exists (or the architect authors it) and any
**open Operator fork is resolvable**; a fork the architect must FRAME first is ruled in-pipeline (Stage 1 → the
mandatory `AskUserQuestion`); a fork that blocks even starting → **STOP and `AskUserQuestion`** now.

## 1. Run the pipeline (per `/x-mode`, Mercury-bound & light-collapsed)

For a **Squad** rung, stand up the aaw team per `/x-mode` §1 (`mcp__aaw__init` → spawn+register the `director`
→ `TeamCreate(<dashed-scope>)` → open the ledger if one is kept). For a **Duo / Trio**, the lighter loop is
enough — the Director spawns the one or two peers directly. **zsh does not word-split unquoted vars** — iterate
file lists with `find … -print0 | while IFS= read -r -d '' f`, never `for f in $files`.

Lift each stage's directive from the rung's `.llms.md` (or the Stage-1 architect brief); wrap each spawn in the
`/x-mode` §3 per-spawn ceremony + "Read and operate by `.claude/agents/<role>.md`; stay inside the Mercury
island (§Boundary of `/mercury-ship`); the gate is `pnpm --filter`, never `pnpm -r`."

**Architect** (reconcile the triad lag-1 against the as-built `mercury/` tree via the reconcile mode, or author
it; author the build brief — the agent stories, the touched paths, the gate, the smallest-change build order;
on a contract rung, author the exemplar + format note then fan out the contract waves; frame seam/placement
forks as four-part Arms) → **Director rules the Arms** (the mandatory `AskUserQuestion` — a fork is never
decided silently) → **Implementor-1** (build to the brief inside `mercury/packages/*` — move-don't-rewrite where
a rung relocates code; the real `@mercury/*` surface only, **no invented prop or export**; add/update the
co-located `<Name>.prompt.md`; run the gate) → **Director verify** (a REAL pass: a fresh reconcile + an
**independent gate re-run** — `pnpm --filter` typecheck + build + apps + the **barrel-diff via the resolved
export set** — + ≥1 adversarial probe + a **mutation spot-check**: Edit-in → typecheck/build-catches → revert →
`git diff --stat` clean **net-zero**, LAW-1a) → **Implementor-2** (resume the same identity — remediate +
harden + the full gate; REMEDIATE loop MAX 3) → **Verifier** *(HIGH-risk only)* (the post-build reconcile +
the adversarial barrel-diff + a mutation kill-rate; resolve every ambiguity with the Operator via
`AskUserQuestion`; spec-sync; **BUILD-GRADE / BLOCKED**) → **Director ship** (the solo ship-gate + the commit
when asked + the record fold). On a NORMAL rung the verifier is out of the pipeline (it mentors after the ship).

## 2. The commit (Director-only, per x.md §10 — only when the Operator asks)

**Commit only when the Operator asks.** At ship: the Director's verify clean + the Mercury gate green (+ on a
HIGH rung, the verifier BUILD-GRADE); `git status --short` AND `git diff --cached --name-only` reviewed;
`.git/rebase-merge` / `rebase-apply` checked. Then a **pathspec** commit — `git add <explicit rung paths>` then
`git commit -F <msg> -- <those paths>`; **NEVER `git add -A`, NEVER a bare commit** (the git root is `jonnify`;
the Operator pre-stages out-of-band). The rung commit is the rung's **measured surface ONLY** —
`mercury/packages/**` (+ the `mercury/apps/*/vite.config.ts` aliases a package rung moved) + the co-located
`mercury/packages/mercury-ui/src/components/**/<Name>.prompt.md` + the rung's `docs/mercury/` triad/reconcile +
the `docs/mercury/mercury.{roadmap,progress,design}.md` fold. **When the tree is entangled** (a sibling-program
edit, staged infra), commit those as **separate scoped commits per concern** so the Mercury commit stays a
faithful record of exactly the rung. The message ends with the `Co-Authored-By: Claude Opus 4.8` trailer. **Do
not push unless asked.** **Record fold:** flip the rung's status in `docs/mercury/mercury.roadmap.md` (+
`mercury.progress.md`), backward-reconcile the rung `.md` to the green as-built surface, and surface the next
frontier.

## 3. Quality gate (before ship)

- [ ] The triad + the canon + the roadmap + `mercury/CLAUDE.md` + the `/x-mode` skill + `aaw.framework.md` read;
      mode declared AAW-light; the topology tier triaged + recorded.
- [ ] **Every read/search/edit stayed inside the island** — `mercury/**` + `docs/mercury/**` + `docs/aaw/**`
      only; no OUT-of-bounds dir (`echo/ html/ elixir/ go/ infra/ node/ tradex/ …`) was touched.
- [ ] Every peer is a REAL self-registered `Agent` spawn (`general-purpose` + the venus/mars/apollo charter; no
      FAKE-N); the Director called no Edit/Write on production code EXCEPT a mutation spot-check reverted
      **net-zero** (LAW-1a); every design Arm was ruled via `AskUserQuestion` before the build.
- [ ] The Mercury gate is green, run from `mercury/`: `pnpm --filter "./packages/*" typecheck` + `build` +
      `pnpm --filter "./apps/*" build` + the **barrel-diff (resolved export set): 0 removed/renamed**; on a
      contract rung, the coverage count matches + the no-extractor-framing grep is clean + the build is
      undisturbed. **No blind `pnpm -r`.**
- [ ] The boundary holds: only `mercury/**` (+ co-located contracts) + the rung's `docs/mercury/` changed; the
      package/app split is intact (no reusable component in an app); apps resolve `@mercury/*` from source.
- [ ] Commit (if asked): exactly one Director pathspec commit **per concern**; nothing foreign in `--cached`;
      the canon fold landed.
- [ ] (Squad) `mcp__aaw__status(scope)` shows EXACTLY the chosen topology tier's peers (no FAKE-N).

## 4. Map

- The laws + pipeline: `.claude/commands/x.md` + the `/x-mode` skill. The reconcile differ:
  `.claude/commands/reconcile.md`. The charters the peers wrap: `.claude/agents/{venus,mars,apollo}.md`.
- The workflow + the architect's two instruments (forks + the contract set): `docs/aaw/aaw.framework.md` +
  `docs/aaw/aaw.architect-approach.md`.
- The Mercury boundary + gate + laws: `mercury/CLAUDE.md` + the per-package `mercury/packages/*/CLAUDE.md`.
- The canon + the single roadmap + the dashboard + the contract format: `docs/mercury/mercury.design.md` ·
  `docs/mercury/mercury.roadmap.md` · `docs/mercury/mercury.progress.md` · `docs/mercury/contracts.md`.
- The operating manual: `docs/mercury/program/mercury.program.md`.
- The specs (source of truth): `docs/mercury/specs/<rung>/<rung>.{md,stories.md,llms.md}`.
- The code (the boundary): `mercury/packages/{mercury-core,mercury-ui,mercury-effector}/` + the composing
  `mercury/apps/*/` + `mercury/codemojex-node/apps/economy/`.
