# MX.5 — build context (for the implementor / the story-author wave)

Working notes for building [`mx.5.md`](./mx.5.md) — six effector-powered Storybook stories. Root =
`mercury/`. The body is authoritative; this file derives from it. **NO-INVENT:** every `@mercury/effector`
and `@mercury/ui` name cited here is a real export (traced from source below); every path is real; every
component prop is verified in the component's `.tsx` before a story uses it. **Edit ONLY** six new files
under `apps/storybook/stories/effector/` — no `@mercury/ui` edit, no host-config edit.

## References (read first, in order)

1. [`mx.5.md`](./mx.5.md) — the authoritative body (the wiring map §6 is the build target).
2. The adapter source — the symbols you import (read each; the body §3 table is the index):
   `packages/mercury-effector/src/{theme.ts,toast.tsx,form.ts,strength.ts,cooldown.ts,formatter.ts}` +
   `packages/mercury-effector/src/index.ts` (the barrel — re-exports all six).
3. The exemplar story shapes (CSF3, typed enum arrays, NO-INVENT comments) — imitate exactly:
   `packages/mercury-ui/src/components/actions/Button/Button.stories.tsx` and the host-home cross-cutting
   `apps/storybook/stories/Tokens.stories.tsx` (the closest sibling — a render-based, no-single-component
   story in the same home where the effector stories go).
4. The component `.tsx` for every wired component (the prop surface is truth) + its mx.2 `<Name>.prompt.md`
   (the control language): `Switch · Button · Alert · Input · PasswordStrength · Checklist · AuthCode ·
   Stat · Select` (paths in the grounding table below).
5. The host (already wired — do NOT edit): `apps/storybook/.storybook/main.ts` (glob),
   `apps/storybook/.storybook/preview.tsx` (the mx.3 theme decorator — leave it; Arm A),
   `apps/storybook/{vite.config.ts,tsconfig.json,package.json}` (effector alias/path/dep all present).

## Ground facts (re-probe before trusting)

- **Stack:** Vite ^6.0.0, React 19, Node 22.18, pnpm 10.17.1, TypeScript ^5.6.3. `tsconfig.base.json`:
  `target/lib ES2024`, `moduleResolution: "Bundler"`, `jsx: "react-jsx"`, `verbatimModuleSyntax: true` (so
  `import type` for types), `isolatedModules`, `strict` + `noUncheckedIndexedAccess`.
- **The host is already effector-ready (mx.4):** `apps/storybook/package.json` deps include
  `@mercury/effector` + `effector ^23.3.0` + `effector-react ^23.3.0`; `vite.config.ts` aliases
  `@mercury/effector → ../../packages/mercury-effector/src/index.ts`; `tsconfig.json` has the matching
  `paths` entry and `include: ["stories/**/*.tsx", …]`; `.storybook/main.ts` glob
  `"../stories/**/*.stories.@(tsx|ts)"` covers `stories/effector/**`. **Add NO host wiring.** If a build
  step says a host edit is required, STOP and report — that is a scope fork, not an implementor call.
- **`sb:typecheck` is the authoritative NO-INVENT gate.** The library `tsc` excludes `**/*.stories.tsx`
  (mx.3 `D-9`); the host `tsc` (`pnpm sb:typecheck` = `@mercury/storybook typecheck`) is the only `tsc`
  that checks these stories. An invented symbol or a wrong prop fails here.
- **The barrel is FROZEN this rung.** `packages/mercury-ui/src/index.ts` must be byte-identical to HEAD.
  mx.4 grew it; mx.5 does not. Resolve from source via the alias — no effector/ui `dist` rebuild needed to
  render a story (the gate still builds the packages).
- **CSF3 import:** `import type { Meta, StoryObj } from "@storybook/react-vite";` (see the exemplars).
- **Hooks in stories:** an effector story renders live state via `effector-react` hooks. Storybook calls a
  CSF `render`/component as a React component, so call hooks inside a small inner function component (or
  the story's `render` body) — not at module top level.

## The file tree (create exactly these — nothing else)

```
apps/storybook/stories/effector/Theme.stories.tsx
apps/storybook/stories/effector/Toast.stories.tsx
apps/storybook/stories/effector/Form.stories.tsx
apps/storybook/stories/effector/Strength.stories.tsx
apps/storybook/stories/effector/Cooldown.stories.tsx
apps/storybook/stories/effector/Formatter.stories.tsx
```

No host edit · no `@mercury/ui` edit · no `tsconfig`/`vite`/`package.json` edit · no apps-side story (mx.6).

## The story-shape recipe (every file)

CSF3, mirroring the Button exemplar + Tokens shape:

- `import type { Meta, StoryObj } from "@storybook/react-vite";`
- `import { <adapter symbols> } from "@mercury/effector";` (+ `useUnit` etc. from `effector-react`,
  `createStore`/`createEvent` from `effector` where the story needs its own store).
- `import { <Components> } from "@mercury/ui";` + `import type { <ExportedUnion> } from "@mercury/ui";`
  for any enum option array (type it: `const TONES: AlertTone[] = [...]` — an invented member fails `tsc`).
- `const meta: Meta = { title: "Effector/<Adapter>" };` (these are cross-component — no `component:` field,
  like `Tokens.stories.tsx`); `export default meta;` `type Story = StoryObj;`
- A primary `Playground`/named story (`render: () => <Demo/>`) + ≥1 scenario story. Define any effector
  **model** (`createForm`/`createCooldown`/`createFormatterModel`/an inline store) at **module scope** so it
  is shared and stable across re-renders; read it via the hooks inside the render component.
- A leading NO-INVENT comment naming the source the wiring is traced from (the exemplar pattern).
- Token discipline: any layout color = `rgb(var(--token))`; never a raw hex; components styled via enum
  props. The mx.3 decorator already wraps every story in the theme + stylesheet — the story authors no
  theme wiring (except the Theme story's own local wrapper, Arm A).

## The grounding table (adapter symbol → wired component(s) → real props)

> Verify each prop against the cited `.tsx` before use; cross-check the control language against the mx.2
> `<Name>.prompt.md` beside it. The `.tsx` is truth.

| Story | Effector imports (from `@mercury/effector`) | `@mercury/ui` component(s) + path | Real prop surface (verify in `.tsx`) |
|---|---|---|---|
| **Theme** | `useTheme` · `toggleTheme` · `setTheme` (NOT `initTheme`) | `Switch` `selection/Switch/Switch.tsx` (+ sample `Button`, `Alert`) | `Switch`: `checked?: boolean` · `onChange?: (checked: boolean) => void` · `label?: ReactNode` |
| **Toast** | `toast` (`.success/.error/.warning/.info`) · `clearToasts` · `Toaster` | `Button` `actions/Button/Button.tsx`; `Toaster` renders `Alert` `feedback/Alert/Alert.tsx` | `Button`: `variant` · `onClick`; `Toaster`: `position?: "top-end"\|"bottom-end"\|"bottom-center"`; `AlertTone = "info"\|"success"\|"warning"\|"danger"` (`error → "danger"`) |
| **Form** | `createForm` → `useField` · `useForm` | `Input` `inputs/Input/Input.tsx`; `Button` | `Input`: `label?` · `value` · `onChange (DOM event)` · `onBlur` · `error?`; bind `onChange={(e) => field.onChange(e.target.value)}`. `Button`: `type` · `loading?: boolean` · `disabled` |
| **Strength** | `passwordStrength` (pure) + an inline `createStore<string>`/`createEvent`/`useUnit` | `Input` (type=password); `PasswordStrength` `feedback/PasswordStrength/PasswordStrength.tsx`; `Checklist` `data-display/Checklist/Checklist.tsx` | `PasswordStrengthProps`: `score: number` · `label?: string` · `variant?: StrengthVariant`. `ChecklistProps`: `items: ChecklistItem[]`, `ChecklistItem { label: ReactNode; met: boolean }`. `passwordStrength` → `{ score, label, variant, rules:{length,mixedCase,number,symbol} }` |
| **Cooldown** | `createCooldown` → `start` · `stop` · `useCooldown` | `Button`; `AuthCode` `inputs/AuthCode/AuthCode.tsx` | `Button`: `disabled` + dynamic label. `AuthCodeProps`: `value: string` · `onChange: (v) => void` · `length?` · `allow?: "numeric"\|"alphanumeric"` |
| **Formatter** | `createFormatterModel` → `setLocale` · `setMonthFormat` · `setYearFormat` · `useFormatter` | `Stat` `data-display/Stat/Stat.tsx`; `Select` `inputs/Select/Select.tsx` (or `Segmented`) | `StatProps`: `label: string` · `value: ReactNode`. `Formatter.fullMonthAndYear(date: Date)` → string. `SelectOption { label; value; disabled? }`. `MonthFormat`/`YearFormat` accept `Intl` strings (`"long"\|"short"\|"narrow"\|"numeric"\|"2-digit"` / `"numeric"\|"2-digit"`) |

### Per-story directives + acceptance gates

Each story is a **Directive** (build) + an **Acceptance gate** (the check that closes it). Surfaces stated
as contracts (precondition / postcondition).

- **Theme (S-1).** *Directive:* render an in-`render` wrapper `<div className={`${theme}-theme`}>` with
  `theme = useTheme()`, a `<Switch checked={theme === "dark"} onChange={() => toggleTheme()} label="Dark theme" />`,
  and a couple of sample components (`Button`, `Alert`) so the token flip is visible. Optionally a
  `setTheme("light"|"dark")` pair. *Pre:* never call `initTheme()` (Arm A). *Gate:* toggling flips the
  canon tokens locally; `sb:typecheck` 0; no `initTheme` import.
- **Toast (S-2).** *Directive:* a `Button` row firing `toast.success/error/warning/info(...)` + a `ghost`
  `clearToasts` button; one `<Toaster position="bottom-end" />` in the render. *Post:* a click adds a live
  `Alert` of the mapped tone; auto-dismiss works; clear empties. *Gate:* only real `toast` helpers + real
  tones; `sb:typecheck` 0.
- **Form (S-3).** *Directive:* module-scope `createForm({ initialValues: { email: "", … }, validate, onSubmit })`;
  bind each `Input` via `useField`; submit `Button` `loading={useForm().submitting}` `disabled={!isValid}`
  `onClick={() => void submit()}`. *Pre:* `useField.onChange` is value-based — adapt the DOM event. *Gate:*
  invalid field shows `error` after touch; valid submit toggles `submitting`; `sb:typecheck` 0.
- **Strength (S-4).** *Directive:* inline `const $pwd = createStore<string>("")`, `const setPwd =
  createEvent<string>(); $pwd.on(setPwd, (_, v) => v)`; in render `const pwd = useUnit($pwd)`,
  `const s = passwordStrength(pwd)`; `Input type="password"` bound to `$pwd`; `PasswordStrength score/label/
  variant={s.*}`; `Checklist` with four items mapping `s.rules`. *Post:* meter + checklist track the live
  value. *Gate:* value held in Effector; `s.variant` types into the prop; `sb:typecheck` 0.
- **Cooldown (S-5).** *Directive:* module-scope `const cd = createCooldown()`; in render `const remaining =
  cd.useCooldown()`; resend `Button disabled={remaining > 0} onClick={() => cd.start(30)}` with the
  countdown label; an `<AuthCode length={6} allow="numeric" value={code} onChange={setCode} />` beside it
  (code value an inline store or `useState` — the cooldown is the effector demo). *Gate:* the count
  decrements to 0 and re-enables; `sb:typecheck` 0.
- **Formatter (S-6).** *Directive:* module-scope `const fm = createFormatterModel()` and `const SAMPLE =
  new Date(2026, 0, 15)` (**fixed** — no `new Date()` at load); in render `const f = fm.useFormatter()`;
  `<Stat label="Member since" value={f.fullMonthAndYear(SAMPLE)} />`; a locale `Select` calling
  `fm.setLocale(e.target.value)` (en-US/fr-FR/ja-JP/de-DE) and a month/year-style control calling
  `fm.setMonthFormat`/`fm.setYearFormat` with valid `Intl` values. *Pre:* wire `Stat`, NOT `MoneyInput`
  (the §6.6 reconcile correction — the formatter is a date/locale formatter). *Gate:* changing locale
  re-renders the `Stat`; no `new Date()` at module load; `sb:typecheck` 0.

## Build order (one wave is fine; ≤2 heavy authors concurrent if fanned out)

The six files are independent (no shared file, no barrel touch). Suggested grouping if fanned out:
**Wave 1:** Theme · Toast · Cooldown (simplest store/event wiring). **Wave 2:** Form · Strength · Formatter
(factory/derived wiring). The Director gates each wave with `sb:typecheck` + the NO-INVENT grep before the
next. A single-author single-wave build is acceptable (the rung is small).

## The gate (run from `mercury/`)

```bash
pnpm sb:typecheck                                                   # host tsc — the NO-INVENT gate, exit 0
pnpm --filter "./packages/*" typecheck                             # 3 packages clean
pnpm --filter "./packages/*" build                                 # 3 packages build
pnpm --filter "./apps/*" --filter "!@mercury/storybook" build      # the FIVE product apps build
pnpm sb:build                                                       # static build, exit 0 → 42 story homes

# barrel BYTE-IDENTICAL (master invariant, strongest form) — expect EMPTY:
diff <(git show HEAD:packages/mercury-ui/src/index.ts) packages/mercury-ui/src/index.ts

# surface + host untouched — git diff should list ONLY the six stories (+ the triad):
git diff --name-only

# NO-INVENT + token discipline greps over the new stories — expect EMPTY:
grep -rn "window.MercuryUI\|_ds_bundle" apps/storybook/stories/effector
grep -rnE "#[0-9a-fA-F]{3,8}\b" apps/storybook/stories/effector
grep -rn "new Date()" apps/storybook/stories/effector/Formatter.stories.tsx   # expect empty (fixed SAMPLE)
```

`sb:build` home count: confirm **42** homes — the 36 prior (35 component + `Foundations/Tokens`) unchanged +
the 6 new `Effector/{Theme,Toast,Form,Strength,Cooldown,Formatter}`.

## Gotchas

- **The barrel is BYTE-IDENTICAL this rung** (not additions-only like mx.4). Any change to
  `packages/mercury-ui/src/index.ts` is a fail. mx.5 adds no `@mercury/ui` surface.
- **No host edit.** The effector dep/alias/path/glob/scripts are already present (§4). If a build asks for
  one, STOP and surface it — do not add it.
- **`useField.onChange` is value-based, not a DOM handler.** Bind `onChange={(e) => field.onChange(e.target.value)}`
  for `Input`/`MoneyInput`-style components. (`Switch`/`AuthCode` `onChange` are already value-based.)
- **Strength is a PURE function** — it has no store; the story supplies the effector state. Hold the
  password in an inline `createStore`/`createEvent` (or a single-field `createForm`). Don't claim
  `passwordStrength` is "an effector store".
- **Formatter wires `Stat`, not `MoneyInput`.** The formatter is `Intl.DateTimeFormat`-based (dates/locale);
  `MoneyInput` takes no formatter. The task's "formatter→MoneyInput" hint is corrected in mx.5.md §6.6.
- **Determinism in the Formatter story:** a fixed `new Date(2026, 0, 15)` at module scope — never `new Date()`
  at load (a moving value drifts the rendered output and any snapshot).
- **The `grep -rn "new Date()" …Formatter.stories.tsx` gate is a SUBSTRING-LITERAL check** — it matches the
  bare text `new Date()` anywhere in the file, **including a comment** that happens to quote the literal. The
  gate-of-record is the *absence of a runtime `new Date()` at module load* (the `SAMPLE` is a fixed
  `new Date(2026, 0, 15)`), **not** the substring itself. Reword any comment to describe the rule without
  quoting `new Date()` (the shipped comment uses "a runtime clock read at load") so the grep stays a clean
  signal. *(As-built: the grep is empty — flagged here as a hygiene note for the next reuse.)*
- **Effector models at module scope, hooks in render.** `createForm`/`createCooldown`/`createFormatterModel`
  and inline stores live at module top level (shared, stable); the `use*` hooks are called inside the render
  component (Storybook treats `render` as a component).
- **Type every enum option array by the exported union** (`const TONES: AlertTone[] = [...]`) — the
  compile-time NO-INVENT guard. A non-exported type import or an invented member fails `tsc`.
- **Commit only when asked, pathspec only.** Everything is under `mercury/apps/storybook/stories/effector/`
  (+ `docs/mercury/specs/mx.5/`); re-verify `git diff --cached --name-only` is purely the mx.5 surface
  before any commit. Never `git add -A`; never `pnpm -r` (use `--filter`).
- **Framing (propagate):** no gendered pronouns for agents; no perceptual/interior-state verbs; no
  first-person narration. State each surface as a contract.
