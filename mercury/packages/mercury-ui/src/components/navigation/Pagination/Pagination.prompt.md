# Pagination — the page-stepper control

A 1-based page navigator with prev/next arrows and a windowed page list that collapses to ellipses when
the count is large. Reach for it under a long table or list. Import:
`import { Pagination } from "@mercury/ui"`.

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `page` | `number` | — (required) | The 1-based current page — controlled. |
| `count` | `number` | — (required) | Total number of pages. |
| `onPageChange` | `(page: number) => void` | — (required) | Fired with the target page; only for an in-range page that differs from `page`. |
| `siblingCount` | `number` | `1` | Pages shown on each side of the current page before ellipses. |
| `size` | `"sm" \| "md"` | `"md"` | Control size (see the enum language). |
| `caption` | `ReactNode` | — | Optional caption rendered under the controls (e.g. "Showing 1 – 10"). |
| `className` | `string` | — | Merged onto the root `.mx-pag` (via `cx`). |
| …rest | `HTMLAttributes<HTMLElement>` (minus `onChange`) | — | Native attrs pass through to the `<nav>`; `forwardRef` to the `<nav>`. |

`PaginationProps extends Omit<HTMLAttributes<HTMLElement>, "onChange">` — the native `onChange` is
omitted so `onPageChange` is the single, typed page callback.

## The enum language

`size` resolves to the `.mx-pag--<size>` recipe (canon §6):

- `sm` — 32px square buttons, 13px text, `--radius-6` corners; a dense footer control.
- `md` — the base size (no modifier class).

There is no `tone`/`variant` family; the active page lifts via the `is-active` state on the surface
tokens (`--bg-*`, `--border-*`).

## Composition

- **Composes:** nothing — a leaf. The arrows are inline carets; page numbers are rendered directly.
- **Composed by:** no current call site — the intended pairing is under a
  [Table](../../data-display/Table/Table.prompt.md) or a list view that owns the `page`/`count` state.

## Examples

```tsx
// Controlled stepper with a caption
<Pagination
  page={page}
  count={12}
  onPageChange={setPage}
  caption={`Showing ${(page - 1) * 10 + 1} – ${page * 10}`}
/>
// (source-grounded; no app call site)

// Compact, wider sibling window
<Pagination page={page} count={40} siblingCount={2} size="sm" onPageChange={setPage} />
// (source-grounded; no app call site)
```

## Notes

- **(source-grounded; no app call site)** — no app composes `Pagination`; the snippets above are the
  minimal valid usage built from `Pagination.tsx`.
- **Controlled** — you own `page` and update it in `onPageChange`. `onPageChange` is guarded: it never
  fires for a page below 1, above `count`, or equal to the current `page`.
- **The window** — when `count` fits the available slots (`siblingCount * 2 + 5`) every page shows;
  beyond that, the list collapses to `1 … left–right … count` with `"dots"` gaps.
- **a11y** — the root is `<nav aria-label="Pagination">`; the active page carries `aria-current="page"`;
  the prev/next buttons are `aria-label`'d and auto-`disabled` at the ends.
