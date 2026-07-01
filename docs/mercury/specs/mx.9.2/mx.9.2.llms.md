# MX.9.2 · build context (the agent brief)

Build context for [`mx.9.2.md`](./mx.9.2.md) (authoritative body) + [`mx.9.2.stories.md`](./mx.9.2.stories.md)
(acceptance). The body wins on any disagreement. **BUILD-READY + WRITE-READY**: the derivation module's exact
shape and every chrome piece's contract are carried below; the bundle `library.jsx` is **not** required
reading (its `CAT_ORDER`/`StoryBlock` patterns are already adapted here and at mx.9.3).

> **Framing (propagate — do not drop):** no gendered pronouns for agents; no perceptual or interior-state
> verbs; no first-person narration. State each surface as a contract.

## References — read first (≤3 files)

1. **This brief + the body** — [`mx.9.2.md`](./mx.9.2.md) (§3 invariants, §4 deliverables).
2. **The as-built mx.9.1 scaffold** — `mercury/apps/showcase/src/App.tsx` (the sanity content to relocate
   into `Home.tsx`) — one small file.
3. *(Only on a mismatch)* the group truth: `ls mercury/packages/mercury-ui/src/components/` → exactly
   `actions data-display feedback foundations inputs layout navigation overlay selection` (verified
   2026-07-02; 65 `*.stories.tsx` + 65 sibling `*.prompt.md` under `<group>/<Name>/`).

**Precondition:** mx.9.1 SHIPPED (the scaffold + the `storybook/test` shim alias + the gate join).
**Inherited rulings (2026-07-02, closed):** B · C · D · E (see the epic §7) — zero new dependency; plain
React state + localStorage for the shell (the bundle `library.jsx` persistence shape, reimplemented typed;
`effector` stays available for story modules' own needs, unused by the chrome this rung).

## Requirements (each traced: story ⇠ requirement ⇢ invariant)

| # | Requirement | Story | Invariant |
|---|---|---|---|
| R-1 | `src/registry.ts`: two lazy globs → grouped, ordered, sorted registry; `{group,name}` from path segments | S-1, S-2 | INV-1 |
| R-2 | The 9-group order/label map keyed by segments (epic-S-4 order); unknown segments appended, never dropped | S-2 | INV-1, INV-2 |
| R-3 | Sidebar (grouped nav + derived footer total) · Topbar (title + theme toggle) | S-2, S-3, S-4 | INV-2, INV-3 |
| R-4 | ComponentPage with Stories/Docs STUB panels (no loader call anywhere this rung) | S-3 | INV-5 |
| R-5 | Home = the relocated sanity content; App composes shell over the persisted route `mx-showcase.route.v1` | S-3 | INV-3 |
| R-6 | Theme: boot-apply + toggle + persist `mx-showcase.theme.v1` (documentElement class flip, canon §0) | S-4 | INV-4 |
| R-7 | `showcase.css` structural layout, `rgb(var(--token))` only — no raw hex | S-4 | INV-4, INV-6 |

## Execution topology

**Runtime shape.** `main.tsx` boot-applies the persisted theme class → `<App/>` holds
`route: { group, name, tab } | null` (persisted) → `Sidebar` (from the registry) + `Topbar` (toggle) +
either `Home` (route null) or `ComponentPage` (stubs). No router dependency (Fork E) — state + localStorage,
the bundle shape typed.

**Files (all under `mercury/apps/showcase/src/`):** NEW `registry.ts` ·
`shell/{Sidebar,Topbar,ComponentPage,Home}.tsx` · `showcase.css`; REWRITE `App.tsx`; EDIT `main.tsx` (the
boot line + the css import). A finer helper split inside `shell/` is the implementor's call — the surfaces
above are the contract, the filenames the default.

### `src/registry.ts` — the exact shape

```ts
// The DERIVED registry (epic INV-6). Globs are relative to THIS file:
// src → apps/showcase → apps → the workspace root = three segments up.
export type StoryModuleLoader = () => Promise<Record<string, unknown>>;
export type PromptLoader = () => Promise<string>;

export type ShowcaseEntry = {
  group: string;                 // the <group> path segment, as-is
  name: string;                  // the <Name> folder segment
  loadStories: StoryModuleLoader; // lazy — NOT called at mx.9.2
  loadPrompt?: PromptLoader;      // lazy ?raw — absent when no sibling .prompt.md
};

export type ShowcaseGroup = { key: string; label: string; entries: ShowcaseEntry[] };

const storyModules = import.meta.glob(
  "../../../packages/mercury-ui/src/components/**/*.stories.tsx",
) as Record<string, StoryModuleLoader>;

const promptFiles = import.meta.glob(
  "../../../packages/mercury-ui/src/components/**/*.prompt.md",
  { query: "?raw", import: "default" },
) as Record<string, PromptLoader>;

// The epic-S-4 presentation order — app chrome keyed by the 9 REAL group
// segments (never a component list). `as const` so GroupKey narrows.
export const GROUP_ORDER = [
  "foundations",
  "actions",
  "inputs",
  "selection",
  "data-display",
  "feedback",
  "overlay",
  "navigation",
  "layout",
] as const;
export type GroupKey = (typeof GROUP_ORDER)[number];

export const GROUP_LABEL: Record<GroupKey, string> = {
  foundations: "Foundations",
  actions: "Actions",
  inputs: "Inputs",
  selection: "Selection",
  "data-display": "Data display",
  feedback: "Feedback",
  overlay: "Overlay",
  navigation: "Navigation",
  layout: "Layout",
};

// components/<group>/<Name>/<file> — segment-derived, no name literal.
function parse(path: string): { group: string; name: string } | null {
  const parts = path.split("/");
  const i = parts.lastIndexOf("components");
  if (i < 0 || parts.length <= i + 2) return null;
  return { group: parts[i + 1], name: parts[i + 2] };
}

export function buildRegistry(): ShowcaseGroup[] {
  const byKey = new Map<string, ShowcaseEntry>();
  for (const [path, loader] of Object.entries(storyModules)) {
    const parsed = parse(path);
    if (!parsed) continue;
    byKey.set(`${parsed.group}/${parsed.name}`, { ...parsed, loadStories: loader });
  }
  for (const [path, loader] of Object.entries(promptFiles)) {
    const parsed = parse(path);
    if (!parsed) continue;
    const entry = byKey.get(`${parsed.group}/${parsed.name}`);
    if (entry) entry.loadPrompt = loader;
    // a prompt with no story stays un-navigable this rung (stories are the nav spine)
  }
  const groups = new Map<string, ShowcaseEntry[]>();
  for (const entry of byKey.values()) {
    const list = groups.get(entry.group) ?? [];
    list.push(entry);
    groups.set(entry.group, list);
  }
  const orderedKeys = [
    ...GROUP_ORDER.filter((key) => groups.has(key)),
    ...[...groups.keys()].filter((key) => !(GROUP_ORDER as readonly string[]).includes(key)).sort(),
  ];
  return orderedKeys.map((key) => ({
    key,
    label: (GROUP_LABEL as Record<string, string>)[key] ?? key,
    entries: (groups.get(key) ?? []).sort((a, b) => a.name.localeCompare(b.name)),
  }));
}

export const REGISTRY = buildRegistry();
export const TOTAL = REGISTRY.reduce((n, g) => n + g.entries.length, 0);
```

### The shell contracts

- **`shell/Sidebar.tsx`** — *pre:* `REGISTRY` + the active route + an `onSelect(group, name)`. *post:*
  grouped nav (labels from the registry), active entry marked, footer renders `{TOTAL} components`
  (the parity observable — INV-2). No component-name literal.
- **`shell/Topbar.tsx`** — *pre:* theme + `onToggleTheme`. *post:* the title "Mercury Showcase" + a toggle
  composing `Button` from `@mercury/ui` (minimal usage; the co-located `Button.prompt.md` is the prop
  authority). Composing ui primitives is legitimate consumer usage — INV-3 forbids HOUSING a reusable
  component, not using one.
- **`shell/ComponentPage.tsx`** — *pre:* the selected `ShowcaseEntry` + `tab: "stories" | "docs"` +
  `onTab`. *post:* header `{label} · {name}`, tab bar, and per-tab a STATIC stub panel ("The live stories
  surface lands at mx.9.3" / "The contract surface lands at mx.9.4"). **INVARIANT: neither `loadStories`
  nor `loadPrompt` is called anywhere this rung** (INV-5 — the shim stays unexercised until mx.9.3).
- **`shell/Home.tsx`** — the mx.9.1 `App.tsx` sanity content relocated verbatim (components + swatches);
  keeps a `@mercury/ui` barrel import in the graph so the stylesheet keeps arriving (index.ts:12).
- **`App.tsx`** — the composition + the persisted route:

```ts
const ROUTE_KEY = "mx-showcase.route.v1";   // JSON { group, name, tab }
const THEME_KEY = "mx-showcase.theme.v1";   // "light" | "dark"
```

  Plain `useState` initialized from `localStorage`, written back on change (a tiny inline
  `usePersistedState` helper is fine). Selecting a nav entry sets `{ group, name, tab: "stories" }`; the
  null route renders `Home`.
- **`main.tsx`** — prepend the boot-apply (before `createRoot`, so no flash):

```ts
import "./showcase.css";

const bootTheme = localStorage.getItem("mx-showcase.theme.v1") === "dark" ? "dark-theme" : "light-theme";
document.documentElement.classList.remove("light-theme", "dark-theme");
document.documentElement.classList.add(bootTheme);
```

  The toggle swaps the two classes on `document.documentElement` and persists.
- **`showcase.css`** — structural only (the grid: sidebar | main; the chrome SKIN is mx.9.5). Colors/borders
  through `rgb(var(--token))` families (grep `packages/mercury-ui/src/styles/` for the neutral surface/text
  token names — canon §6 families; `--bg-brand`/`--fg-on-brand`/`--space-*` are verified examples). **No raw
  hex** — token discipline is the law even in app chrome.

## Agent stories — Directive + Acceptance gate

- **AS-1 · Write the registry.** *Directive:* `src/registry.ts` exactly as above. *Acceptance:*
  `pnpm --filter @mercury/showcase typecheck` exits 0; `grep -c "import.meta.glob" src/registry.ts` → 2;
  the component-name spot-grep empty.
- **AS-2 · Write the shell + route + theme.** *Directive:* the four shell pieces, the App rewrite, the
  main.tsx boot edit, the css — to the contracts above. *Acceptance:* build green; selecting an entry opens
  the stub page; reload restores route + theme; the toggle repaints Home.
- **AS-3 · Run the liveness probe + parity.** *Directive:* create
  `packages/mercury-ui/src/components/foundations/__Probe__/__Probe__.stories.tsx` (a minimal CSF module:
  a default export `{ title: "probe" }` + one named export), observe the nav entry appear with zero src
  edit, **delete the probe folder**, observe it disappear; compare the footer total to
  `find packages/mercury-ui/src/components -name "*.stories.tsx" | wc -l`. *Acceptance:* both behaviors
  observed and reported; the probe folder is gone after (the only permitted — and transient —
  `packages/**` write this rung; it never touches a tracked file's content, and the Director re-verifies
  `packages/**` clean at review).
- **AS-4 · Close the gate.** *Directive:* the ladder below. *Acceptance:* every step green; greps empty;
  no `*.stories.tsx` network request on boot/navigation (report the observation — MANUAL INV-5 evidence).

## The gate ladder (run from `mercury/` — NEVER `pnpm -r`)

```bash
pnpm --filter "./packages/*" typecheck            # unchanged by mx.9.2
pnpm --filter "./packages/*" build                # unchanged
pnpm --filter @mercury/showcase typecheck
pnpm --filter @mercury/showcase build
pnpm --filter "./apps/*" --filter "!@mercury/storybook" build    # 3 product apps
grep -RnE "design-sync|DesignSync|@babel/standalone|window\.MercuryUI|_ds_bundle" apps/showcase  # → empty
grep -c "import.meta.glob" apps/showcase/src/registry.ts          # → 2
grep -nE '"(Button|Badge|Card|Icon|Tabs|Modal|Table)"' apps/showcase/src/registry.ts  # → empty
grep -rnE "#[0-9a-fA-F]{3,8}\b" apps/showcase/src/showcase.css    # → empty (no raw hex)
find packages/mercury-ui/src/components -name "*.stories.tsx" | wc -l   # == the rendered footer total
# Director-run: barrel-diff byte-identical; packages/** clean; the S-1 probe re-run adversarially.
```

## The prompt (leaves no decision open)

Inside the shipped mx.9.1 scaffold, write `src/registry.ts` exactly as this brief carries it (two lazy globs
three segments up, segment-parsed, the epic-S-4 group order with unknown segments appended, names sorted),
then the shell to the stated contracts: Sidebar with the derived footer total, Topbar with a
`Button`-composed theme toggle, ComponentPage with static Stories/Docs stubs that call **no** loader, Home
carrying the relocated sanity content, App holding the `mx-showcase.route.v1`-persisted route, main.tsx
boot-applying `mx-showcase.theme.v1` before mount, and token-only structural css. Run the liveness probe
(create → observe → DELETE the throwaway story folder) and the parity check, then the gate ladder verbatim.
Touch only `apps/showcase/src/**` (the probe folder transiently excepted); no root edit, no lockfile delta,
no new dependency, no git, no `pnpm -r`. Escalate any mismatch — do not improvise past the brief.
