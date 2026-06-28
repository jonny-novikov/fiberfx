# @mercury/effector — the state plug

Effector-backed state adapters that keep Mercury components **presentational**: `useTheme` /
`setTheme` / `toggleTheme` / `initTheme`, `toast` + `<Toaster>` (renders Mercury `Alert`s),
`createForm` (`useField` / `useForm`, async `onSubmit` + `$submitting`), `passwordStrength`,
`createCooldown`. Depends on `@mercury/core` + `@mercury/ui`. State lives **outside React** (Effector
stores), so the components never gain application state.

See the program CLAUDE.md ([`../../CLAUDE.md`]) for the AAW loop + the standing laws.

## Rules

- **Presentational stays presentational.** An adapter wires state to a Mercury component *from the
  outside* — it never pushes state into the component library. The split is load-bearing: `@mercury/ui`
  has no idea Effector exists.
- **Depend through the public surface.** Use `@mercury/ui` for the components an adapter renders
  (`Toaster` → `Alert`) and `@mercury/core` for `date`/utils — never reach into a package's internal
  path.
- **Backward-compat is a contract.** `createForm`'s async `onSubmit` + `$submitting` were added
  additively; existing `useForm()` callers (the `showcase` SignIn, the `mobile` send form) must keep
  working. Grow the surface; don't break it.

## Add an adapter

A new Effector store + a thin hook under `src/`; export from `src/index.ts`. If it renders UI, compose
the **public** `@mercury/ui` export. Gate:
`pnpm --filter @mercury/effector typecheck && pnpm --filter @mercury/effector build`.
