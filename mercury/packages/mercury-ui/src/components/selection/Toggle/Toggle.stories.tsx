import { useState } from "react";
import type { Meta, StoryObj } from "@storybook/react-vite";
import { Toggle, ToggleGroup, Icon } from "@mercury/ui";
import type { ToggleSize, ToggleGroupItem } from "@mercury/ui";

// `size` ramp, typed by the component's exported union (NO-INVENT — mx.4.md
// INV-5). Toggle.prompt.md: sm (32px) | md | lg, height/padding only.
const SIZES: ToggleSize[] = ["sm", "md", "lg"];

// source-grounded; no app call site — Toggle has no usage in showcase/economy,
// so every sample below is constructed from Toggle.tsx (Toggle.prompt.md Notes).
const ALIGN_ITEMS: ToggleGroupItem[] = [
  { value: "left", label: "Left" },
  { value: "center", label: "Center" },
  { value: "right", label: "Right" },
];

// Controls restate Toggle.prompt.md (verified against Toggle.tsx — NO-INVENT):
// `pressed`/`defaultPressed`/`disabled` (boolean), `size` (sm|md|lg select),
// `children` (text — a label; an <Icon/> is shown in WithIcon). `onPressedChange`
// fires with the next pressed boolean. Omitting `pressed` runs it uncontrolled.
const meta: Meta<typeof Toggle> = {
  title: "Selection/Toggle",
  component: Toggle,
  argTypes: {
    pressed: { control: "boolean" },
    defaultPressed: { control: "boolean" },
    disabled: { control: "boolean" },
    size: { control: "inline-radio", options: SIZES },
    children: { control: "text" },
  },
  args: {
    children: "Bold",
    defaultPressed: false,
    disabled: false,
    size: "md",
  },
};
export default meta;

type Story = StoryObj<typeof Toggle>;

export const Playground: Story = {};

// The size ramp — sm | md | lg, each starting pressed.
export const Sizes: Story = {
  render: () => (
    <div style={{ display: "flex", gap: "12px", alignItems: "center" }}>
      {SIZES.map((size) => (
        <Toggle key={size} size={size} defaultPressed>
          {size}
        </Toggle>
      ))}
    </div>
  ),
};

// An icon-only toggle — a real <Icon/> in children + an aria-label (the
// composition Toggle.prompt.md cites: Toggle composes Icon).
export const WithIcon: Story = {
  args: {
    "aria-label": "Bold",
    children: <Icon name="star" size={16} />,
  },
};

// The co-located ToggleGroup (same module) — a single-select bordered row.
// source-grounded; no app call site (Toggle.prompt.md).
export const Group: Story = {
  render: () => {
    const [align, setAlign] = useState("center");
    return (
      <ToggleGroup
        type="single"
        value={align}
        onValueChange={(v) => setAlign(v as string)}
        items={ALIGN_ITEMS}
      />
    );
  },
};
