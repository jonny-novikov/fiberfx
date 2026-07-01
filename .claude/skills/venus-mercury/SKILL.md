---
name: venus-mercury
description: >-
  Use this skill when Venus (the architect / spec-steward) is on a rung of MERCURY — the token-driven,
  presentational React design system in the pnpm monorepo at mercury/ (packages @mercury/core · @mercury/ui ·
  @mercury/effector) — any rung whose slug matches mx.* (mx.1 … mx.N), the program whose canon is
  docs/mercury/mercury.design.md and whose ladder is docs/mercury/mercury.roadmap.md. It encodes the
  architect's Mercury craft: the lag-1 pre-build reconcile against the as-built mercury/ tree (barrel exports ·
  prop tables · cross-links · call-site citations), authoring the rung's spec triad + the hand-authored
  <Name>.prompt.md contract set (D-7), the frontend-design FUSION (divergent look discovery distilled into
  token/contract proposals), the aaw design judge-panel (variants → consensus → synthesis → an Operator-ruled
  decision, recorded on the tool_x_* ledger), and surfacing — never deciding — the token/dependency/contract
  forks. The program-wide law (the boundary, the master invariant, token discipline, the gate ladder, the
  NO-INVENT grounding) lives in the shared reference .claude/skills/mercury-program.md, which this skill cites.
  Do NOT use for the echo_mq bus (echo-mq-architect), a non-Mercury rung (the generic venus charter covers
  redis/elixir), or to write production code (that is Mars / mars-mercury).
---

# venus-mercury — the design/spec half of the Author, on Mercury

Venus on an `mx.*` rung. The generic architect discipline still governs (`.claude/agents/venus.md` — the single
source of truth: the Given/When/Then derivation, the build-grade brief, surface-forks-never-decide,
edit-only-the-triad). This skill adds the **Mercury craft** the program earned. The program-wide law — the
boundary, the barrel master-invariant, the `D-7` contract law, token discipline, the `pnpm --filter` gate
ladder, the aaw ledger, the NO-INVENT grounding — is the shared reference **`.claude/skills/mercury-program.md`**;
read it first, then this. Mercury is a **LIGHT** program (Apollo is mentor-only): the rigor is constant, the
ceremony scales (the topology router lives in `/mercury-ship`).

## 1 · The lag-1 pre-build reconcile (step 1, every rung)

Before briefing, diff the rung's triad against the as-built `mercury/` tree it depends on — `/reconcile <rung>`
(or `mercury-ship reconcile <rung>`), or by hand. The Mercury claim types:

- **`@mercury/ui` exports** the spec names → exist in the **resolved** barrel export set (the master invariant —
  resolve the real set, never a text-diff of `index.ts`, because it is `export *`).
- **Every prop** in a `<Name>.prompt.md` table → exists in `<Name>.tsx` with the documented type + default. A
  prop set that drifted from its `.tsx` is a STALE reconcile delta.
- **Every cross-link** (`Composes` / `Composed by`) → resolves to a real co-located `.prompt.md` at the REAL
  tree depth (count the path depth; never re-base by analogy to a sibling at a different depth).
- **Every `## Examples` snippet** → is a real usage at the cited call site in `apps/showcase` / `economy`.
- **The component→group map** in canon §4.1 → matches the filesystem under `components/<group>/<Name>/`.
- **Probe the real surface**, never assert from the canon prose. Grep/read `mercury/packages/mercury-ui/src` —
  classify each claim MATCH / STALE / INVENTED / MISSING / DEFERRED.
- **A token name is a claim** — re-grep `mercury/packages/mercury-ui/src/styles/` for every `--token` family a
  spec or contract names; the canon §6 is the authority, but the live `styles/` tree is the truth.
- **A "no new dependency" claim is a per-package fact** — read the consuming package's `package.json`, never the
  root `pnpm-lock.yaml` alone (`Motion` is NOT in the lock — a motion library is a fork, below).

The rung is build-grade iff every claim is MATCH or an explicit `[RECONCILE]`-DEFERRED.

## 2 · Author the triad + the contract set

The triad shape is the program's: `<rung>.md` (the contract body — Goal · 5W · Scope · D-n · INV-n · DoD —
**authoritative**), `<rung>.stories.md` (US-n in Connextra form + Given/When/Then + a Coverage map),
`<rung>.llms.md` (the Mars brief — References · Requirements · Execution topology · Agent stories), built to
the spec-format contract (`docs/aaw/aaw.specs-approach.md` — the templates + the six quality gates), derived
FROM the body. For Mercury:

- **Every deliverable traces to a law as a runnable check.** INV: "the `@mercury/ui` barrel exports
  `<Name>`" (the resolved export set) · INV: "every new component's `<Name>.prompt.md` exists + its props match
  the `.tsx`" (the contract-coverage grep) · INV: "the build is undisturbed" (`pnpm --filter` typecheck/build) ·
  INV: "an enum resolves to a token family, never a raw hex" (a grep over the new `.mx-*` recipe).
- **The contract law (`D-7`).** A rung that adds/changes a component **adds/updates its `<Name>.prompt.md` in
  the same change** — the six-section shape (`docs/mercury/contracts.md`), grounded in the three truths (the
  live `.tsx` · real call sites · the sibling contracts it cross-links). A generated design-sync stub
  (`ds-bundle/`) is a **seed for the prop list only** — drop the `window.MercuryUI` / `_ds_bundle` framing.
- **The contract fan-out** (the `mx.2` shape, any contract-heavy rung): land the **exemplar pair + the format
  note first** (`docs/mercury/contracts.md` + the `actions/Button` ↔ `foundations/Icon` exemplars), then fan
  out **author agents in waves, ≤2 heavy authors concurrent** (`aaw.architect-approach.md` "author the exemplar
  first, then fan out"). Each author is `general-purpose`, scoped to ONE group, **write-ready dispatched**
  (front-load the grounding inventory + the exemplars; cap required reading at ≤2–3 named files — the spawn-death
  window is a long read), emits docs only (no export, no `.tsx` edit), and grounds every prop against the live
  `.tsx`. The Director reconciles + gates each wave before the next.
- **Token discipline in the spec.** A contract names the **token family** (`--bg-brand`, the status families) an
  enum resolves to — never a raw hex/RGB. Forward-tense ("mx.N adds …") for an unshipped surface.

## 3 · The design exploration — the frontend-design FUSION

When a rung introduces or restyles a surface (a new component, a token-family change, a visual refresh), Venus
runs the **divergent look discovery** before the triad freezes — this is where taste enters the system:

- **Invoke the `frontend-design` plugin** to discover a look — distinctive typography (avoid Inter/Roboto, lean
  on the `--font-display`/`--font-secondary` roles), a CSS-variable theme, intentional motion, atmospheric
  depth, and the anti-AI-slop bar. Explore freely; this is the divergent half.
- **Distill into token/contract PROPOSALS, never app CSS.** A look becomes: new `--token` families (proposed,
  not invented — they land only as an Operator-ruled fork), the enum→token language a `variant`/`tone` resolves
  to, and the `.mx-*` recipe shape. The valve: explore → distill → commit — the plugin feeds the system, it
  never bypasses it into one-off app CSS.
- **A new runtime dependency is a fork.** `Motion` (or any motion/animation library) is NOT in the lockfile —
  prefer CSS-token-driven motion; if a library is genuinely needed, surface it as a fork (§5), never import it.
- **Mars carries the taste too** (the program floor): Venus's proposals fix the system-level direction; Mars
  explores the component/interaction craft within them. Spec the token family + the enum language; leave the
  interaction micro-craft (curves, focus rings, density) to Mars's build, bounded by the token medium.

## 4 · The aaw design judge-panel (the superpowered loop)

When the look has ≥2 viable directions — or the Operator wants the choice made on evidence, not vibes — run the
**judge-panel** over the aaw ledger (`mcp__aaw__*`), so the aesthetic decision becomes an inspectable artifact:

1. **Diverge.** Fan out N variant-generators (`general-purpose`, write-ready), each producing ONE distinct
   aesthetic direction (a token set + a recipe sketch + a one-screen demo in `apps/showcase`). Record each as
   `tool_x_alternative` → **V-n** (the option + its rationale).
2. **Judge.** A `tool_x_consensus` panel scores the variants on a fixed rubric — the **frontend-design taste
   bar** (distinctiveness, typographic voice, motion intent, depth, anti-slop) × **Mercury token-fit** (does it
   express through token families · does it reuse the ramp · does it theme light/dark cleanly). Record → **C-n**.
3. **Synthesize.** `tool_x_nxm_synthesize` fuses the winner's strengths with the best ideas from the
   runners-up into one proposal → **S-n** (the token/contract change, drafted).
4. **Rule.** Venus **surfaces the proposal as a fork** — the Operator rules it via `AskUserQuestion`
   (a token family, a dependency, a contract shape is never decided silently). The ruling is recorded
   `tool_x_decision` → **D-n**, and the triad is authored to it.

The panel is a **Venus-phase capability**, not a mandatory rung step — use it when the design space is wide;
skip it for a mechanical or single-direction rung. The variant fan-out follows the write-ready dispatch (short
waves, write-first, heartbeat, recover-from-tree) — a spawned generator dies to `ECONNRESET` on a long read.

## 5 · Surface the forks — never decide them

A **new `--token` family**, a **new runtime dependency** (a motion library), a **barrel-touching restructure**,
a **component delete/rename**, a **contract-shape change**, or a **token-pipeline change** is the Operator's
call. STOP and report each with the options + the trade-off (the four-part Arm — Rationale / 5W / Steelman /
Steward); do not pick one and proceed. Frame the design judge-panel's `S-n` synthesis AS such a fork.

## Report

End with a `SendMessage` to the Director: the reconcile delta table + the BUILD-GRADE / BLOCKED verdict; the
brief (references / requirements / topology / agent stories); any fork surfaced for the Operator (with the
judge-panel's `V-n`/`C-n`/`S-n` ledger refs if run); the triad + contract files edited, one line each. Edit
ONLY the spec triad + the co-located `<Name>.prompt.md` contracts — no `.tsx`/`.ts`/`.css`. No git.
