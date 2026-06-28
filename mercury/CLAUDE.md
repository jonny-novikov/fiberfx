# CLAUDE.md — Mercury UI · the React design system

Guidance for agents working **Mercury** — a token-driven, presentational React design system in a
pnpm monorepo (Vite · Effector · TypeScript, Node ≥22, pnpm ≥10.17). **Distinct** from the echo_mq /
BCS Elixir stack that shares the `jonnify` git root: different language, different tooling, no module
overlap. The git root is `jonnify` (the PARENT), so **scope every commit with a `mercury/...`
pathspec** — never `git add -A`. `TMPDIR=/tmp` is an Elixir-only rule; it does **not** apply here.

> Canon lives in `docs/mercury/` (not duplicated here): the design [`../docs/mercury/mercury.design.md`],
> the roadmap [`../docs/mercury/mercury.roadmap.md`], the dashboard
> [`../docs/mercury/mercury.progress.md`], the manual [`../docs/mercury/program/mercury.program.md`].
> The workflow that ships it is **AAW** ([`../docs/aaw/aaw.framework.md`]).

## What Mercury is

Three packages under `packages/`, one new line — **the foundation is a package, not a folder**:

| Package | Role | Depends on |
|---|---|---|
| `@mercury/core` | UI-free foundation: headless hooks, the reuse barrel, `cx`/`date`/`types`. **Zero JSX.** | — (React a *peer*) |
| `@mercury/ui` | The component library, Claude-Design grouped (`src/components/<group>/<Name>/`). Tokens live here. | `@mercury/core` |
| `@mercury/effector` | Effector state adapters (theme · toast · form · strength · cooldown). Components stay presentational. | `@mercury/core` + `@mercury/ui` |

Apps (`apps/*` + the `codemojex-node/apps/*` sub-workspace) resolve `@mercury/*` **from source** via a
vite alias + tsconfig `paths` — a package edit is live in dev, no prebuild.

## How the work runs — the AAW loop (summary)

Mercury ships through **AAW (the Agile Agent Workflow)** — defined in [`../docs/aaw/aaw.framework.md`],
summarized here for the agent at the keyboard:

- **One Operator, agents in named roles.** The human **Operator** owns intent, every
  architecture/contract/dependency **fork**, and acceptance. The **Director** (the orchestrating
  agent — you, when leading) designs the ladder, spawns and gates the specialized agents, verifies
  adversarially, ratifies, and **commits when asked**. The specialized roles each have a charter: a
  **spec-steward** (architect) reconciles the spec and authors the build brief; an **implementor**
  builds + hardens from that brief and nothing else; a **verifier** re-runs the gate, reconciles
  spec↔code, and mentors the other charters. **An agent surfaces forks; it never decides one.**
- **Work in rungs.** A **rung** (`mx.N`) is one thin, provable increment carried by a three-file
  spec under `docs/mercury/specs/<rung>/`: `<rung>.md` (the body — *authoritative*), `.stories.md`
  (Given/When/Then acceptance), `.llms.md` (build context). The three move together as the **triad**.
- **The six-stage loop:** sharpen (Operator agrees the spec) → build → ship (thin but robust, behind
  the boundary) → demo → review → feedback. **Feedback edits the spec, never the code directly.**
- **Forward mode, grounded.** The spec is the source of truth; the build cites it; a reconcile pass
  diffs as-built against the spec each rung. **No invention** — every public call names a real
  surface, every prop is verified in the `.tsx`.
- **The architect's two instruments** ([`../docs/aaw/aaw.architect-approach.md`]): *forks* (surface
  ≥2 arms as Rationale · 5W · Steelman · Steward; the Operator rules) and the *contract set*
  (hand-author the per-component contracts as hypotheses that feed each other, reconciled against
  source + real call sites).

Mercury is a **light** program — not the full Venus/Mars/Apollo lead-team — but the loop, the
grounding standard, and the contract discipline are the same.

**Ship a rung with `/mercury-ship <rung>`** (e.g. `/mercury-ship mx.2`) — `/x-mode` with the Mercury
context pre-loaded and the ceremony collapsed to a Duo/Trio: it binds the laws to the **Mercury
island** (`mercury/**` + `docs/mercury/**` + `docs/aaw/**` — everything else in the `jonnify` root,
`echo/ html/ elixir/ go/ infra/ node/ tradex/ …`, is **out of bounds**), the `pnpm --filter` gate, the
barrel master-invariant, the `D-7` contract law, and the `mercury/…` pathspec commit. **Reconcile** a
spec triad against the as-built code with `/mercury-ship reconcile <rung>` (the spec↔code differ — barrel
exports · prop tables · cross-links · call-site citations). The skill is
[`.claude/skills/mercury-ship/SKILL.md`] at the `jonnify` root.

## The standing laws

- **The master invariant.** `@mercury/ui`'s public export surface holds across every rung — every
  name exported from `src/index.ts` before a rung is still exported after it (additions OK;
  **removals/renames NOT**). The mechanical check is the **barrel-diff**. The barrel uses
  `export * from "./components/..."`, so a text-diff of `index.ts` is **insufficient** — resolve the
  full export set (TS `getExportsOfModule`) when in doubt.
- **The package/app split.** Reusable components live ONLY in `packages/*`. Apps **compose** them
  with the `@mercury/effector` plug — they never house or reimplement a reusable component.
- **The contract.** Every component carries a co-located, **hand-authored** `<Name>.prompt.md` (canon
  §4/§6; format at [`../docs/mercury/contracts.md`]). A generated design-sync stub is a seed, never
  the contract.
- **Token discipline.** Style components through enum props; style layout with `rgb(var(--token))`;
  never author the private `.mx-*` classes or reach for a utility-class framework.
- **Commit only when asked**, **pathspec only** (the git root is `jonnify` — re-verify
  `git diff --cached --name-only` is purely Mercury). Don't push unless asked.

## The gate ladder (run from `mercury/`)

```bash
pnpm --filter "./packages/*" typecheck     # every package clean
pnpm --filter "./packages/*" build         # every package builds
pnpm --filter "./apps/*" build             # all 5 apps build (resolve from source)
# barrel-diff — the @mercury/ui export name set: 0 removed/renamed
```

Scope to Mercury with `--filter` — **not** a blind `pnpm -r` — the `codemojex-node` sub-workspace
carries its own (sometimes-broken) build state.

## Map

Per-package guides: [`packages/mercury-core/CLAUDE.md`] · [`packages/mercury-ui/CLAUDE.md`] ·
[`packages/mercury-effector/CLAUDE.md`]. Canon: [`../docs/mercury/`]. Workflow:
[`../docs/aaw/aaw.framework.md`] + the contract-set method [`../docs/aaw/aaw.architect-approach.md`].
