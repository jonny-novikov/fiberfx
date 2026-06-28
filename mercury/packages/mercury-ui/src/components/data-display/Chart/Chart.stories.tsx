import type { Meta, StoryObj } from "@storybook/react-vite";
import { Chart } from "@mercury/ui";
import type { ChartSeries, ChartMarker } from "@mercury/ui";

// Chart is a geometry-DUMB data-prop component: the caller precomputes every
// path/scale/tick. The sample geometry below mirrors the economy curve builder
// (viewBox "0 0 1000 300", token strokes, gradient-filled area, evenly-spaced
// gridY, axis ticks) — grounded in real call sites (cited). No enum props:
// `height`/`ariaLabel` are the only controls; series/grids/ticks are structured.
// codemojex-node/apps/economy/src/model/curves.ts (buildHousePctCurve)
// codemojex-node/apps/economy/src/components/HousePctCurve.tsx · PoolGrowthCurve.tsx

// ── House % of each guess vs avg key price (rising-then-plateau, area-filled) ──
const houseSeries: ChartSeries[] = [
  {
    d: "M0 282 L125 250 L250 205 L375 168 L500 138 L625 116 L750 100 L875 90 L1000 84",
    area: "M0 282 L125 250 L250 205 L375 168 L500 138 L625 116 L750 100 L875 90 L1000 84 L1000 300 L0 300 Z",
    stroke: "rgb(var(--iris-9))",
    fillId: "houseGrad",
  },
];

const meta: Meta<typeof Chart> = {
  title: "Data Display/Chart",
  component: Chart,
  argTypes: {
    height: { control: { type: "number", min: 120, max: 480, step: 10 } },
    ariaLabel: { control: "text" },
    viewBox: { control: false },
    series: { control: false },
    gridY: { control: false },
    gridX: { control: false },
    yTicks: { control: false },
    xTicks: { control: false },
    gradients: { control: false },
    markers: { control: false },
  },
  args: {
    viewBox: "0 0 1000 300",
    series: houseSeries,
    gridY: [0, 60, 120, 180, 240, 300],
    gradients: [{ id: "houseGrad", stroke: "rgb(var(--iris-9))" }],
    yTicks: ["100%", "80%", "60%", "40%", "20%", "0%"],
    xTicks: ["$0.01", "$0.10", "$0.20", "$0.30", "$0.40"],
    height: 240,
    ariaLabel: "House percentage of each guess as the average key price rises",
  },
};
export default meta;

type Story = StoryObj<typeof Chart>;

export const Playground: Story = {};

// ── Operator margin vs pool portion: two token-stroked series + a zero marker ──
// codemojex-node/apps/economy/src/components/MarginCurve.tsx
// codemojex-node/apps/economy/src/model/curves.ts (buildMarginCurve)
const marginSeries: ChartSeries[] = [
  { d: "M0 96 L250 110 L500 126 L750 140 L1000 150", stroke: "rgb(var(--green-9))", width: 2.5 }, // desktop (low fee)
  { d: "M0 110 L250 132 L500 150 L750 176 L1000 210", stroke: "rgb(var(--orange-9))", width: 2.5 }, // mobile (high fee)
];
const marginMarkers: ChartMarker[] = [{ y: 150 }]; // the zero / loss boundary (dashed by default)

export const MarginCurve: Story = {
  render: () => (
    <Chart
      viewBox="0 0 1000 300"
      series={marginSeries}
      gridY={[0, 75, 150, 225, 300]}
      markers={marginMarkers}
      yTicks={["+$0.04", "+$0.02", "$0.00", "−$0.02", "−$0.04"]}
      xTicks={["0%", "25%", "50%", "75%", "100%"]}
      ariaLabel="Operator margin versus pool-funding portion, mobile and desktop"
    />
  ),
};
