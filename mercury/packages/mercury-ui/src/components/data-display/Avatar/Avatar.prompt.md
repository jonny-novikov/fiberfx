# Avatar — a user image or initials disc

A circular user marker: an image when `src` is given, otherwise the name's initials on a
deterministic, name-hashed background, with an optional status dot. Reach for it for user rows, table
cells, and account chrome. Import: `import { Avatar } from "@mercury/ui"`.

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `name` | `string` | `""` | Drives the initials (first letter of up to the first two words, uppercased), the `<img alt>`, and the background hue (a char-code hash into a fixed hue set). |
| `src` | `string` | — | An image URL; when set, renders `<img>` over a `--bg-tertiary` backplate instead of initials. |
| `size` | `number` | `40` | Square px — sets the disc `width`/`height`; the font (`0.38×`) and status dot (`0.28×`) scale from it. |
| `status` | `"positive" \| "caution" \| "negative" \| "info"` | — | When set, renders a corner status dot. Exported as `AvatarStatus`. |

## The enum language

`status` resolves directly to a **status-family surface token**, `rgb(var(--bg-<status>))` — one of
`--bg-positive` · `--bg-caution` · `--bg-negative` · `--bg-info` (canon §6). The initials background is
**not** an enum: it is a deterministic hash of `name` into a fixed hue ramp (`--iris-9` · `--indigo-9`
· `--green-9` · `--orange-9` · `--plum-9` · `--red-9`), so the same name always gets the same color.
Tokens, never raw hex.

## Composition

- **Composes:** nothing — a leaf (renders an `<img>` or text initials).
- **Composed by:** [Table](../Table/Table.prompt.md) cells (an owner/user column `render`).

## Examples

```tsx
// Size ramp — initials from the name
<Avatar name="Ada Lovelace" size={24} />
<Avatar name="Ada Lovelace" size={80} />
// showcase/src/pages/components/AvatarPage.tsx

// With a status dot
<Avatar name="Grace Hopper" size={48} status="positive" />
<Avatar name="Ada Lovelace" size={48} status="negative" />
<Avatar name="Radia Perlman" size={48} status="info" />
// showcase/src/pages/components/AvatarPage.tsx

// In a table cell — small, owner column
<Avatar name={r.owner} size={22} />
// showcase/src/pages/components/TablePage.tsx
```

## Notes

- With no `src`, the disc shows up to **two** initials on a **deterministic** name-hashed hue — the
  same `name` is reproducibly colored across renders and surfaces.
- All sizing is derived from the single `size` prop (font and dot scale from it), so an avatar stays
  proportioned at any px without extra props.
- `status` is a **status family** (`positive`/`caution`/`negative`/`info`) → `--bg-<status>`; there is
  no `brand`/`neutral`/`discovery` status dot.
