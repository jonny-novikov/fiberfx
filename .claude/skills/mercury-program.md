# mercury — the program law (shared reference)

The common law every Mercury dev skill cites. The role-specific craft lives in the two role skills
(`venus-mercury`, `mars-mercury`); this file is the program-wide floor both stand on. Read it once per `mx.*`
rung; the role skill points back here. It is an operational digest — the binding authority is the canon, which
this file points at, never overrides.

**Framing.** Third person for any agent reference; no gendered pronouns for agents; no perceptual or
interior-state verbs for agents or software — components render, resolve, refuse, return.

**TMPDIR=/tmp is an Elixir-only rule — it does NOT apply here.** Mercury is Node (≥22) + pnpm (≥10.17).

## The canon (read-first, NO-INVENT)

- **The design canon** — `docs/mercury/mercury.design.md`: the topology, the token vocabulary (§6), the `D-`
  decisions (§7), the component→group map (§4.1). Operator-ratified; reconcile-only.
- **The single roadmap** — `docs/mercury/mercury.roadmap.md`: the three Movements, the `mx.N` ladder, the
  master invariant. The dashboard is `docs/mercury/mercury.progress.md`.
- **The contract format note** — `docs/mercury/contracts.md`: the frozen `D-7` six-section `<Name>.prompt.md`
  template.
- **The boundary + gate + laws** — `mercury/CLAUDE.md` + the per-package `mercury/packages/*/CLAUDE.md`.
- **The operating manual** — `docs/mercury/program/mercury.program.md`.
- **The workflow** — `docs/aaw/aaw.framework.md` + the architect's two instruments (forks + the contract set)
  `docs/aaw/aaw.architect-approach.md`.
- **The taste plugin** — the model-invoked `frontend-design` skill (taste / aesthetics); how it feeds the
  system is the valve (below).

## The boundary — Mercury is an island in the jonnify monorepo

The git root is `jonnify` (the PARENT); it holds ≥10 unrelated programs that share nothing with Mercury but the
directory. A Mercury rung treats the rest of the tree as if it did not exist.

**IN bounds — the only places a rung reads, searches, or edits:**

- `mercury/**` — the design system + its apps:
  - `mercury/packages/{mercury-core,mercury-ui,mercury-effector}/` — the three packages (the edit surface).
  - `mercury/apps/{showcase,echomq,mobile,catalogue,docs}/` — the five composing apps (contract grounding +
    the `apps/*` build gate; **apps only compose — never house a reusable component**).
  - `mercury/codemojex/apps/{admin,economy,game,game-tauri}/` — the `@codemojex/*` sub-workspace (shipped by
    `/cm-ship`); `economy` is a grounding source, its build
    state is INDEPENDENT and may be broken — never let it into the gate (use `--filter`).
- `docs/mercury/**` — the canon, the manual, the specs (`docs/mercury/specs/<rung>/`).
- `docs/aaw/**` — the workflow framework + the contract-set method (read-only reference).

**OUT of bounds — DO NOT read, `Glob`, `Grep`, `find`, build, or touch (everything else in the root):**

```
echo/  html/  elixir/  go/  infra/  node/  tradex/  mcp/  bin/  scripts/  memory/  …and any other top-level
dir that is not docs/ or mercury/
```

Enforce it mechanically: **every `Glob`/`Grep`/`find` roots at `mercury/` or `docs/mercury/`** — never a bare
search from the jonnify root; **the gate uses `pnpm --filter`, never a blind `pnpm -r`** (which walks into the
sometimes-broken `codemojex` sub-workspace); **the commit is a `mercury/…` (+ `docs/mercury/…`) pathspec**.

## The laws (the load-bearing properties — an invariant that asserts one is a runnable check)

| Law | What it binds | Source |
|---|---|---|
| **The master invariant (the barrel holds)** | Every name exported from `mercury/packages/mercury-ui/src/index.ts` before a rung is still exported after it (additions OK; **removals/renames break the apps**). The barrel is `export * from "./components/…"`, so a text-diff of `index.ts` is INSUFFICIENT — resolve the full export set (TS `getExportsOfModule`, or `dist/index.d.ts` after a build). | canon §2 |
| **The package/app split** | Reusable components live ONLY in `packages/*`; apps **compose** them with the `@mercury/effector` plug — they never house or reimplement a reusable component. | canon §7 `D-8` |
| **The contract (`D-7`)** | Every `@mercury/ui` component carries a co-located, **hand-authored** `<Name>.prompt.md` (the six-section shape in `docs/mercury/contracts.md`), grounded in three truths — the `.tsx` source · real call sites in `apps/showcase` + `economy` · the sibling contracts it cross-links. A generated design-sync stub is a SEED for the prop list only, never the contract. | canon §4/§6 `D-7` |
| **Token discipline** | Components style through enum props (`variant`/`size`/`tone`); layout styles with `rgb(var(--token))`; the private `.mx-*` classes are never authored by a consumer; no utility-class framework. A contract names the **token family** an enum resolves to (`--bg-brand`, the status families), never a raw hex/RGB. | canon §6 |

## The Mercury facts (the pre-loaded context — NO-INVENT, ground each in a real `.tsx` or a canon §)

- **The three packages** (`mercury.design.md`): `@mercury/core` (UI-free foundation — headless hooks, the
  reuse barrel, `cx`/`date`/`types`; **zero JSX**; React a peer; source-consumed) → `@mercury/ui` (the
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
  (Modal · Tooltip) · `layout` (AuthLayout). Forward-tense ("mx.N adds …") for an unshipped surface.
- **The tokens** (`mercury/packages/mercury-ui/src/styles/`): semantic families resolved as `rgb(var(--token))`
  — surfaces (`--bg-brand`, `--bg-brand-hover`), text (`--fg-on-brand`), borders (`--border-strong`), the
  status families, the spacing ramp (`--space-2` …), and the three font roles `--font-primary` (DM Sans) /
  `--font-secondary` (DM Mono) / `--font-display` (DM Serif Display). `dark-theme` on an ancestor flips every
  token. The `.mx-*` recipes (e.g. `.mx-btn--<variant>`) are the private styling layer. **Cite the real token —
  the canon §6 is the authority; re-grep `styles/` rather than assert a name.**
- **The three Movements** (`mercury.roadmap.md`): **I** — modular foundation & Claude-Design structure (`mx.0`
  docs ✅, `mx.1` the structural rung ✅). **II** — the authored contract layer (`mx.2`). **III** — the Design
  System Storybook (`mx.3` host → `mx.4` component stories → `mx.5` effector stories → `mx.7` import epic;
  `mx.6` dropped). Re-sequencing is Operator-ruled — re-probe the dashboard at the rung's reconcile.
- **The decisions** (`mercury.design.md` §7): `D-1` core scope = utils/types/hooks only · `D-3` core
  source-consumed, React a peer · `D-7` the hand-authored contract · `D-8` the app/library split ratified ·
  `D-6` (mx.7) `@mercury/ui` never imports `@internationalized/date` — dates flow THROUGH `@mercury/core`.

## The frontend-design valve (taste → tokens → system)

The `frontend-design` plugin is a model-invoked **taste** instrument (bold distinctive aesthetics, distinctive
typography — avoid Inter/Roboto, CSS-variable themes, intentional motion, atmospheric depth, anti-AI-slop). It
is **where a look is discovered**; Mercury is **where it is systematized**. The valve, in one line: **explore a
look (plugin) → distill into tokens/contracts → commit to the system (Mercury)** — the plugin feeds the system,
it never bypasses it into one-off app CSS.

Both roles carry the full taste vocabulary; they differ by **axis of exploration**, united by **medium of
expression**:

- **Venus explores at the system/look level** — direction, new `--token` families, the enum→token language.
  Output: token/contract *proposals*.
- **Mars explores at the component/interaction level** — motion curves, focus rings, state transitions,
  density rhythm, the anti-slop micro-craft. Output: token-faithful *implementation*.
- **The token system is the shared medium.** Every taste decision — Venus's or Mars's — lands as a
  `--token`/`.mx-*` recipe, never raw hex in a consumer. Token discipline is not a leash on taste; it is the
  channel that turns taste into **reusable system value** instead of throwaway CSS. (`Motion` is NOT in the
  lockfile — adding a runtime dependency is a fork the Operator rules, never a silent import; prefer
  CSS-token-driven motion.)

## The aaw ledger (the durable record — `mcp__aaw__*`)

The aaw MCP (the `go/aaw` server) carries a scoped, append-only ledger that makes a rung's reasoning
inspectable — the AAW *transparency* pillar. On a rung that stands up a team (`mcp__aaw__aaw_init` →
`agent_register` → `TeamCreate(<dashed-scope>)`), the `tool_x_*` family records:

| Tool | Records | Key |
|---|---|---|
| `tool_x_alternative` | an option considered (a design variant, an approach) | `V-n` |
| `tool_x_consensus` | a panel's agreement across independent judgments | `C-n` |
| `tool_x_nxm_synthesize` | a fusion of N agents' outputs into one | `S-n` |
| `tool_x_decision` | a ruled decision (the Operator's, or a closed fork) | `D-n` |
| `tool_x_learning` | a craft/process lesson to fold forward | `L-n` |

The dashed scope (`mx-2`, never `mx.2` — `^[a-z0-9][a-z0-9-]*$`; a dot split-brains the registry) matches the
on-disk ledger filename when one is kept. A Duo/Trio rung needs no team; a design judge-panel or a Squad rung
opens the ledger.

## The gate ladder (run from `mercury/`, before reporting — NEVER a blind `pnpm -r`)

```bash
pnpm --filter "./packages/*" typecheck     # every package clean
pnpm --filter "./packages/*" build         # every package builds
pnpm --filter "./apps/*" build             # all apps build (resolve @mercury/* from source via alias)
# barrel-diff — the @mercury/ui export name set (resolved, not text-diffed): 0 removed/renamed
```

Node ≥22, pnpm ≥10.17. A docs/contract-only rung adds **no export and must not perturb `tsc`/`vite`** — the
gate proves the build is undisturbed plus the contract-coverage + no-extractor-framing checks.

## Process locks (every rung, this repo)

- **Agents run NO git.** The Director commits once, at the rung's close, by **pathspec** (`git commit -F <msg>
  -- <paths>`; never `git add -A`, never a bare commit) — and **only when the Operator asks**. The Operator
  pre-stages out-of-band, so the tree is routinely entangled with sibling programs: re-verify `git diff
  --cached --name-only` is purely Mercury before committing, and split an entangled tree into one scoped commit
  per concern. The message ends with the `Co-Authored-By: Claude Opus 4.8` trailer. Do not push unless asked.
- **The boundary.** The diff stays inside `mercury/packages/*` (+ the `mercury/apps/*/vite.config.ts` aliases a
  package rung moves) + the co-located contracts + the rung's `docs/mercury/`. A change reaching an
  OUT-of-bounds dir is a diff no one can review — STOP and re-scope.
- **Escalate, do not invent.** A spec⇄canon / spec⇄spec / spec⇄as-built contradiction STOPS and escalates to
  the Director; the canon is the authority; a deterministic re-grep/probe closes every escalation.
