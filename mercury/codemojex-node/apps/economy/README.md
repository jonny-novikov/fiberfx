# @codemojex/economy — Revenue-Model Calibration Console

An interactive **Vite + React 19 + Effector** console for tuning the Codemojex
per-guess revenue model. Enter the inputs in the form; the KPI tiles, tables,
curves, and revenue-flow visualization recompute live.

Port **5180** · dark-first · reuses `@mercury/ui` + `@mercury/effector`.

## Run

```bash
pnpm install                 # from mercury/ — links the workspace
pnpm dev:economy             # → http://localhost:5180
pnpm build:economy           # production build (filtered; build:apps does not reach codemojex-node/apps/*)
```

## The model (USD-canonical)

`diamondsPerUsd` is a calibration **input** (default 10 → `10💎 = $1`), never a hidden constant.

```
guess_value   = akp × guess_fee
basis_akp     = splitBasis==="net" ? akp × (1 − storeFeeMobile) : akp
pool_diamonds = floor(basis_akp × guess_fee × pool_portion × diamondsPerUsd)   (integer)
pool_usd      = pool_diamonds / diamondsPerUsd
house_usd     = guess_value − pool_usd            (one-floor complement; the floor residue → house)
margin        = net_received − pool_owed,  net_received = guess_value × (1 − store_fee)
squeeze_pct   = margin / guess_value
conservation  : gross_consumed == pool_liability + house_realized
```

Defaults reproduce the worked example exactly: `akp $0.15, fee 5, portion 0.70`
→ 5💎 ($0.50) pool + $0.25 house (33.3%); mobile margin **+1.3%** vs desktop **+30.3%**;
N=10 × G=20 → 1000💎 ($100) pool + $50 house, conservation balanced.

## Structure

- `src/model/` — pure, deterministic calc + curve/flow geometry (no React, no Date/random; unit-checkable)
- `src/store/` — Effector `createForm` inputs (`form.ts`) + derived stores (`derived.ts`)
- `src/components/` · `src/views/` — the calibration form, KPI tiles, the three tables
  (split ladder · margin squeeze · prize pool), the three curves (house% vs akp · margin vs
  pool portion · pool growth), the revenue-flow viz, the rail panel, and the WAC balance simulator
- Tabs: **Calibrate** · **Prize Pool** · **Advanced**

New reusable primitives this app added to `@mercury/ui`: **`Chart`** (token-driven SVG
curve/area) and **`Stat`** (KPI tile) — both consumed from library source via the Vite alias.
