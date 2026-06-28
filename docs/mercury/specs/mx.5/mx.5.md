# MX.5 · Effector-powered Storybook stories

> **Status: ✅ BUILT — gate-green (2026-06-29), verified post-build.** Shipped as six effector story
> files under `apps/storybook/stories/effector/`; barrel byte-identical (INV-1); full gate exits 0;
> `sb:build` registers 42 homes (prior 36 + the six `Effector/*`). The §9 as-built records the shipped
> wiring. The third rung of
> **Movement III (the Design System Storybook)**. mx.3 landed the **host** (`apps/storybook/`, Storybook
> 10.4.6, source-resolved, a light/`dark-theme` decorator); mx.4 filled the **library** side of the host's
> glob (a co-located `<Name>.stories.tsx` for every component — 35 component homes + the host `Tokens`
> = **36** registered homes) and grew the barrel additively (the focused trio). mx.5 fills the **state**
> side: a set of host-home stories that wire `@mercury/effector`'s live state into `@mercury/ui`
> components — proving the canon §1 contract that **components stay presentational and `@mercury/effector`
> plugs the state from the outside**.
>
> **Risk: NORMAL — and the `@mercury/ui` public surface is FROZEN this rung.** mx.4 *grew* the barrel
> (two new components); mx.5 *freezes* it: the rung adds **only** new story files under the Storybook
> host and touches **no** `@mercury/ui` `.tsx`/`index.ts`. The master invariant for this run is the
> **strongest** form — `packages/mercury-ui/src/index.ts` is **byte-identical** to HEAD (not merely
> additions-only). Load-bearing hazards: (a) a story citing an effector symbol or a component prop the
> source does not define — NO-INVENT, caught by `sb:typecheck` (the host `tsc`, the authoritative story
> type-check since the library `tsc` excludes `**/*.stories.tsx`, mx.4 `D-10`); (b) the theme adapter's
> `initTheme()` mutating global `<html>` and leaking across stories or fighting the mx.3 toolbar
> decorator (Arm A); (c) a non-deterministic `new Date()` at module load making the Formatter story's
> rendered value drift (use a fixed sample Date).
>
> **The decisions this rung carries (Operator-ruled — recorded VERBATIM for ratification at ship):**
> - **mx.5 = effector-powered Storybook stories ONLY.** Stories that wire `@mercury/effector`'s live
>   state into `@mercury/ui` components, proving "components stay presentational; effector plugs the
>   state" (canon §1, the `@mercury/effector` row).
> - **mx.5 does NOT touch `@mercury/ui`'s public surface** — the barrel stays byte-identical. No
>   `.tsx`/`index.ts` edit under `packages/mercury-ui/src/components/**` except, if genuinely
>   unavoidable, a non-export-changing fix that MUST be flagged.
> - **Re-sequenced (Operator-ruled):** the apps-side Pages → **mx.6** (model: page-level
>   `*.stories.tsx` co-located in `apps/*/src/`, wiring real `@mercury/ui` + `@mercury/effector`; the five
>   apps `showcase/echomq/mobile/catalogue/docs` are being completely rewritten with Mercury DS and
>   retired from the workspace when the mx program finishes; `codemojex-node/apps/economy` is OUT of
>   scope). Build/deploy + design-sync re-align → **mx.7**.
>
> These big forks are RULED — this triad does not re-litigate them. The three **residual minor forks**
> below (Arms A/B/C) are the only open calls.

Canon: [`../../mercury.design.md`](../../mercury.design.md) · roadmap:
[`../../mercury.roadmap.md`](../../mercury.roadmap.md) · dashboard:
[`../../mercury.progress.md`](../../mercury.progress.md) · prior triad:
[`../mx.4/mx.4.md`](../mx.4/mx.4.md) · contract template:
[`../../contracts.md`](../../contracts.md) · method:
[`../../../aaw/aaw.framework.md`](../../../aaw/aaw.framework.md) · acceptance:
[`mx.5.stories.md`](./mx.5.stories.md) · build context: [`mx.5.llms.md`](./mx.5.llms.md).

---

## A · Residual minor forks — Director ratifies (or surfaces to the Operator)

Three placement/mechanism calls remain. Each is a `D-4`-class judgment (not a correctness claim);
all three carry a Venus recommendation. The big scope forks (above) are already ruled.

### Arm A — the theme story: **augment** the mx.3 decorator (RECOMMENDED) vs **replace** it

- **Rationale.** The mx.3 preview decorator (`apps/storybook/.storybook/preview.tsx`) flips theme from
  the Storybook **global toolbar** — it sets a `${theme}-theme` class on a *scoped wrapper div* driven by
  `context.globals.theme`, and deliberately does **not** depend on `@mercury/effector`'s `initTheme()`.
  The theme adapter (`$theme` · `setTheme` · `toggleTheme` · `useTheme` · `initTheme`) is the *other*
  theme mechanism: `initTheme()` writes the class onto `document.documentElement` (`<html>`) and persists
  to `localStorage`. The fork is how the Theme **story** demonstrates the adapter without these two
  mechanisms colliding.
- **5W.** *Who:* the Theme story author + the Director (host owner). *What:* whether the global toolbar
  decorator stays as-is. *When:* this rung. *Where:* `stories/effector/Theme.stories.tsx` (augment) vs
  `.storybook/preview.tsx` (replace). *Why:* a single source of theme truth per story, no cross-story leak.
- **Steelman (augment, RECOMMENDED).** The Theme story is **self-contained**: it reads `useTheme()` and
  applies `${theme}-theme` to its **own** in-render wrapper, with an in-story `Switch`/`Button` calling
  `toggleTheme()`/`setTheme()` — it **never** calls `initTheme()` (no global `<html>`/`localStorage`
  mutation, no leak into the 41 other stories, no fight with the toolbar). The mx.3 toolbar keeps working
  for every other story. Zero host-config edit; the barrel + host stay frozen.
- **Steelman (replace).** Rewiring `preview.tsx` to drive its decorator off `$theme` would make the
  global toolbar a *live demo* of the adapter for the whole Storybook. But it couples the host to
  `@mercury/effector`, calls `initTheme()` (global mutation), risks cross-story leakage and a persisted
  `localStorage` value surprising later runs, and edits host config the Operator's scope ruled minimal.
- **Steward / recommendation: AUGMENT.** The story owns its theme locally; `preview.tsx` is untouched.
  This keeps INV-2 (UI/host surface untouched) and the no-leak property. *(Director-ratifiable.)*

### Arm B — story home: **the host `stories/effector/` home** (RECOMMENDED) vs library co-located vs apps

- **Rationale.** An effector story is a **cross-component pattern** — one adapter (e.g. `createForm`) wires
  *several* `@mercury/ui` components at once; it is not owned by any single component folder.
- **5W.** *Who:* the story authors. *What:* where the six files live. *When:* this rung. *Where:*
  `apps/storybook/stories/effector/` (host home) vs `packages/mercury-ui/src/components/<group>/<Name>/`
  (library) vs `apps/*/src/` (apps). *Why:* the host glob + the mx.4 "1:1 component↔story" invariant.
- **Steelman (host home, RECOMMENDED).** `apps/storybook/stories/` is exactly where the cross-cutting
  `Tokens.stories.tsx` already lives (a render-based story with *no single component*). The host glob
  `../stories/**/*.stories.@(tsx|ts)` already spans `stories/effector/**` (verified), and the host
  tsconfig `include` already covers `stories/**/*.tsx` — **zero** host wiring. It keeps the library's
  `count(*.stories.tsx) == count(component folders) == 35` invariant (mx.4 S-1) intact, because no
  story is added under `packages/mercury-ui/`.
- **Steelman (library co-located).** Co-locating under a component folder would break the mx.4 1:1 count
  (a folder would carry two stories) and mis-attribute a cross-component pattern to one component.
- **Steelman (apps).** Apps-side stories are **mx.6** (Operator-ruled) — out of scope this rung.
- **Steward / recommendation: HOST HOME `apps/storybook/stories/effector/`.** *(Director-ratifiable.)*

### Arm C — file layout: **one file per adapter** (RECOMMENDED) vs one grouped file

- **Rationale.** Six adapters, each with a Playground + scenarios. One file per adapter gives a clean
  1:1 adapter↔story-home and a parallelizable build (one author per file).
- **5W.** *Who:* the story authors. *What:* six files vs one. *When:* this rung. *Where:*
  `stories/effector/{Theme,Toast,Form,Strength,Cooldown,Formatter}.stories.tsx`. *Why:* navigability +
  the `sb:build` home count.
- **Steelman (one-file-per-adapter, RECOMMENDED).** Six titles `Effector/Theme` … `Effector/Formatter`
  read as a clean sidebar group; each file is small, single-author, and independently gateable; the
  `sb:build` home delta is exactly **+6** (36 → 42).
- **Steelman (one grouped file).** A single `Effector.stories.tsx` with six exports is fewer files, but a
  larger file, a single `title`, mixed concerns, and a non-parallel author — and it muddies the +6 home
  count (one home with six stories).
- **Steward / recommendation: ONE FILE PER ADAPTER (six files).** *(Director-ratifiable.)*

> **Not a fork — a build mechanism, recorded:** the **strength** story binds the password value into an
> effector store (§5 K-2) — `passwordStrength` itself is a *pure* function. Use a tiny inline
> `createStore<string>("")` + `createEvent<string>()` (primary) or a single-field `createForm` (alt);
> either keeps the value in Effector. This is implementor latitude, not an Operator fork.

---

## 0 · The slice — what mx.5 builds, and why effector-wired stories

Movement III's destination is a complete, browsable Design System Storybook. mx.3 proved the host renders
the library from source under a theme decorator. mx.4 gave **every component** a co-located story. mx.5
adds the **dimension mx.4 deliberately left empty**: live application **state**. Today the Storybook shows
each component in isolation, driven by static Storybook controls. `@mercury/effector` is the package whose
whole job is to wire live state into those presentational components from the outside — and nothing in the
host yet *demonstrates* that contract. mx.5 builds **six host-home stories, one per `@mercury/effector`
adapter**, each rendering the adapter's live Effector stores/events through `effector-react` into the real
`@mercury/ui` component(s) it naturally drives. The proof a browser reads: the component never gains state;
the adapter plugs it from outside, and the UI reacts.

What mx.5 is **not**: it adds **no** `@mercury/ui` surface (the barrel is byte-identical), **no** host
config edit (the host already depends on and aliases `@mercury/effector` — §4), and **no** apps-side Page
(those are mx.6). The whole diff is six new files under `apps/storybook/stories/effector/` plus this triad.

## 1 · Goal

After mx.5, the Storybook carries an **`Effector/`** story group with **one story home per adapter** —
`Theme · Toast · Form · Strength · Cooldown · Formatter` — each wiring the adapter's live Effector state
into the real `@mercury/ui` component(s) at the real prop surface. Concretely: six CSF3 files under
`apps/storybook/stories/effector/`, each importing only real `@mercury/effector` + `@mercury/ui` exports
(+ `react`/`effector`/`effector-react`/`@storybook/react-vite`), each rendering through the adapter's
hooks (`useTheme`/`useToasts`/`useForm`/`useCooldown`/`useFormatter` and the `useUnit` primitive). `pnpm
sb:build` registers **exactly the prior 36 homes + the 6 new `Effector/*` homes = 42** and exits 0;
`pnpm sb:typecheck` exits 0 (the compile-time NO-INVENT gate); the three packages typecheck/build and the
five product apps build, undisturbed. **The `@mercury/ui` barrel is byte-identical to HEAD; no component
`.tsx`/`index.ts` is edited; no host `.storybook/`/`tsconfig`/`vite`/`package.json` is edited.**

## 2 · Rationale (5W)

- **Why.** A presentational design system is only half-documented until the *state plug* is shown. The
  canon's load-bearing claim (§1) is that `@mercury/ui` "has no idea Effector exists" and
  `@mercury/effector` wires it from the outside. A Storybook that never demonstrates that wiring leaves the
  contract unproven to the human/agent who browses it. Six effector stories make the contract visible and
  give Mercury contributors a copy-paste reference for the apps-side Pages (mx.6).
- **What.** Six host-home CSF3 stories, one per adapter, each effector-bound (live stores via
  `effector-react`) and wired into the adapter's real `@mercury/ui` component(s): Theme→the `dark-theme`
  flip via a `Switch`; Toast→`Button`s firing `toast.*` + a `<Toaster/>` of live `Alert`s; Form→`createForm`
  driving `Input`s + a submit `Button`; Strength→`passwordStrength` over a live-state field → a
  `PasswordStrength` meter + a `Checklist`; Cooldown→`createCooldown` driving a resend `Button` beside an
  `AuthCode`; Formatter→`createFormatterModel` driving a `Stat` (and text) showing a live locale-formatted
  date.
- **Who.** *Authored by* Claude Code as Director-led architect (this triad) + the story-author wave(s).
  *Consumed by* — (1) Mercury contributors + the Claude Design agent browsing the live-state patterns;
  (2) **mx.6** (the apps-side Pages), which copy these wirings into real screens; (3) the canon §1 contract,
  which these stories make demonstrable.
- **When.** Now — Movement III, after the library coverage (mx.4) and before the apps-side Pages (mx.6).
- **Where.** Only `apps/storybook/stories/effector/` (six new files) + `docs/mercury/specs/mx.5/`.

## 3 · The adapter surface (reconciled — read the source, not the roadmap)

`packages/mercury-effector/src/` ships **SIX** adapters. The **roadmap row mx.5** names only four
(`theme · toast · createForm · createCooldown`) — that row **lags**; the **design canon §1** correctly names
all six (`theme · toast · form · strength · cooldown · formatter`). mx.5 covers **all six** (the roadmap
re-sync is the Director's fold at ship — Venus does not edit the roadmap). The exact public surface, traced
from `packages/mercury-effector/src/index.ts` (re-exports all six modules):

| # | Adapter (file) | Public symbols (exact, from source) | Effector-bound? |
|---|---|---|---|
| 1 | `theme.ts` | `Theme` · `setTheme` · `toggleTheme` · `$theme` · `initTheme()` · `useTheme()` | yes (store) |
| 2 | `toast.tsx` | `ToastOptions` · `ToastItem` · `showToast` · `dismissToast` · `clearToasts` · `$toasts` · `toast` · `useToasts()` · `ToasterPosition` · `Toaster` | yes (store + effect) |
| 3 | `form.ts` | `FormErrors` · `FormConfig` · `FieldBinding` · `createForm(config)` → `{ $values, $errors, $touched, $isValid, $submitting, changed, blurred, submitted, reset, submit, useField, useForm }` | yes (factory) |
| 4 | `strength.ts` | `StrengthVariant` · `PasswordRules` · `PasswordStrengthResult` · `passwordStrength(pwd)` → `{ score, label, variant, rules }` | **no — pure** (the story supplies the effector state; see Arm-C note) |
| 5 | `cooldown.ts` | `createCooldown()` → `{ $remaining, start(s), stop(), useCooldown() }` | yes (factory) |
| 6 | `formatter.ts` | `FormatterModelOptions` · `FormatterModel` · `createFormatterModel(opts)` → `{ $locale, $monthFormat, $yearFormat, setLocale, setMonthFormat, setYearFormat, formatter, useFormatter() }` | yes (factory) |

## 4 · Host wiring — RECONCILED: nothing to add

The task brief asked whether the host must add the effector dep / source alias / tsconfig path. **The
reconcile finds it is already wired** (mx.4 left it ready); the four host claims are all **MATCH**, so
mx.5 adds **zero** host config:

| Host claim | As-built (cited) | Verdict |
|---|---|---|
| Host depends on `@mercury/effector` | `apps/storybook/package.json` deps: `@mercury/effector` + `effector` `^23.3.0` + `effector-react` `^23.3.0` | MATCH — present |
| Host aliases `@mercury/effector` from source | `apps/storybook/vite.config.ts` `resolve.alias["@mercury/effector"] → ../../packages/mercury-effector/src/index.ts` | MATCH — present |
| `@mercury/effector` resolves for `sb:typecheck` | `apps/storybook/tsconfig.json` `paths["@mercury/effector"]` + `include: ["stories/**/*.tsx", …]` | MATCH — present; `stories/effector/**` is covered |
| The story glob picks up the new home | `apps/storybook/.storybook/main.ts` `"../stories/**/*.stories.@(tsx|ts)"` (resolves from `.storybook/`) | MATCH — `stories/effector/**` matches |
| The gate scripts exist | root `package.json`: `sb:typecheck` = `pnpm --filter @mercury/storybook typecheck`; `sb:build` = `pnpm --filter @mercury/storybook build` | MATCH — present (mx.4 `D-10`) |

> **If a build step nonetheless reveals a missing host edit, STOP and report it** — adding a host dep or
> alias is a scope change the Operator ruled out, not an implementor call. The reconcile says none is
> needed.

## 5 · Deliverables

- **K-1 — six effector story files** under `apps/storybook/stories/effector/`, one per adapter:
  `Theme.stories.tsx · Toast.stories.tsx · Form.stories.tsx · Strength.stories.tsx · Cooldown.stories.tsx
  · Formatter.stories.tsx` (Arm B/C). Each is CSF3 (`Meta`/`StoryObj`), `title: "Effector/<Adapter>"`,
  with a Playground/primary story + ≥1 scenario.
- **K-2 — each story is effector-bound, not static.** Every story renders the adapter's live Effector
  state through `effector-react` (`useTheme`/`useToasts`/`useForm`/`useCooldown`/`useFormatter`, or the
  `useUnit` primitive for the strength field) — a Storybook reload reflects store updates. The strength
  story holds its password value in an Effector store (Arm-C note).
- **K-3 — each story wires the adapter into its real `@mercury/ui` component(s)** at the real prop surface
  (§3 table → §6 wiring map). Every prop is verified against the component `.tsx`; every enum option is
  typed by the component's exported union (NO-INVENT).
- **K-4 — the `@mercury/ui` public surface is byte-identical.** No edit to `packages/mercury-ui/src/index.ts`
  (barrel) and no edit to any `packages/mercury-ui/src/components/**` `.tsx`/`index.ts`. (Any unavoidable
  non-export-changing fix is flagged and surfaced, per the Operator ruling.)
- **K-5 — the host is unedited.** No change under `apps/storybook/.storybook/`, `apps/storybook/tsconfig.json`,
  `apps/storybook/vite.config.ts`, or `apps/storybook/package.json` (§4). The six story files are the whole
  code diff.
- **K-6 — the gate is green** (§7): `sb:typecheck` 0 · `sb:build` exit 0 registering **42** homes (prior 36
  + 6 new `Effector/*`) · `pnpm --filter "./packages/*" typecheck`/`build` 0 · the five product apps build
  · barrel byte-identical · the NO-INVENT + token greps empty.

**Coverage:** K-1 → S-1..S-6 (one per adapter) ; K-2 → S-1..S-6 ; K-3 → S-1..S-6 ; K-4 → S-7 ; K-5 → S-8 ;
K-6 → S-9.

## 6 · The per-adapter wiring map (grounded — `.tsx` + mx.2 contract cited)

Each row: the adapter symbols the story imports → the `@mercury/ui` component(s) it wires → the **exact**
prop surface (verified in the component `.tsx`; cross-checked against the component's mx.2 `<Name>.prompt.md`).

### 6.1 · Theme → `Switch` (+ the `dark-theme` token flip)
- **Adapter:** `useTheme()` → `"light"|"dark"`; `toggleTheme()`; `setTheme(t)`; `$theme`.
- **Component:** `Switch` — `SwitchProps { checked?: boolean; onChange?: (checked: boolean) => void; label?: ReactNode; disabled?; name?; id? }` (`selection/Switch/Switch.tsx`; contract `Switch.prompt.md`).
- **Wiring:** the story renders an in-render wrapper `<div className={`${theme}-theme`} …>` (theme from
  `useTheme()`) containing `<Switch checked={theme === "dark"} onChange={() => toggleTheme()} label="Dark theme" />`
  and a few sample components (e.g. a `Button` + an `Alert`) so the live token flip is visible. **Does NOT
  call `initTheme()`** (Arm A — no global `<html>`/`localStorage` mutation). May also show a `setTheme`
  pair (e.g. two `Button`s "Light"/"Dark").

### 6.2 · Toast → `Button` (triggers) + `<Toaster/>` (renders `Alert`s)
- **Adapter:** `toast.success/error/warning/info(msg)` · `showToast(opts)` · `clearToasts()` ·
  `useToasts()` · `<Toaster position?=… />` (`ToasterPosition = "top-end"|"bottom-end"|"bottom-center"`).
- **Components:** `Button` (fires the events); `Toaster` renders live `Alert`s internally —
  `AlertTone = "info"|"success"|"warning"|"danger"` and `toast.error` maps to `tone: "danger"`
  (`feedback/Alert/Alert.tsx`; `toast.tsx`).
- **Wiring:** a row of `Button`s — `<Button variant="primary" onClick={() => toast.success("Saved")}>`,
  `… toast.error(…)`, `… toast.warning(…)`, `… toast.info(…)`, and a `<Button variant="ghost"
  onClick={() => clearToasts()}>Clear</Button>` — plus a single `<Toaster position="bottom-end" />` in the
  render. Live toasts auto-dismiss (the adapter's `autoDismissFx`).

### 6.3 · Form → `Input` (fields) + `Button` (submit)
- **Adapter:** `createForm({ initialValues, validate?, onSubmit? })` → `useForm()` (`{ values, errors,
  touched, isValid, submitting, setField, submit, reset }`) + `useField(name)` (`{ value, error, onChange,
  onBlur }`).
- **Components:** `Input` — `InputProps extends Omit<InputHTMLAttributes,"size"> { label?; hint?; error?;
  leading?; trailing? }` (`inputs/Input/Input.tsx`); `Button` with `loading` (`actions/Button/Button.tsx`,
  `ButtonProps.loading?: boolean`, `type?: "button"|"submit"|"reset"`).
- **Wiring:** `const field = useField("email")` → `<Input label="Email" value={field.value}
  onChange={(e) => field.onChange(e.target.value)} onBlur={field.onBlur} error={field.error} />`
  (`useField.onChange` is value-based, so adapt the DOM event). Submit: `const f = useForm()` →
  `<Button type="submit" loading={f.submitting} disabled={!f.isValid} onClick={() => void f.submit()}>`.
  Define `createForm` at **module scope** (a single shared model for the story file) with a `validate` that
  returns a `FormErrors` map.

### 6.4 · Strength → `Input` (password) + `PasswordStrength` (meter) + `Checklist` (rules)
- **Adapter:** `passwordStrength(pwd)` → `{ score: number; label: ""|"Weak"|"Fair"|"Strong"; variant:
  "negative"|"caution"|"positive"; rules: { length, mixedCase, number, symbol } }` (`strength.ts`). The
  password value is held in an **Effector store** the story creates (Arm-C note).
- **Components:** `Input` (`type="password"`, value/onChange as 6.3); `PasswordStrength` —
  `PasswordStrengthProps { score: number; label?: string; variant?: StrengthVariant; className? }`
  (`feedback/PasswordStrength/PasswordStrength.tsx`); `Checklist` — `ChecklistProps { items: ChecklistItem[]
  }`, `ChecklistItem { label: ReactNode; met: boolean }` (`data-display/Checklist/Checklist.tsx`).
- **Wiring:** `const pwd = useUnit($pwd)` (the story's inline store); `const s = passwordStrength(pwd)`;
  `<Input type="password" value={pwd} onChange={(e) => setPwd(e.target.value)} />`,
  `<PasswordStrength score={s.score} label={s.label} variant={s.variant} />`, and
  `<Checklist items={[{ label: "8+ characters", met: s.rules.length }, { label: "Upper & lower case",
  met: s.rules.mixedCase }, { label: "A number", met: s.rules.number }, { label: "A symbol",
  met: s.rules.symbol }]} />`. (The `StrengthVariant` from `strength.ts` and the one from `PasswordStrength.tsx`
  are the identical union `"negative"|"caution"|"positive"`, so `s.variant` types straight into the prop.)

### 6.5 · Cooldown → `Button` (resend) [+ `AuthCode`]
- **Adapter:** `createCooldown()` → `{ $remaining, start(seconds), stop(), useCooldown() }`.
- **Components:** `Button` (`disabled`, dynamic label) (`actions/Button/Button.tsx`); `AuthCode` —
  `AuthCodeProps { value: string; onChange: (v) => void; onComplete?; length?; allow?: "numeric"|"alphanumeric";
  error?; disabled? }` (`inputs/AuthCode/AuthCode.tsx`) shown as the affordance the cooldown gates.
- **Wiring:** `const remaining = useCooldown()` →
  `<Button variant="secondary" disabled={remaining > 0} onClick={() => start(30)}>{remaining > 0 ? `Resend in ${remaining}s` : "Resend code"}</Button>`;
  beside an `<AuthCode value={code} onChange={setCode} length={6} allow="numeric" />` (the code value held
  in a small inline store or `useState` — the *cooldown* is the effector demo; the `AuthCode` value is
  presentational context). Author the `createCooldown()` model at module scope.

### 6.6 · Formatter → `Stat` (live-formatted date) + a locale control
- **RECONCILE — CORRECTION:** the task hint "formatter → `MoneyInput`/`Stat`" is **INVENTED for
  `MoneyInput`**. `createFormatterModel` wraps `@mercury/ui`'s `createFormatter` → a **date/locale**
  `Formatter` (`fullMonthAndYear` · `selectedDate` · `fullMonth` · `fullYear` · `dayOfWeek` · `dayPeriod` …,
  all `Intl.DateTimeFormat`-based); it does **not** format money, and `MoneyInput` (`inputs/MoneyInput/MoneyInput.tsx`)
  takes **no formatter input** — it is a plain `Input` + a static `currency` prefix. So the formatter
  adapter wires a **date display**, not `MoneyInput`. Corrected target: `Stat` + raw text.
- **Adapter:** `createFormatterModel(opts)` → `{ $locale, $monthFormat, $yearFormat, setLocale,
  setMonthFormat, setYearFormat, formatter, useFormatter() }`; `MonthFormat`/`YearFormat` are
  `Intl.DateTimeFormatOptions["month"]|"year"` (string) or a mapper fn (from `@mercury/core`/`@mercury/ui`).
- **Components:** `Stat` — `StatProps { label: string; value: ReactNode; delta?; deltaTone?: StatTone;
  hint?; leading?; align? }` (`data-display/Stat/Stat.tsx`); a `Select` (`SelectOption { label; value;
  disabled? }`) or `Segmented` for the locale; a `Select`/`Segmented` for month/year style.
- **Wiring:** `const fmt = useFormatter()` → `<Stat label="Member since" value={fmt.fullMonthAndYear(SAMPLE)} />`
  where `const SAMPLE = new Date(2026, 0, 15)` is a **fixed** module-scope Date (NO `new Date()` at load —
  determinism). A `<Select label="Locale" options={[{label:"English (US)",value:"en-US"}, {label:"Français",
  value:"fr-FR"}, {label:"日本語",value:"ja-JP"}, {label:"Deutsch",value:"de-DE"}]} onChange={(e) =>
  setLocale(e.target.value)} />` re-renders the `Stat` live; a month-style control calls `setMonthFormat`
  with a valid `Intl` month value (`"long"|"short"|"narrow"|"numeric"|"2-digit"`). Author the
  `createFormatterModel()` model at module scope.

## 7 · Invariants — as runnable gates

Run from `mercury/`. Each invariant is the check that proves it, not prose.

- **INV-1 — the barrel is byte-identical (the master invariant, strongest form).**
  `diff <(git show HEAD:packages/mercury-ui/src/index.ts) packages/mercury-ui/src/index.ts` → **empty**.
  Not "additions-only" (mx.4) — **byte-identical** this rung.
- **INV-2 — the `@mercury/ui` surface + the host are untouched.**
  `git diff --name-only` shows **no** path under `packages/mercury-ui/src/` and **no** path under
  `apps/storybook/` *except* the six new `apps/storybook/stories/effector/*.stories.tsx` (and this triad).
  (Any unavoidable non-export-changing component fix is flagged + surfaced — not silently made.)
- **INV-3 — `sb:typecheck` clean (the authoritative NO-INVENT gate).** `pnpm sb:typecheck` exits 0. This
  is where an invented effector symbol or a wrong component prop fails to compile (the host `tsc` is the
  only `tsc` that checks stories — the library `tsc` excludes `**/*.stories.tsx`, mx.4 `D-10`).
- **INV-4 — `sb:build` registers exactly the prior 36 homes + the 6 new `Effector/*` homes (= 42).**
  `pnpm sb:build` exits 0; the built index lists `Effector/Theme`, `Effector/Toast`, `Effector/Form`,
  `Effector/Strength`, `Effector/Cooldown`, `Effector/Formatter` **and** all 36 prior homes unchanged.
- **INV-5 — packages typecheck/build + the five product apps build, undisturbed.**
  `pnpm --filter "./packages/*" typecheck` = 0 · `pnpm --filter "./packages/*" build` = 0 ·
  `pnpm --filter "./apps/*" --filter "!@mercury/storybook" build` = 0.
- **INV-6 — NO-INVENT.** Every imported effector symbol is a real `@mercury/effector` export; every wired
  component prop is defined in the component `.tsx`; every enum option array is typed by the component's
  exported union (`const TONES: AlertTone[] = […]`); no story contains `window.MercuryUI` or `_ds_bundle`;
  no `new Date()` at module load (use a fixed sample). Greps:
  `grep -rn "window.MercuryUI\|_ds_bundle" apps/storybook/stories/effector` → **empty**.
- **INV-7 — token discipline.** No raw hex in the stories; any layout color uses `rgb(var(--token))`
  (canon §6); components are styled through their enum props. Grep:
  `grep -rnE "#[0-9a-fA-F]{3,8}\b" apps/storybook/stories/effector` → **empty** (a hex literal is a fail).

## 8 · Out of scope (explicit)

- Any `@mercury/ui` component change, any new export, any `index.ts` edit (mx.5 freezes the surface).
- Any host `.storybook/`/`tsconfig`/`vite`/`package.json` edit (already wired — §4).
- Any apps-side Page or apps-side `*.stories.tsx` (**mx.6**, Operator-ruled).
- Build/deploy of the static Storybook + the design-sync re-align (**mx.7**, Operator-ruled).
- Editing the roadmap/progress/design (the Director folds the roadmap's stale four-adapter row + the
  re-sequence + a new `D-11` at ship).

## 9 · As-built (Apollo / the verifier — filled post-build, 2026-06-29)

Verified independently post-build. Every promise (K-1..K-6, INV-1..INV-7, S-1..S-9) classifies **MATCH**;
no STALE/INVENTED/MISSING. Verdict: **BUILD-GRADE.**

### The six shipped files (all NEW, host home — Arms B/C honored)
- `apps/storybook/stories/effector/Theme.stories.tsx`
- `apps/storybook/stories/effector/Toast.stories.tsx`
- `apps/storybook/stories/effector/Form.stories.tsx`
- `apps/storybook/stories/effector/Strength.stories.tsx`
- `apps/storybook/stories/effector/Cooldown.stories.tsx`
- `apps/storybook/stories/effector/Formatter.stories.tsx`

Each is CSF3 (`Meta`/`StoryObj`), `title: "Effector/<Adapter>"`, **no `component:` field** (cross-component,
like `Tokens.stories.tsx`), a leading NO-INVENT trace comment, a `Playground` story **plus a second named
scenario** (so all six exceed the ≥1-scenario floor: `ExplicitButtons`, `TopEnd`, `SingleField`, `Strong`,
`ShortCooldown`, `Comparison`).

### Gate reproduced (run from `mercury/`, all EXIT 0)
- `pnpm sb:typecheck` → 0 (the authoritative NO-INVENT gate — every imported effector symbol + every wired
  component prop compiles).
- `pnpm --filter "./packages/*" typecheck` → 0 · `pnpm --filter "./packages/*" build` → 0.
- `pnpm --filter "./apps/*" --filter "!@mercury/storybook" build` → 0 — the **five** product apps build
  (`catalogue · docs · echomq · mobile · showcase`).
- `pnpm sb:build` → 0; **42** distinct homes = the prior 36 unchanged + the six new
  `Effector/{Theme,Toast,Form,Strength,Cooldown,Formatter}` (INV-4).
- **INV-1** `diff <(git show HEAD:packages/mercury-ui/src/index.ts) packages/mercury-ui/src/index.ts` →
  **empty** (byte-identical, strongest form).
- **INV-2** `git status` over `mercury/`: the only mx.5 paths are the six untracked
  `apps/storybook/stories/effector/*.stories.tsx` (+ this triad). **No** edit under
  `packages/mercury-ui/src/` and **no** edit under `apps/storybook/` config — no flagged non-export-changing
  component fix was needed.
- **INV-6/7** greps over `apps/storybook/stories/effector`: `window.MercuryUI`/`_ds_bundle` empty; raw-hex
  empty; `new Date()` (no-arg) absent from `Formatter.stories.tsx` (the `SAMPLE` is a fixed `new Date(2026,
  0, 15)`); no `initTheme` **import** in `Theme.stories.tsx` (Arm A — the three `initTheme` grep hits are
  NO-INVENT *comments* explaining the omission, not a call).

### The resolved per-adapter wiring as shipped
- **Theme** — `ThemedCard` applies `${theme}-theme` to its **own** in-render wrapper from `useTheme()`
  (Arm A: never `initTheme()`, no `<html>`/`localStorage` leak). `Switch checked={theme === "dark"}
  onChange={() => toggleTheme()} label="Dark theme"`; an `ExplicitButtons` scenario pairs
  `setTheme("light")`/`setTheme("dark")` (`Button variant="outline"`). Sample `Button`s (`primary` /
  `secondary`) + an `Alert tone="info"` make the token flip visible.
- **Toast** — a trigger row of `Button`s (`variant` `primary`/`destructive`/`secondary`/`secondary`/`ghost`,
  all real `ButtonVariant` members) firing `toast.success/error/warning/info` + `clearToasts`; a single
  `<Toaster position="bottom-end" />` (Playground) and a `TopEnd` scenario (`position="top-end"`).
  `toast.error → "danger"` tone is the adapter's mapping (`toast.tsx:57`).
- **Form** — **two** module-scope `createForm` models: `signInForm` (`email`+`password`, `validate` →
  `FormErrors`, async `onSubmit` ~800 ms) and `newsletterForm` (single `email`, ~600 ms). Each `Input` binds
  via `useField` with the DOM→value adapter `onChange={(e) => field.onChange(e.target.value)}` +
  `onBlur`/`error`; submit `Button type="submit" loading={form.submitting} disabled={!form.isValid}`; the
  `<form onSubmit>` calls `void model.submit()`.
- **Strength** — the password value lives in an **inline Effector store** (`createStore<string>` +
  `createEvent<string>`, read via `useUnit`), per the Arm-C note. Two stores (`$pwd` empty, `$strong`
  pre-filled `"Sup3r-Secret!"`) drive a shared `StrengthPanel`: `passwordStrength(pwd)` →
  `<PasswordStrength score/label/variant>` (the `"negative"|"caution"|"positive"` union types straight in)
  + a four-item `<Checklist>` mapping `rules.{length,mixedCase,number,symbol}`.
- **Cooldown** — two module-scope `createCooldown()` models (`cooldown` 30 s, `quick` 5 s). `useCooldown()`
  drives `disabled={remaining > 0}` + the label `remaining > 0 ? "Resend in ${remaining}s" : "Resend code"`;
  an `<AuthCode length={6} allow="numeric">` sits beside it as the gated affordance, its value held in
  `useState` (presentational context — spec-permitted; the cooldown is the effector demo).
- **Formatter** — module-scope `createFormatterModel({ locale: "en-US" })` (locale **pinned** so controls
  and output start in sync, not `navigator.language`-dependent) + a **fixed** `const SAMPLE = new Date(2026,
  0, 15)`. The style arrays use `["long","short","narrow","numeric","2-digit"] as const satisfies readonly
  MonthFormat[]` (and the `YearFormat[]` pair) — a compile-time NO-INVENT guard that an invented `Intl`
  style fails. Three `<Select>`s (`Locale`/`Month style`/`Year style`) call
  `setLocale`/`setMonthFormat`/`setYearFormat` via the DOM `onChange`; `<Stat label="Member since"
  value={fmt.fullMonthAndYear(SAMPLE)} />` re-renders live. The `Comparison` scenario shows
  `fullMonthAndYear`/`fullMonth`/`fullYear`/`dayOfWeek(SAMPLE, "long")`. Wires **`Stat`, not `MoneyInput`**
  (the §6.6 reconcile correction is honored).

### Residual note for the Director (pathspec hygiene — not an mx.5 defect)
`git status` also shows `mercury/vitest.config.ts` **modified** (adds `"packages/*/src/**/*.test.{ts,tsx}"`
to the test `include`). It is outside the six stories + this triad, is unrelated to mx.5 (which adds no
tests) and is not on any mx.5 gate leg. The mx.5 `mercury/…` pathspec commit must include **only** the six
`apps/storybook/stories/effector/*.stories.tsx` + `docs/mercury/specs/mx.5/` — exclude `vitest.config.ts`
(commit it separately under its own concern, or leave it to the Operator's out-of-band staging).
