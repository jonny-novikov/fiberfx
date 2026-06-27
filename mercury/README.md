# Mercury — React + Vite monorepo

A token-driven React component library, an Effector adapter, and three example apps
(**EchoMQ**, **Showcase**, **Catalogue**) — all wired together with pnpm workspaces.

```
mercury/
├─ packages/
│  ├─ mercury-ui/         @mercury/ui        — TSX components + token CSS (Vite library mode, ESM + .d.ts)
│  └─ mercury-effector/   @mercury/effector  — theme store, toast model + <Toaster/>, createForm factory
├─ apps/
│  ├─ showcase/           component browser   (consumes the library + Effector)
│  ├─ catalogue/          foundations + components explorer
│  ├─ echomq/             message-queue console dashboard
│  └─ docs/               documentation site — sidebar + content + TOC (like catalogue)
├─ site/index.html        first-class marketing landing (static HTML, new DS CSS)
└─ playground/index.html  no-build Babel preview (open directly in a browser)
```

## Requirements & install

```bash
# Node >= 20, pnpm >= 9
pnpm install
```

## Build the library (the "required tool")

`@mercury/ui` builds in **Vite library mode** → modern ESM (`es2024`), a single CSS bundle,
React externalized, with first-class types emitted by `tsc`.

```bash
pnpm build                 # builds packages/* (ui then effector)
# → packages/mercury-ui/dist/mercury-ui.js, mercury-ui.css, index.d.ts
```

## Run the apps

Apps alias `@mercury/*` to package **source**, so dev needs no prebuild:

```bash
pnpm dev:showcase          # http://localhost:5173
pnpm dev:catalogue
pnpm dev:echomq
pnpm build:apps            # production builds of all three apps
pnpm typecheck             # tsc across every package + app
```

## Using the library

```tsx
import { Button, Input, Tabs, Table, Tag } from "@mercury/ui";
import "@mercury/ui/styles.css"; // tokens + components (auto-imported by the entry too)

<Button variant="primary" size="lg">Continue</Button>
```

Components are **presentational** and styled by the `.mx-*` classes in `mercury.css`,
which read semantic tokens from `tokens.css`. Switching light/dark — or rebranding —
is one variable deep (swap the `--bg-brand` / `--fg-*` aliases).

## Pluggable Effector layer

`@mercury/effector` keeps state outside React; components stay dumb.

```tsx
import { initTheme, setTheme, useTheme, toast, Toaster, createForm } from "@mercury/effector";

initTheme();                          // sync <html> class + persist (call once at startup)
const theme = useTheme();             // reactive "light" | "dark"
setTheme("dark");

toast.success("Saved");               // imperative toasts; render <Toaster /> once near root

const signIn = createForm({
  initialValues: { email: "", password: "" },
  validate: (v) => (!v.email ? { email: "Required" } : {}),
});
function EmailField() {
  const f = signIn.useField("email");
  return <Input value={f.value} error={f.error}
    onChange={(e) => f.onChange(e.target.value)} onBlur={f.onBlur} />;
}
```

- **theme** — `$theme` store, `setTheme` / `toggleTheme`, `initTheme()`, `useTheme()`.
- **toast** — `$toasts`, `showToast` / `dismissToast`, `toast.{success,error,info,warning}`, `<Toaster position />`.
- **form** — `createForm({ initialValues, validate })` → `$values/$errors/$touched/$isValid` + `useField` / `useForm` hooks.

## Components

Button · Input · Textarea · Search · Select · Checkbox · Radio · Switch · Segmented ·
Slider · Chip · Tag · Badge · Avatar · Card · Alert · Progress · Tabs · Modal · Tooltip ·
Table · AuthCode · Icon.

## Preview without a build

`playground/index.html` is a self-contained Babel-standalone page that loads the real
`tokens.css` + `mercury.css` and renders an interactive gallery (theme toggle + toasts via
an inline Effector model). Open it directly — handy for a quick look without `pnpm install`.
