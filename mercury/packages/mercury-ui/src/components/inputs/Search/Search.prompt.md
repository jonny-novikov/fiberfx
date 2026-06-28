# Search — the search input with a built-in glyph + clear

A self-contained search box: a fixed leading magnifier glyph, a value-string `onChange`, an
Enter-to-`onSearch` and Escape-to-clear keyboard contract, and an automatic clear (`×`) button when
there is a value. Reach for it for any filter/search field. Import: `import { Search } from "@mercury/ui"`.

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `value` | `string` | — (required) | The controlled query string. |
| `onChange` | `(value: string) => void` | — | Fired with the **string** value (not the event) on input and on Escape/clear. |
| `onSearch` | `(value: string) => void` | — | Fired with the current value when the user presses Enter. |
| `placeholder` | `string` | `"Search"` | Native placeholder. |
| `disabled` | `boolean` | — | Native; fades the field, blocks entry, and hides the clear button. |
| …rest | `Omit<InputHTMLAttributes<HTMLInputElement>, "onChange">` | — | `name`, `aria-*`, `className`, etc. pass through to the `<input>` (forced `type="search"`). The native `onChange` is replaced by the string-valued one above. |

## Composition

- **Composes:** [Icon](../../foundations/Icon/Icon.prompt.md) — the built-in leading glyph,
  hard-wired as `<Icon name="search" size={14} />` (not a slot).
- **Composed by:** any toolbar/list-filter surface. *(No app call site yet; source-grounded — sibling
  contracts authored across mx.2.)*

## Examples

```tsx
// Basic — controlled query
<Search value={query} onChange={setQuery} />
// (source-grounded; no app call site)

// Enter to run, Escape to clear
<Search value={query} onChange={setQuery} onSearch={runSearch} placeholder="Filter jobs" />
// (source-grounded; no app call site)
```

## Notes

- **No app call site** — the snippets above are constructed from the live interface and labeled
  *(source-grounded; no app call site)*.
- **No enum props** — no enum-language section. There is no `error`/state styling on this component.
- **`onChange` is string-valued**, unlike `Input` (which passes the native event through). The native
  `onChange` is omitted from `…rest` precisely so the string signature wins.
- **Keyboard contract** — Enter calls `onSearch(value)`; Escape calls `onChange("")` (clear). The
  trailing `×` clear button appears only when `value` is non-empty and the field is not `disabled`,
  and carries `aria-label="Clear"`.
