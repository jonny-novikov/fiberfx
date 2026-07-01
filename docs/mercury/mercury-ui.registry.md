# Mercury UI — the Component Registry & Developer Reference

The **single map** of `@mercury/ui`: every component, the category it lives in, its shipped/pending
status, its Storybook coverage, and the plan for the first-class **Developer Reference**
application (`apps/showcase`). It is the broad-audience entry point — a contributor, a consuming
app developer, or the Claude Design agent reads *this* to find a component, then follows the link to
its co-located contract (`<Name>.prompt.md`) and its stories (`<Name>.stories.tsx`).

> **Canon, not a second copy.** The architecture is [`mercury.design.md`](./mercury.design.md); the
> forward plan is [`mercury.roadmap.md`](./mercury.roadmap.md); the live dashboard is
> [`mercury.progress.md`](./mercury.progress.md); the contract format is
> [`contracts.md`](./contracts.md). This registry is the **as-built index** those documents point at.

> **Grounding (as-built 2026-06-30).** Every **shipped** row below is verified present on disk —
> `mercury/packages/mercury-ui/src/components/<group>/<Name>/` carries `<Name>.tsx`,
> `<Name>.stories.tsx`, `<Name>.prompt.md`, and `index.ts` for all 52. Story names are read from the
> `.stories.tsx` exports; prop axes from the `.tsx` source. **Pending** rows are forward-tense from
> the roadmap (`mx.7.3.3` · `mx.7.4` · `mx.7.5`) — they name a planned surface, not a shipped one.

---

## At a glance

| | Count |
|---|---|
| **Shipped components** | **55**, across **9 groups** — each with `.tsx` + `.stories.tsx` + `.prompt.md` + `index.ts` |
| **Storybook coverage** | **55 / 55** — every component has a co-located CSF3 story file (a `Playground` + variant/usage stories) |
| **Contract coverage** | **55 / 55** — every component carries a hand-authored `<Name>.prompt.md` (the `D-7` six-section shape) |
| **Pending (planned)** | **+11 rows** — `mx.7.3.3` (4 selection composites + `ToggleGroup` + a `Textarea` enrichment fold) · `mx.7.5` (6 menus/nav) |
| **Public surface** | every component exports from the `@mercury/ui` barrel — `import { <Name> } from "@mercury/ui"` |

The export surface only ever **grows** (the master invariant — additions OK; removals/renames are a
breaking change that stops a rung). Reusable components live **only** in `packages/*`; apps compose
them, they never house one.

---

## 1. The component catalogue (categorized · shipped + pending)

Nine groups, by the component's **primary role**. `✅` = shipped (on disk + on the barrel); `📋` =
planned (forward-tense from the roadmap). The **Origin** column names the rung that shipped (or will
ship) it.

### `foundations` — the primitives everything builds on
| Component | Status | Origin |
|---|---|---|
| `Icon` | ✅ | the original 33 (`mx.1`/`mx.2`) |
| `Divider` | ✅ | the original 33 |
| `Heading` | ✅ | `mx.7.1` |
| `Text` | ✅ | `mx.7.1` |
| `Separator` | ✅ | `mx.7.1` |

### `actions` — trigger an action
| Component | Status | Origin |
|---|---|---|
| `Button` | ✅ | the original 33 |
| `Link` | ✅ | the original 33 |
| `IconButton` | ✅ | `mx.7.1` |

### `inputs` — enter a value
| Component | Status | Origin |
|---|---|---|
| `Input` | ✅ | the original 33 |
| `Textarea` | ✅ | the original 33 *(enrichment fold planned `mx.7.3.3`)* |
| `Search` | ✅ | the original 33 |
| `Select` | ✅ | the original 33 |
| `AuthCode` | ✅ | the original 33 |
| `MoneyInput` | ✅ | `mx.4` |
| `Label` | ✅ | `mx.7.1` |
| `DateField` | ✅ | `mx.7.3.1` — segmented date entry; composes `@mercury/core` `useDateField` |
| `Calendar` | ✅ | `mx.7.3.2` — month-grid picker; composes `@mercury/core` `useCalendar` |

### `selection` — pick from a set
| Component | Status | Origin |
|---|---|---|
| `Checkbox` | ✅ | the original 33 |
| `Radio` | ✅ | the original 33 |
| `Switch` | ✅ | the original 33 |
| `Segmented` | ✅ | the original 33 |
| `Slider` | ✅ | the original 33 |
| `Toggle` | ✅ | the original 33 |
| `CheckboxGroup` | 📋 | `mx.7.3.3` |
| `CheckboxCards` | 📋 | `mx.7.3.3` |
| `RadioGroup` | 📋 | `mx.7.3.3` |
| `RadioCards` | 📋 | `mx.7.3.3` |
| `ToggleGroup` | 📋 | `mx.7.3.3` (fold) |

### `data-display` — present read-only data
| Component | Status | Origin |
|---|---|---|
| `Avatar` | ✅ | the original 33 |
| `Badge` | ✅ | the original 33 |
| `Chip` | ✅ | the original 33 |
| `Tag` | ✅ | the original 33 |
| `Card` | ✅ | the original 33 *(`title`/`actions` header props added `mx.4`)* |
| `Table` | ✅ | the original 33 |
| `Stat` | ✅ | the original 33 |
| `Chart` | ✅ | the original 33 |
| `Checklist` | ✅ | the original 33 |
| `ListRow` | ✅ | `mx.4` |
| `Blockquote` | ✅ | `mx.7.2` |
| `DataList` | ✅ | `mx.7.2` |
| `Code` | ✅ | `mx.7.2` |
| `Kbd` | ✅ | `mx.7.2` |

### `feedback` — system messages & status
| Component | Status | Origin |
|---|---|---|
| `Alert` | ✅ | the original 33 |
| `Progress` | ✅ | the original 33 |
| `PasswordStrength` | ✅ | the original 33 |
| `Callout` | ✅ | `mx.7.2` |
| `Spinner` | ✅ | `mx.7.2` |
| `Skeleton` | ✅ | `mx.7.2` |

### `navigation` — move between views
| Component | Status | Origin |
|---|---|---|
| `Tabs` | ✅ | the original 33 |
| `Accordion` | ✅ | the original 33 |
| `Pagination` | ✅ | the original 33 |
| `TabNav` | 📋 | `mx.7.5` — link-based nav tabs (distinct from the button/panel `Tabs`) |

### `overlay` — float above the page
| Component | Status | Origin |
|---|---|---|
| `Modal` | ✅ | the original 33 |
| `Tooltip` | ✅ | the original 33 |
| `Dialog` | ✅ | `mx.7.4` (on the new overlay floor) |
| `AlertDialog` | ✅ | `mx.7.4` |
| `Popover` | ✅ | `mx.7.4` |
| `Dropdown` | 📋 | `mx.7.5` |
| `ContextMenu` | 📋 | `mx.7.5` |
| `HoverCard` | 📋 | `mx.7.5` |
| `LinkPreview` | 📋 | `mx.7.5` |
| `Menubar` | 📋 | `mx.7.5` |

### `layout` — structural shells
| Component | Status | Origin |
|---|---|---|
| `AuthLayout` | ✅ | the original 33 |
| `AspectRatio` | ✅ | `mx.7.2` |
| `Collapsible` | ✅ | `mx.7.2` |
| `ScrollArea` | ✅ | `mx.7.2` |

> **`mx.7.4`/`mx.7.5` also ship a headless overlay floor** in `@mercury/core` (positioning +
> dismiss + focus-trap) that the overlay/menu components consume — the same compose-the-foundation
> pattern the date pair set (`useDateField`/`useCalendar`). It is a foundation primitive, not a
> `@mercury/ui` export, so it is not a catalogue row.

---

## 2. Storybook component status (the surface · the usage stories)

Two columns per component, read from the co-located `<Name>.stories.tsx`:

- **Surface — variants · colors · actions** — what the component *is*: the prop axes it varies on
  (`variant` · `size` · `accent` · `tone` · `state`) and the actions it fires, with the **axis
  stories** that demonstrate them (the `Playground` is the live controls/args explorer).
- **Usage stories** — what the component *does in place*: the **scenario stories** that compose it
  into a real situation (a header, a KPI row, a confirm dialog, a settings list…).

Colour shows through the **accent ramp** — `accent="iris | indigo | green | orange | plum | red"`
(see §3). `✦` marks a component that carries the `accent` prop.

### `foundations`
| Component | Surface — variants · colors · actions | Usage stories |
|---|---|---|
| `Icon` | `name` (≈333-glyph set) · `size` · `strokeWidth` — *Playground · Gallery* | *Gallery* (the full glyph catalogue) |
| `Divider` | resting / states — *Playground · States* | *Playground only* |
| `Heading` ✦ | `size` · `accent` (6-ramp) — *Playground · Sizes · Accents* | *Playground only* |
| `Text` ✦ | `variant` · `accent` (6-ramp) · `align` — *Playground · Variants · Accents* | *Playground only* |
| `Separator` | orientation / states — *Playground · States* | *Playground only* |

### `actions`
| Component | Surface — variants · colors · actions | Usage stories |
|---|---|---|
| `Button` | `variant` · `size` · `onClick` · leading-icon slot — *Playground · Variants* | *WithIcon* |
| `Link` | `size` · hover/visited/disabled states — *Playground · Sizes · States* | *Playground only* |
| `IconButton` | `variant` · `size` · `shape` · icon-only action — *Playground · Variants · SizesAndShapes* | *Playground only* |

### `inputs`
| Component | Surface — variants · colors · actions | Usage stories |
|---|---|---|
| `Input` | states (focus/error/disabled) · icon slot — *Playground · States* | *WithIcon* |
| `Textarea` | states · char counter — *Playground · States* | *WithCounter* |
| `Search` | states · clear action — *Playground · States* | *Playground only* |
| `Select` | states · listbox — *Playground · States* | *CalibratePackage* |
| `AuthCode` | `variant` · OTP segments — *Playground · Variants* | *Playground only* |
| `MoneyInput` | states · currencies — *Playground · States* | *Currencies* |
| `Label` ✦ | `accent` (6-ramp) · states — *Playground · States* | *Playground only* |
| `DateField` | segmented entry · controlled + uncontrolled — *Playground* | *Uncontrolled · Controlled* |
| `Calendar` ✦ | `accent` (6-ramp) · month paging · controlled + uncontrolled — *Playground · Accent* | *Uncontrolled · Controlled* |

### `selection`
| Component | Surface — variants · colors · actions | Usage stories |
|---|---|---|
| `Checkbox` | checked / indeterminate / disabled — *Playground · States* | *Playground only* |
| `Radio` | grouped selection — *Playground* | *Group* |
| `Switch` | on/off states — *Playground · States* | *Playground only* |
| `Segmented` | `size` · rail switch — *Playground · Sizes* | *RailSwitch* |
| `Slider` | `size` · calibration — *Playground · Sizes* | *Calibration* |
| `Toggle` | `size` · icon · group — *Playground · Sizes* | *WithIcon · Group* |

### `data-display`
| Component | Surface — variants · colors · actions | Usage stories |
|---|---|---|
| `Avatar` | `size` · status dot · image fallback — *Playground · Sizes · Statuses* | *WithImage* |
| `Badge` | `variant` · `size` — *Playground · Variants · Sizes* | *Playground only* |
| `Chip` | `variant` · `size` · leading icon · removable action — *Playground · Variants · Sizes* | *WithLeadingIcon · Removable* |
| `Tag` | `size` · tones · dotless — *Playground · Tones · Dotless* | *Playground only* |
| `Card` | `variant` (flat/raised/floating) · `title`/`actions` header slots — *Playground · Variants* | *WithHeader* |
| `Table` | column `align` — *Playground* | *PrizePool* |
| `Stat` | `align` · delta tones · leading icon — *Playground · DeltaTones* | *KpiRow · WithLeadingIcon* |
| `Chart` | data-driven (margin · curve) — *Playground* | *MarginCurve* |
| `Checklist` | item states — *Playground · States* | *Playground only* |
| `ListRow` | leading/trailing slots · row actions — *Playground* | *SettingsList · ActivityFeed* |
| `Blockquote` ✦ | `accent` (6-ramp) · `size` — *Playground · Sizes · Accents* | *Playground only* |
| `DataList` | `orientation` · `size` — *Playground · Orientations · Sizes* | *Playground only* |
| `Code` ✦ | `variant` · `accent` (6-ramp) · inline/block — *Playground · Variants · Accents* | *Block* |
| `Kbd` | `size` · key chords — *Playground · Sizes* | *Chord* |

### `feedback`
| Component | Surface — variants · colors · actions | Usage stories |
|---|---|---|
| `Alert` | tones (status families) · action slot — *Playground · Tones* | *WithActions* |
| `Progress` | `variant` · `size` · indeterminate — *Playground · Variants · Sizes* | *Indeterminate* |
| `PasswordStrength` | strength states — *Playground · States* | *Playground only* |
| `Callout` | `intent` · `variant` — *Playground · Intents · Variants* | *Playground only* |
| `Spinner` ✦ | `size` · `accent` (6-ramp) — *Playground · Sizes · Accents* | *Playground only* |
| `Skeleton` | shapes — *Playground · Shapes* | *Playground only* |

### `navigation`
| Component | Surface — variants · colors · actions | Usage stories |
|---|---|---|
| `Tabs` | `variant` (underline/pills) · disabled tab — *Playground · Variants* | *WithDisabledTab* |
| `Accordion` | modes (single/multiple) · disabled item — *Playground · Modes* | *WithDisabledItem* |
| `Pagination` | `size` · windowing — *Playground · Sizes* | *Windowed* |

### `overlay`
| Component | Surface — variants · colors · actions | Usage stories |
|---|---|---|
| `Modal` | `size` · open/close · backdrop — *Playground · Sizes* | *Confirm* |
| `Tooltip` | trigger modes · side — *Playground* | *OnTriggers* |
| `Dialog` | `size` (sm/md/lg) · open/close · focus-trap + return · description slot — *Playground · Sizes · a11y — focus trap* | *Playground* |
| `AlertDialog` | `destructive` · confirm/cancel · Escape-only dismiss (no backdrop) — *Playground · a11y* | *Playground* |
| `Popover` | `placement` (4) · controlled + uncontrolled · anchored non-modal dismiss — *Playground · a11y* | *Playground* |

### `layout`
| Component | Surface — variants · colors · actions | Usage stories |
|---|---|---|
| `AuthLayout` | brandable auth shell — *Playground* | *Verify · CustomBrand* |
| `AspectRatio` | ratio presets — *Playground · Ratios* | *Playground only* |
| `Collapsible` ✦ | `accent` (6-ramp) · open/closed — *Playground · Accents* | *Open* |
| `ScrollArea` | sizes · custom scrollbar — *Playground · Sizes* | *Playground only* |

> **Pending components carry no stories yet** — `mx.7.3.3`/`mx.7.5` add the
> `<Name>.stories.tsx` in the same rung that adds the `.tsx` and the `.prompt.md` (the contract +
> story land with the component, never after).

---

## 3. The colour & sizing vocabulary (what the "colors" axis resolves to)

The Surface column above names axes; here is the token language they resolve to (canon
[`mercury.design.md`](./mercury.design.md) §6 — never a raw hex).

- **The accent ramp (✦ components)** — `accent="iris | indigo | green | orange | plum | red"`. One
  prop re-skins the brand/active surface of a component through the `mercAccent` helper
  (`@mercury/core`): each id resolves to a `{ solid, subtle, ring, fg, onSolid }` token set. `iris`
  is identity (the default brand), `indigo` is interaction, the rest are the semantic families.
- **Brand vs interaction** — Iris 9 (`--bg-brand…`) is identity; Indigo 9 (`--bg-active`,
  `--border-focus`, `--ring-focus`) is interaction (focus rings, checked, links). Kept distinct.
- **Status families** — green (positive) · red (negative) · orange (caution) · plum (discovery) ·
  indigo (info), each with `--bg-*` / `--bg-*-subtle` / `--fg-*` / `--border-*`. These back the
  `tone` / `intent` / `status` axes (Alert · Tag · Callout · Stat deltas).
- **The size scale** — `size="sm" | "md" | "lg"` (heights 32 / 40 / 48; default `md`) wherever a
  component is sized.
- **Variant families** — per-component closed enums (`Button.variant`, `Card.variant`
  flat/raised/floating, `Tabs.variant` underline/pills, `Text.variant`, …) documented in each
  component's `## The enum language` section.

---

## 4. `apps/showcase` — the Developer Reference (planned · `mx.9`)

The forward target: **one comprehensive showcase application**, a *first-in-class Developer
Reference* for a broad audience — the place a developer lands to learn the system, browse every
component live, read its API, and copy a grounded example. It **replaces the retired demo apps**
and is the public face of `@mercury/ui`.

> **Status — FOUNDATION SHIPPED (`mx.7.4` §F, 2026-07-01) · full Reference PLANNED (`mx.9`, Squad-tier).**
> `apps/showcase/` is scaffolded: the shell (sidebar · topbar with a theme toggle wired to the
> `@mercury/effector` theme adapter · source-resolving `@mercury/*` like the other apps) + an
> **Overview** page + an **Overlays** live demo driving the mx.7.4 `Dialog`/`AlertDialog`/`Popover`
> through the disclosure bridge (the two modals stack + lock body scroll; the non-modal `Popover` does
> not). The full per-component Developer Reference (the Components · Foundations · Patterns routes
> below) remains the `mx.9` scope.
> This section is the build brief's north star, grounded in the prototype it is scaffolded from.

### 4.1 Scaffolded from the `mercury-ds` prototype

The prototype already exists and works in the browser —
[`mercury/packages/mercury-ds/project/showcase`](../../mercury/packages/mercury-ds/project/showcase).
`apps/showcase` is the production translation of it into the monorepo:

| Prototype source (`mercury-ds/project/showcase/`) | Role | Translates to `apps/showcase` |
|---|---|---|
| `index.html` + `library.jsx` + `loader.js` | the **live component browser** — nav from `registry.ts`, lazy-compiles each `<Name>.stories.tsx`, renders **Stories + the `.prompt.md` Docs tab** | the **Components** route — a real Vite build resolving `@mercury/ui` from source (no in-browser `@babel/standalone`) |
| `guides.html` + `app.jsx` + `pages.jsx` | the **Foundations** pages (Colors · Typography · Spacing & radius) | the **Foundations** route |
| `components.jsx` · `mercurized.jsx` · `mercurized-pages.jsx` | per-component demo pages + Patterns (Form sign-in · Dashboard) | the **Patterns** route |
| `app.css` | the showcase chrome (sidebar · topbar · theme toggle) | the app's own layout (composed from `@mercury/ui` + `@mercury/effector` theme) |

**The scaffold contract** (the boundary it must hold): a Vite/React app under `mercury/apps/showcase/`
that resolves `@mercury/*` **from source** via the vite alias + tsconfig `paths` (exactly like the
other apps — a package edit is live, no prebuild); it **composes** `@mercury/ui` and never houses a
reusable component; it styles through tokens (`.light-theme`/`.dark-theme` decorator, the
`@mercury/effector` `theme` adapter); and it adds nothing to the `@mercury/ui` barrel (the master
invariant holds — the showcase is a *consumer*).

### 4.2 The reference surfaces (per component)

The "broad audience" Developer Reference renders these surfaces for every component — and they are
**already authored**: each maps to a section of the co-located `<Name>.prompt.md` contract (the
`D-7` six-section shape, [`contracts.md`](./contracts.md)) plus the live stories. The showcase
*renders* the contract; it does not re-document.

| Reference surface (broad-audience ask) | Source of truth | Where it lives today |
|---|---|---|
| **API** — what to import & the component signature | the contract title + `Import:` line + the component's exported types | `<Name>.prompt.md` head · `@mercury/ui` barrel |
| **Props** — every prop, type, default | `## Props` table (grounded in the live `.tsx`) | `<Name>.prompt.md` |
| **Usage** — copy-paste examples | `## Examples` (real call sites, cited) + the live `Playground`/scenario stories | `<Name>.prompt.md` · `<Name>.stories.tsx` |
| **Forms** — building real input flows | the `inputs` + `selection` groups + the Patterns **Form · Sign-in** demo | `apps/showcase` Patterns route |
| **Do / Don't** — a11y, state behaviour, gotchas | `## Notes` + `## The enum language` (tokens, not hex) | `<Name>.prompt.md` |
| **Composition** — what it feeds / is fed by | `## Composition` cross-links (real relative paths) | `<Name>.prompt.md` |

Because the contracts already carry props/API/usage/do-don't/composition for all 52 components, the
showcase's per-component page is **render the contract + mount the stories** — the Reference is a
*projection* of the registry, not a parallel set of hand-written docs to drift from.

### 4.3 Information architecture (the sidebar)

Mirrors the prototype's shell, broadened for the Reference:

- **Getting started** — Overview · install & the `@mercury/*` package split · theming (light/dark) · token discipline.
- **Foundations** — Colors (the accent ramp + status families) · Typography · Spacing & radius · Elevation.
- **Components** — the §1 catalogue, grouped; each page = **Stories** (live) + **Docs** (the contract: API · Props · Usage · Do/Don't · Composition).
- **Patterns** — Forms (Sign-in) · Dashboard · real-world recipes composing several components.

---

## Map

This registry · the architecture [`mercury.design.md`](./mercury.design.md) · the roadmap
[`mercury.roadmap.md`](./mercury.roadmap.md) · the dashboard
[`mercury.progress.md`](./mercury.progress.md) · the contract format
[`contracts.md`](./contracts.md) · the program manual
[`program/mercury.program.md`](./program/mercury.program.md). Code:
[`../../mercury/packages/mercury-ui/src/components`](../../mercury/packages/mercury-ui/src/components)
· the showcase prototype
[`../../mercury/packages/mercury-ds/project/showcase`](../../mercury/packages/mercury-ds/project/showcase).
