# Collapsible — a single disclosure

One labelled header with a round toggle that reveals its body on a smooth height animation. Reach
for it for a lone show/hide region; reach for `Accordion` when several disclosures should be managed
as a set (one-open-at-a-time). Import: `import { Collapsible } from "@mercury/ui"`.

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `title` | `ReactNode` | — (required) | The always-visible header label. |
| `defaultOpen` | `boolean` | `false` | Uncontrolled initial open state. |
| `open` | `boolean` | — | Controlled open state; pair with `onOpenChange`. |
| `onOpenChange` | `(open: boolean) => void` | — | Called with the next open state on toggle. |
| `bordered` | `boolean` | `true` | Wrap in a bordered card; `false` for a bare disclosure. |
| `accent` | `"iris" \| "indigo" \| "green" \| "orange" \| "plum" \| "red"` (`CollapsibleAccent`) | `"iris"` | Tints the toggle when open. |
| `width` | `number \| string` | `360` | Container width (number → px). |
| `children` | `ReactNode` | — | The disclosed body. |
| …rest | `HTMLAttributes<HTMLDivElement>` | — | `id`, `className`, `style`, `aria-*`, … pass through to the root `<div>`. |

## The enum language

- `accent` resolves to `.mx-collapsible--accent-<id>`: when open, the toggle takes a `--<ramp>-3`
  background and `--<ramp>-11` ink; closed, it is the neutral `--bg-secondary` / `--fg-secondary`.
- `bordered` resolves to `.mx-collapsible--bordered` → a `--border-secondary` card on `--bg-primary`;
  omit it for a flush, borderless disclosure.

## Composition

- **Composes:** [Icon](../../foundations/Icon/Icon.prompt.md) — the toggle chevron (`chevron-down`,
  rotated 180° when open).
- **Distinct from:** [Accordion](../../navigation/Accordion/Accordion.prompt.md) — Accordion manages a
  set (`items`, single/multiple, keyboard roving); Collapsible is one self-contained disclosure. Compose
  several Collapsibles for an unmanaged group.

## Examples

```tsx
<Collapsible title="Connection details">
  <p>Host, port, and credentials for the upstream service.</p>
</Collapsible>

<Collapsible title="Advanced" defaultOpen accent="indigo">
  <p>Pre-expanded, indigo toggle tint.</p>
</Collapsible>

// Controlled
<Collapsible title="Filters" open={open} onOpenChange={setOpen}>…</Collapsible>
```

## Notes

- **Controlled + uncontrolled:** pass `open` + `onOpenChange` to drive it; otherwise it owns its state
  from `defaultOpen`. The toggle carries `aria-expanded`.
- The reveal is a CSS `grid-template-rows: 0fr → 1fr` transition — no measured height and so no
  `useRef().current` dereference (the React-19 nullable-ref hazard does not arise here). The transition
  is dropped under `prefers-reduced-motion`.
- (source-grounded; no app call site — a net-new mx.7.2 import.)
