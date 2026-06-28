# Button — the primary action affordance

A clickable action with six visual variants, three sizes, optional leading/trailing slots, and a
loading state that swaps the label for a spinner. Reach for it for any command — submit, confirm,
cancel, a quick action in a panel. Import: `import { Button } from "@mercury/ui"`.

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `variant` | `"primary" \| "secondary" \| "outline" \| "ghost" \| "destructive" \| "inverse"` | `"primary"` | Visual weight + intent (see the enum language). |
| `size` | `"sm" \| "md" \| "lg"` | `"md"` | Control height + padding. |
| `loading` | `boolean` | `false` | Swaps the label for a spinner, disables interaction, sets `aria-busy`. Hides `leading`/`trailing`. |
| `fullWidth` | `boolean` | `false` | Stretch to the container width (`is-full`). |
| `leading` | `ReactNode` | — | Element before the label — usually an `<Icon />`. Hidden while `loading`. |
| `trailing` | `ReactNode` | — | Element after the label. Hidden while `loading`. |
| `type` | `"button" \| "submit" \| "reset"` | `"button"` | Native button type. |
| `disabled` | `boolean` | — | Native; `disabled \|\| loading` disables. |
| …rest | `ButtonHTMLAttributes` | — | `onClick`, `name`, `aria-*`, `className` pass through (`forwardRef` to the `<button>`). |

## The enum language

`variant` resolves to the `.mx-btn--<variant>` token recipe (canon §6):

- `primary` — brand fill (`--bg-brand` / `--fg-on-brand`); the default CTA.
- `secondary` — subtle surface (`--bg-secondary`); a second action beside a primary.
- `outline` — bordered, transparent fill (`--border-strong`); low-emphasis.
- `ghost` — text-only, no border; toolbar / inline actions.
- `destructive` — the `negative` status family; delete/remove.
- `inverse` — for placement on a dark/brand surface.

`size` → `sm | md | lg` height ramps. Pair `leading`/`trailing` with a matching `Icon` `size` (14 for
`sm`/`md`).

## Composition

- **Composes:** [Icon](../../foundations/Icon/Icon.prompt.md) — in the `leading`/`trailing` slot
  (`leading={<Icon name="download" size={14} />}`).
- **Composed by:** [Modal](../../overlay/Modal/Modal.prompt.md) (the `footer` actions),
  [AuthLayout](../../layout/AuthLayout/AuthLayout.prompt.md) (the auth-screen submit),
  [Card](../../data-display/Card/Card.prompt.md) (a form's CTA). *(Sibling contracts authored across
  mx.2; links resolve at set completion.)*

## Examples

```tsx
// Variants + sizes
<Button variant="destructive">Delete</Button>
<Button variant="secondary" size="sm">Cancel</Button>
// showcase/src/pages/components/ButtonPage.tsx

// Icon slot
<Button leading={<Icon name="download" size={14} />}>Download</Button>
<Button variant="outline" leading={<Icon name="plus" size={14} />}>New job</Button>
// showcase/src/pages/components/ButtonPage.tsx

// Loading + disabled
<Button loading>Saving…</Button>
// showcase/src/pages/components/ButtonPage.tsx

// In a calibration panel — disabled when there is nothing to spend
<Button variant="secondary" disabled={keys <= 0}>Spend</Button>
<Button variant="ghost" onClick={reset}>Reset</Button>
// codemojex-node/apps/economy/src/components/BalanceSimPanel.tsx
```

## Notes

- **Loading** sets `disabled` + `aria-busy` and renders only the spinner — `leading`/`trailing` are
  suppressed, so a loading button shows no icon.
- The label span renders only when `children != null`; an icon-only button passes just `leading` and
  no children.
- `variant="destructive"` is visual only — it carries no confirmation; pair it with a
  [Modal](../../overlay/Modal/Modal.prompt.md) for irreversible actions.
