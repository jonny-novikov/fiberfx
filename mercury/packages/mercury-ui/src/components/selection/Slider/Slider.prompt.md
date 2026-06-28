# Slider — the numeric range control

A labelled range input with an optional live value readout — drag a number across a bounded span
(`min…max` by `step`). Reach for it for a continuous calibration: a rate, a percentage, a fee. Import:
`import { Slider } from "@mercury/ui"`.

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `value` | `number` | — (required) | Controlled numeric value. |
| `onChange` | `(value: number) => void` | — | Fires with the **new number** (already `Number(...)`-coerced). |
| `min` | `number` | `0` | Lower bound. |
| `max` | `number` | `100` | Upper bound. |
| `step` | `number` | `1` | Increment granularity (e.g. `0.001` for a fine rate). |
| `label` | `string` | — | Caption shown in the head row. |
| `unit` | `string` | `""` | Suffix appended to the readout (e.g. `"%"`). |
| `showValue` | `boolean` | `true` | Toggles the `value + unit` readout in the head row. |
| `size` | `"sm" \| "md"` | `"md"` | Track-height ramp (see the enum language). |
| `disabled` | `boolean` | — | Dims to `0.5` + `not-allowed`. |

The component does **not** `forwardRef` and passes through only the props above (no `…rest`). The head
row renders only when `label` or `showValue` is set.

## The enum language

`size` is a dimensional ramp on the track, not a color (canon §6 size ramp):

- `sm` — a 2px track.
- `md` — a 4px track; the default.

Colors are fixed surface tokens: the unfilled track is `--bg-tertiary`, the filled portion (driven by a
`--mx-pct` CSS var) is `--bg-brand`, the thumb sits on `--bg-primary` ringed in `--bg-brand`; focus adds
the `--ring-focus` halo. The label is `--fg-secondary`, the readout `--fg-primary`.

## Composition

- **Composes:** nothing — a leaf (a native `<input type="range">`).
- **Composed by:** [Card](../../data-display/Card/Card.prompt.md) (a calibration panel — the economy
  `CalibrationForm`). *(Sibling contract authored across mx.2; link resolves at set completion.)*

## Examples

```tsx
// Percentage with label + unit, value mapped to a 0..1 fraction
<Slider label="Pool portion" unit="%" min={0} max={100} step={1}
  value={Math.round(poolPortion.value * 100)} onChange={(v) => poolPortion.onChange(v / 100)} />
// codemojex-node/apps/economy/src/components/CalibrationForm.tsx

// Fine rate, readout suppressed (an external Tag shows the value)
<Slider min={0.05} max={0.4} step={0.001} showValue={false} value={akp.value} onChange={editAkp} />
// codemojex-node/apps/economy/src/components/CalibrationForm.tsx
```

## Notes

- **`onChange` carries a number** — the source coerces `e.target.value` with `Number(...)`, so no
  parsing on the consumer side.
- **The readout is display-only** — `value + unit` (e.g. `42%`); `unit` does not scale the value, so map
  domain↔display in `value`/`onChange` (the economy form stores a `0…1` fraction and shows `× 100`).
- **Drop the head row** by leaving `label` unset and `showValue={false}` — useful when a sibling (a
  `Tag`/`Stat`) shows the number instead.
