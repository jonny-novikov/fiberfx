# Mercury UI — the operating manual

How the Mercury program runs. Light by design — Mercury is a focused design-system program, not the
full Venus/Mars/Apollo lead-team. The forward plan is [`../mercury.roadmap.md`](../mercury.roadmap.md);
the canon is [`../mercury.design.md`](../mercury.design.md); the dashboard is
[`../mercury.progress.md`](../mercury.progress.md).

## Who

- **The Operator** owns the goal, the ladder order, and every fork (`D-`/`S-` decisions).
- **Claude Code** ships each rung through the loop below — plan, build, gate, record. Commits happen
  **only when the Operator asks**.

## The unit of work — a rung

A **rung** (`mx.N`) is one shippable increment with a three-file spec under
[`../specs/<rung>/`](../specs/):

- `<rung>.md` — the body: the slice (why), goal, scope (in/out), invariants, deliverables,
  dependencies. **The body is authoritative.**
- `<rung>.stories.md` — the acceptance face: Given/When/Then stories, each tied to a deliverable +
  the invariant it proves.
- `<rung>.llms.md` — build context for the implementor: exact paths, the move recipe, the gate
  commands, gotchas.

## The loop

1. **Sharpen.** Confirm scope against the roadmap + canon; author/refresh the triad.
2. **Build.** Implement to the body. **Move, don't rewrite**, where a rung relocates code (e.g.
   hoisting `@mercury/core`). Keep the diff inside `mercury/packages/*` — plus the
   `apps/*/vite.config.ts` aliases when a package rung adds/moves a package.
3. **Gate** (run from the workspace root, `mercury/`):
   - `pnpm -r typecheck` — every package clean.
   - `pnpm -r build` — every package builds.
   - **Barrel-diff** — the set of named exports from `@mercury/ui` is identical before/after the
     rung (the master invariant, mechanically checked: compare `git show HEAD:packages/mercury-ui/src/index.ts`
     export names against the working tree).
   - `pnpm --filter "./apps/*" build` — every app still builds, resolving packages via alias.
   - No dangling import to a moved/deleted path (a deleted-package rung greps the repo for the old
     specifier).
4. **Record.** Update [`../mercury.progress.md`](../mercury.progress.md) (the bar + one-line state);
   record any decision as a `D-` row in [`../mercury.design.md`](../mercury.design.md) §7.
5. **Commit.** Only on the Operator's ask; **pathspec only** (never `git add -A`); re-verify
   `git diff --cached --name-only` is purely the rung; split an entangled tree into scoped commits.
   Do not push unless asked.

## The standing laws

- **The master invariant.** `@mercury/ui`'s public export surface holds across every rung
  (the barrel-diff). See the canon §2.
- **The package/app split.** Reusable, ready-to-use components live ONLY in `packages/*`
  (`@mercury/ui` for components, `@mercury/core` for the UI-free foundation, `@mercury/effector` for
  state). Apps (`apps/*`) only **compose** them — never house or reimplement a reusable component.
- **Source-resolution.** Apps (and the Storybook host) resolve `@mercury/*` from **source** via vite
  alias — no prebuild in dev. A package rung that adds a package adds its alias everywhere it's
  consumed.
- **Token discipline.** Style components through enum props; style layout with `rgb(var(--token))`
  tokens; never author the private `.mx-*` classes or reach for a utility-class framework (canon §6).

## Map

[`../mercury.roadmap.md`](../mercury.roadmap.md) · [`../mercury.design.md`](../mercury.design.md) ·
[`../mercury.progress.md`](../mercury.progress.md) · the rung triads under
[`../specs/`](../specs/).
