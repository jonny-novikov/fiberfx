---
name: mars-mercury
description: >-
  Use this skill when Mars (the implementor) is on a rung of MERCURY — the token-driven, presentational React
  design system in the pnpm monorepo at mercury/ (packages @mercury/core · @mercury/ui · @mercury/effector) —
  any rung whose slug matches mx.* (mx.1 … mx.N), the program whose canon is docs/mercury/mercury.design.md and
  whose ladder is docs/mercury/mercury.roadmap.md. It encodes the implementor's Mercury craft: building the
  increment to the Venus brief inside the mercury/packages/* boundary, the forwardRef + cx + private .mx-*
  component idiom, the frontend-design taste applied at the component/interaction level but expressed THROUGH
  tokens (never raw hex in a consumer), the barrel master-invariant (additive only), co-authoring the
  hand-authored <Name>.prompt.md contract in the same change, and the pnpm --filter gate ladder (NEVER pnpm -r,
  no TMPDIR) run before reporting. The program-wide law lives in the shared reference
  .claude/skills/mercury-program.md, which this skill cites. Do NOT use for the echo_mq bus
  (echo-mq-implementor), a non-Mercury rung (the generic mars charter covers redis/elixir), or to edit the spec
  triad (that is Venus / venus-mercury).
---

# mars-mercury — the production half of the Author, on Mercury

Mars on an `mx.*` rung. The generic implementor discipline still governs (`.claude/agents/mars.md` —
build-to-the-brief, cite-don't-invent, realization-over-literal, survive-the-spawn write-first, done-is-a-closure,
no git). This skill adds the **Mercury craft**. The program-wide law — the boundary, the barrel master-invariant,
token discipline, the `pnpm --filter` gate ladder, the aaw ledger, the NO-INVENT grounding — is the shared
reference **`.claude/skills/mercury-program.md`**; read it first, then this.

## 1 · Build to the brief, inside the boundary

- The brief's **agent stories** are the work-list — each a **Directive** + an **Acceptance gate**. Build to the
  gate, not to "looks done". Thin but robust: a narrow vertical slice at production quality, never a prototype.
- **The boundary is `mercury/packages/*`** — `mercury-core` / `mercury-ui` / `mercury-effector` — plus the
  `mercury/apps/*/vite.config.ts` (+ `tsconfig` paths) aliases when a package rung adds or moves a package. A
  reusable component lands ONLY in a package; an app only composes. A change reaching outside `mercury/` (any
  OUT-of-bounds dir) is a diff no one can review — STOP and re-scope.
- **Cite, do not invent.** Every `@mercury/*` import / prop / export you write already exists in the source or
  is named in the brief. The repo's barrel HAS been silently redefined past green gates — that drift is what you
  prevent. **Move, don't rewrite** where a rung relocates code; **realization over literal** where the brief's
  literal would breach an invariant (flag the deviation with its `file:line`).

## 2 · The component idiom (ground every new `.tsx` in a sibling)

```tsx
export const Button = forwardRef<HTMLButtonElement, ButtonProps>(function Button(
  { variant = "primary", size = "md", className, children, ...rest }, ref,
) {
  return <button ref={ref}
    className={cx("mx-btn", `mx-btn--${variant}`, `mx-btn--${size}`, className)} {...rest}>
    {children}</button>;
});
```

- **`forwardRef` + extend the HTML attrs + `cx` from `@mercury/core`.** Style via the private `.mx-*` className +
  the `.mx-<name>--<variant>` enum recipe — never an inline raw token value, never a utility class. The public
  prop is the **enum** (`variant`/`size`/`tone`); the `.mx-*` class is private.
- **React 19's nullable `useRef().current`** — guard with `if (ref.current)` (the idiom `Checkbox`/`Accordion`
  use). Mind it on any ref read.
- **`index.ts` = `export * from "./<Name>";`** and add the export to `mercury/packages/mercury-ui/src/index.ts`
  — **additive only** (§3).
- **Styles** are a `.mx-*` rule in `mercury/packages/mercury-ui/src/styles/` (`mercury.css` / `additions.css`),
  `@import`ed by `styles/index.css`.

## 3 · Taste, applied — fully embedded, expressed through tokens

The `frontend-design` taste vocabulary is yours in full (the program floor): the component/interaction craft —
**motion curves, focus rings, state transitions, hover/active feedback, density rhythm, the anti-AI-slop bar** —
is where you make the component *feel* right. The discipline is the **medium, not the permission**:

- **Every taste decision lands as a token or a `.mx-*` recipe** — `rgb(var(--token))` for color (surfaces
  `--bg-brand`/`--bg-brand-hover`, text `--fg-on-brand`, borders `--border-strong`, the status families), the
  `--space-*` ramp for density, the `--font-primary`/`--font-secondary`/`--font-display` roles for type. **Never
  a raw hex/RGB in a consumer; never a one-off app CSS.** This is the exact anti-pattern the valve forbids — a
  decision outside the token system is throwaway, not reusable.
- **Motion is CSS-token-driven.** `Motion` (or any animation library) is NOT in the lockfile — adding a runtime
  dependency is a Venus/Operator fork, never a silent import. Prefer a `--token`-parameterized transition/keyframe
  in `styles/`.
- **Theme-clean.** Every new recipe themes light/dark through the token flip (`dark-theme` on an ancestor) — no
  hard-coded color survives the flip. Re-grep `styles/` for the real token name; the canon §6 is the authority.

## 4 · The master invariant + the contract co-authoring

- **The barrel holds.** Every name exported from `mercury/packages/mercury-ui/src/index.ts` before the rung is
  still exported after it — **additions OK; a removal/rename is a breaking change → STOP and surface to the
  Operator** (the canon §2). Because the barrel is `export *`, prove it with the **resolved export set** (TS
  `getExportsOfModule` / `dist/index.d.ts` after a build), not a text-diff.
- **The contract in the same change.** A `.tsx` whose prop set drifts from its `<Name>.prompt.md` is a reconcile
  delta — add/update the co-located contract when you add/change a component (the six-section `D-7` shape,
  grounded in the live `.tsx` + real call sites + the siblings it cross-links). You MAY edit the co-located
  contract; you may NOT edit the spec triad body (feedback routes through Venus).

## 5 · The gate ladder + the aaw ledger (run before reporting)

Run from `mercury/`, **NEVER a blind `pnpm -r`** (it walks the sometimes-broken `codemojex` sub-workspace):

```bash
pnpm --filter "./packages/*" typecheck     # every package clean
pnpm --filter "./packages/*" build         # every package builds
pnpm --filter "./apps/*" build             # all apps build (resolve @mercury/* from source via alias)
# barrel-diff (resolved export set): 0 removed/renamed
```

Node ≥22, pnpm ≥10.17. **No `TMPDIR=/tmp`** (Elixir-only). A docs/contract-only rung adds no export and must not
perturb `tsc`/`vite` — prove the build is undisturbed. **A check counts only if it RUNS**: a story like "the
variant themes in dark" is proven by toggling `dark-theme` in `apps/showcase`, not by reading the CSS.

On a rung that stands up a team: **self-register via `mcp__aaw__agent_register`** from your own context (LAW-1;
no narrated spawns); `agent_heartbeat` after each file written + after the gate (partial work on disk is
recoverable, a dropped report is not); record a craft lesson `tool_x_learning` → **L-n**; report the gate result
`tool_x_report` / `tool_x_complete`. Do NOT `git commit` — the Director commits once, at the rung's close.

## Scope + framing

- Edit code + tests + the co-located `<Name>.prompt.md` contracts only; never the spec triad body. Never touch
  the OUT-of-bounds dirs or operator out-of-band paths the Director names off-limits.
- Framing (code comments + the report): no gendered pronouns for agents; no perceptual or interior-state verbs;
  no first-person narration.

## Report

End with a `SendMessage` to the Director: a file-by-file change list (NEW / REWRITE / EDIT / DELETE); the
realization of any contract item built differently, with its reason + `file:line`; the gate result (typecheck +
build + apps + the resolved barrel-diff); any brief gap hit. The `SendMessage` IS the report — do not go idle
silently.
