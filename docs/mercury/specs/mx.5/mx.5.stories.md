# MX.5 · acceptance stories

Given/When/Then for [`mx.5.md`](./mx.5.md). Each story is in Connextra form, names the deliverable it
realizes and the invariant(s) it proves, and states concrete, checkable criteria — "done" is a closure
over these checks, not prose. **Coverage:** K-1 → S-1..S-6 ; K-2 → S-1..S-6 ; K-3 → S-1..S-6 ; K-4 → S-7 ;
K-5 → S-8 ; K-6 → S-9.

> One story per adapter (S-1..S-6) proves the adapter's deliverable (a file that exists, is
> effector-bound, and wires the right component at the real prop surface). S-7..S-9 are the rung-wide
> gates (surface frozen · host untouched · gate green).

## S-1 · The Theme story flips the canon tokens from live state (K-1, K-2, K-3)
*As a **design-system browser**, I want a story where a `Switch` driven by the effector theme store flips
the `dark-theme` tokens, so that the "components stay presentational; effector plugs the state" contract is
visible.*
**Given** `apps/storybook/stories/effector/Theme.stories.tsx` — CSF3, `title: "Effector/Theme"`, importing
`useTheme`/`toggleTheme`/`setTheme` from `@mercury/effector` and `Switch` (+ sample `Button`/`Alert`) from
`@mercury/ui` — **when** the story renders and the `Switch` is toggled, **then** the story's own in-render
`${theme}-theme` wrapper (theme from `useTheme()`) flips the canon §6 tokens on the sample components, the
`Switch` is `checked={theme === "dark"}` with `onChange={() => toggleTheme()}`, **and** the story does
**not** call `initTheme()` (no global `<html>`/`localStorage` mutation, Arm A) so no other story leaks.
*(Proves INV-3 + INV-6 + INV-7.)*

## S-2 · The Toast story fires live toasts that render as Alerts (K-1, K-2, K-3)
*As a **feedback author**, I want `Button`s that fire `toast.*` and a `<Toaster/>` that renders the live
toasts as Mercury `Alert`s, so that the event→store→render path is demonstrable.*
**Given** `Toast.stories.tsx` (`title: "Effector/Toast"`) importing `toast`/`clearToasts`/`Toaster` from
`@mercury/effector` and `Button` from `@mercury/ui`, **when** a `toast.success/error/warning/info` button
is clicked, **then** a Mercury `Alert` of the mapped tone (`error → "danger"`, the others 1:1) appears in
the single `<Toaster position="bottom-end" />`, auto-dismisses (the adapter's effect), and a `clearToasts`
button empties them — **and** the story uses only real `toast` helpers + real `Alert` tones (no invented
tone). *(Proves INV-3 + INV-6.)*

## S-3 · The Form story drives presentational Inputs from a createForm model (K-1, K-2, K-3)
*As a **form author**, I want `createForm` to drive `Input`s + a submit `Button` with live validation and a
`submitting` flag, so that the inputs hold no state of their own.*
**Given** `Form.stories.tsx` (`title: "Effector/Form"`) with a module-scope `createForm({ initialValues,
validate, onSubmit })`, **when** the story renders and a field is edited, **then** each `Input` is bound via
`useField(name)` — `value={field.value}`, `onChange={(e) => field.onChange(e.target.value)}`,
`onBlur={field.onBlur}`, `error={field.error}` — the submit `Button` is `loading={useForm().submitting}` and
`disabled={!isValid}`, an invalid field shows its `error` only after touch/submit, and a valid submit toggles
`submitting`; **and** every prop used is defined in `Input.tsx`/`Button.tsx`. *(Proves INV-3 + INV-6.)*

## S-4 · The Strength story scores a live-state password into the meter + checklist (K-1, K-2, K-3)
*As an **auth-screen author**, I want a password `Input` whose value lives in effector state, scored by
`passwordStrength` into a `PasswordStrength` meter and a `Checklist`, so that the pure scorer + the live
state read together.*
**Given** `Strength.stories.tsx` (`title: "Effector/Strength"`) with an inline Effector store holding the
password (`createStore<string>` + `createEvent` + `useUnit`; or a single-field `createForm`), **when** the
user types, **then** `passwordStrength(value)` feeds `<PasswordStrength score=… label=… variant=… />` and a
`<Checklist items=[…] />` whose four `met` flags map to `rules.{length,mixedCase,number,symbol}`, the meter's
`variant` is `s.variant` (the `"negative"|"caution"|"positive"` union, assignable straight into the prop),
**and** the value is held in Effector, not bare React state in a non-effector path. *(Proves INV-3 + INV-6.)*

## S-5 · The Cooldown story gates a resend Button by a live countdown (K-1, K-2, K-3)
*As an **OTP-screen author**, I want `createCooldown` to disable a resend `Button` and show a live "resend
in Ns" countdown beside an `AuthCode`, so that the timer state lives outside React.*
**Given** `Cooldown.stories.tsx` (`title: "Effector/Cooldown"`) with a module-scope `createCooldown()`,
**when** the resend `Button` is clicked, **then** `start(30)` runs, `useCooldown()` drives
`disabled={remaining > 0}` and the label `remaining > 0 ? "Resend in {n}s" : "Resend code"`, the count
decrements once per second to 0 and re-enables the button, **and** an `<AuthCode length={6} allow="numeric"
…/>` renders beside it as the gated affordance — every prop verified in `Button.tsx`/`AuthCode.tsx`.
*(Proves INV-3 + INV-6.)*

## S-6 · The Formatter story renders a live locale-formatted date into a Stat (K-1, K-2, K-3)
*As a **localization author**, I want `createFormatterModel` to render a locale-formatted date into a
`Stat`, switchable by a `Select`, so that changing the locale store re-renders the value.*
**Given** `Formatter.stories.tsx` (`title: "Effector/Formatter"`) with a module-scope
`createFormatterModel()` and a **fixed** `const SAMPLE = new Date(2026, 0, 15)`, **when** the locale
`Select` changes, **then** `setLocale(value)` re-renders `<Stat label=… value={useFormatter().fullMonthAndYear(SAMPLE)} />`
in the chosen locale, a month/year-style control calls `setMonthFormat`/`setYearFormat` with valid `Intl`
values, **and** the story wires `Stat` (NOT `MoneyInput` — the formatter is a date/locale formatter, the
mx.5.md §6.6 reconcile correction), with no `new Date()` at module load. *(Proves INV-3 + INV-6 + INV-7.)*

## S-7 · The @mercury/ui public surface is byte-identical (K-4)
*As a **downstream consumer**, I want mx.5 to add no public surface, so that nothing I import changes.*
**Given** the `@mercury/ui` barrel + components before and after mx.5, **when** the byte-diff runs
(`diff <(git show HEAD:packages/mercury-ui/src/index.ts) packages/mercury-ui/src/index.ts`) and
`git diff --name-only` is inspected, **then** the barrel diff is **empty** (byte-identical, not merely
additions-only) **and** no path under `packages/mercury-ui/src/` is changed (no component `.tsx`/`index.ts`
edit) — any unavoidable non-export-changing fix is explicitly flagged in the report, never silent.
*(Proves INV-1 + INV-2.)*

## S-8 · The host needs no edit; the six stories are the whole code diff (K-5)
*As a **host maintainer**, I want the effector stories to need zero host wiring, so that the rung adds only
content.*
**Given** the mx.4 host (`@mercury/effector` dep + vite alias + tsconfig path + glob + `sb:*` scripts all
present, mx.5.md §4), **when** `git diff --name-only` runs, **then** the only changed/added paths are the
**six** `apps/storybook/stories/effector/*.stories.tsx` (+ `docs/mercury/specs/mx.5/`) — **no** change under
`apps/storybook/.storybook/`, `apps/storybook/tsconfig.json`, `apps/storybook/vite.config.ts`, or
`apps/storybook/package.json`. If a host edit proves necessary, the build STOPS and surfaces it as a scope
fork. *(Proves INV-2.)*

## S-9 · The gate is green — typecheck, build, 42 homes (K-6)
*As a **Director**, I want the rung to pass the full per-rung gate, so that it ships without regression.*
**Given** the six effector stories, **when** the gate runs from `mercury/` —
`pnpm sb:typecheck` · `pnpm --filter "./packages/*" typecheck` · `pnpm --filter "./packages/*" build` ·
`pnpm --filter "./apps/*" --filter "!@mercury/storybook" build` · `pnpm sb:build` — **then** every command
exits 0; `sb:build` registers **exactly 42** story homes (the prior 36 unchanged + the six new
`Effector/{Theme,Toast,Form,Strength,Cooldown,Formatter}`); the NO-INVENT grep
(`window.MercuryUI`/`_ds_bundle`) and the raw-hex grep over `apps/storybook/stories/effector` are both
**empty**. *(Proves INV-3 + INV-4 + INV-5 + INV-6 + INV-7.)*
