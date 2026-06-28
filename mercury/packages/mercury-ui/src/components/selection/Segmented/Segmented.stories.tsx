import { useState } from "react";
import type { Meta, StoryObj } from "@storybook/react-vite";
import { Segmented } from "@mercury/ui";
import type { Segment, SegmentedProps } from "@mercury/ui";

// `size` ramp, typed by the component's own union (NO-INVENT — an invented
// member is a compile error). Segmented.prompt.md: sm | md | lg, padding/font
// only (no color change).
const SIZES: NonNullable<SegmentedProps<string>["size"]>[] = ["sm", "md", "lg"];

// Sample data shaped to `Segment<T>` — the date-range switch.
// showcase/src/pages/components/SelectionPage.tsx + showcase/src/chrome/Topbar.tsx (theme switch).
const DATE_RANGES: Segment<string>[] = [
  { label: "Day", value: "day" },
  { label: "Week", value: "week" },
  { label: "Month", value: "month" },
  { label: "Year", value: "year" },
];

// The dense, full-width pay-in rail switch (size sm, fullWidth).
// codemojex-node/apps/economy/src/components/RailPanel.tsx (RAILS → segments).
const RAILS: Segment<string>[] = [
  { label: "Stars", value: "stars" },
  { label: "TON", value: "ton" },
  { label: "Card", value: "card" },
  { label: "Crypto", value: "crypto" },
];

// Controls restate Segmented.prompt.md (verified against Segmented.tsx —
// NO-INVENT, mx.4.md INV-5): `size` (sm|md|lg select), `fullWidth` (boolean);
// `segments` (Segment<T>[]) and the controlled `value`/`onChange` are data, not
// raw controls — they are driven by the render.
const meta: Meta<typeof Segmented<string>> = {
  title: "Selection/Segmented",
  component: Segmented,
  argTypes: {
    size: { control: "inline-radio", options: SIZES },
    fullWidth: { control: "boolean" },
    segments: { control: false },
    value: { control: false },
    onChange: { control: false },
  },
  args: { segments: DATE_RANGES, value: "week", size: "md", fullWidth: false },
};
export default meta;

type Story = StoryObj<typeof Segmented<string>>;

// Args-driven but controlled — the render owns `value` so a click moves the pill.
export const Playground: Story = {
  render: (args) => {
    const [value, setValue] = useState(args.value);
    return <Segmented {...args} value={value} onChange={setValue} />;
  },
};

// The size ramp — sm | md | lg, each independently controlled.
export const Sizes: Story = {
  render: () => (
    <div style={{ display: "flex", flexDirection: "column", gap: "16px", alignItems: "flex-start" }}>
      {SIZES.map((size) => (
        <SegmentedDemo key={size} size={size} />
      ))}
    </div>
  ),
};

// The economy pay-in rail switch — full-width, dense.
// codemojex-node/apps/economy/src/components/RailPanel.tsx
export const RailSwitch: Story = {
  render: () => {
    const [rail, setRail] = useState("stars");
    return (
      <div style={{ maxWidth: "420px" }}>
        <Segmented<string> segments={RAILS} value={rail} onChange={setRail} fullWidth size="sm" />
      </div>
    );
  },
};

function SegmentedDemo({ size }: { size: NonNullable<SegmentedProps<string>["size"]> }) {
  const [value, setValue] = useState("week");
  return <Segmented<string> segments={DATE_RANGES} value={value} onChange={setValue} size={size} />;
}
