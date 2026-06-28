import type { Meta, StoryObj } from "@storybook/react-vite";
import { Stat, Icon } from "@mercury/ui";
import type { StatTone, StatProps } from "@mercury/ui";

// The delta-tone language, traced from Stat.tsx (the StatTone union →
// `.mx-stat__delta--<tone>`) and restated in Stat.prompt.md — NO-INVENT.
const TONES: StatTone[] = ["neutral", "positive", "negative", "caution", "brand", "info"];
// `align` has no exported union — typed from the prop so an invented value fails tsc.
const ALIGNS: NonNullable<StatProps["align"]>[] = ["left", "center"];

// Controls restate Stat.prompt.md: `label`/`value`/`delta`/`hint` (caller-formatted
// text), `deltaTone` (the StatTone select — colors only the delta chip), `align`
// (left|center). `leading` is a ReactNode slot driven by a story arg rendering a
// real <Icon />, never a raw control. Defaults grounded in the economy KpiRow
// "House / guess" tile.
// codemojex-node/apps/economy/src/components/KpiRow.tsx
const meta: Meta<typeof Stat> = {
  title: "Data Display/Stat",
  component: Stat,
  argTypes: {
    label: { control: "text" },
    value: { control: "text" },
    delta: { control: "text" },
    deltaTone: { control: "select", options: TONES },
    hint: { control: "text" },
    align: { control: "inline-radio", options: ALIGNS },
    leading: { control: false },
  },
  args: {
    label: "House / guess",
    value: "$0.012",
    delta: "30.3%",
    deltaTone: "brand",
    hint: "of gross",
    align: "left",
  },
};
export default meta;

type Story = StoryObj<typeof Stat>;

export const Playground: Story = {};

// Each delta tone over the same figure.
export const DeltaTones: Story = {
  render: () => (
    <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(180px, 1fr))", gap: "12px" }}>
      {TONES.map((tone) => (
        <Stat key={tone} label={`deltaTone="${tone}"`} value="$0.012" delta="+30.3%" deltaTone={tone} hint="of gross" />
      ))}
    </div>
  ),
};

// The headline KPI row — five tiles fed by the canonical split + pool.
// codemojex-node/apps/economy/src/components/KpiRow.tsx
export const KpiRow: Story = {
  render: () => (
    <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(160px, 1fr))", gap: "12px" }}>
      <Stat label="Guess value" value="$0.040" hint="gross akp × fee" />
      <Stat label="Pool / guess" value="80💎" hint="$0.016" />
      <Stat label="House / guess" value="$0.012" delta="30.3%" deltaTone="brand" hint="of gross" />
      <Stat label="Mobile margin" value="−$0.004" delta="−10.1%" deltaTone="negative" hint="after store fee" />
      <Stat label="Pool · 20×3" value="$96.00" hint="960💎" />
    </div>
  ),
};

// A leading icon in the head slot — a real <Icon /> per Stat.prompt.md.
export const WithLeadingIcon: Story = {
  args: {
    label: "Balance",
    value: "$12,480.00",
    leading: <Icon name="wallet" size={14} />,
    delta: "+2.4%",
    deltaTone: "positive",
  },
};
