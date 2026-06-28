import { useState } from "react";
import type { Meta, StoryObj } from "@storybook/react-vite";
import { Slider } from "@mercury/ui";
import type { SliderProps } from "@mercury/ui";

// `size` ramp, typed by the component's own union (NO-INVENT — Slider exports
// no named size type, so the option array is grounded in SliderProps["size"]).
// Slider.prompt.md: sm (2px track) | md (4px track), no color change.
const SIZES: NonNullable<SliderProps["size"]>[] = ["sm", "md"];

// Controls restate Slider.prompt.md (verified against Slider.tsx — NO-INVENT,
// mx.4.md INV-5): `min`/`max`/`step` (number), `label`/`unit` (text),
// `showValue`/`disabled` (boolean), `size` (sm|md select); the controlled
// `value`/`onChange` are driven by the render (onChange carries the coerced number).
const meta: Meta<typeof Slider> = {
  title: "Selection/Slider",
  component: Slider,
  argTypes: {
    min: { control: "number" },
    max: { control: "number" },
    step: { control: "number" },
    label: { control: "text" },
    unit: { control: "text" },
    showValue: { control: "boolean" },
    disabled: { control: "boolean" },
    size: { control: "inline-radio", options: SIZES },
    value: { control: false },
    onChange: { control: false },
  },
  args: {
    label: "Pool portion",
    unit: "%",
    min: 0,
    max: 100,
    step: 1,
    value: 35,
    showValue: true,
    size: "md",
    disabled: false,
  },
};
export default meta;

type Story = StoryObj<typeof Slider>;

// Args-driven but controlled — the render owns `value` so the thumb drags.
export const Playground: Story = {
  render: (args) => {
    const [value, setValue] = useState(args.value);
    return <Slider {...args} value={value} onChange={setValue} />;
  },
};

// The two track ramps — sm | md.
export const Sizes: Story = {
  render: () => (
    <div style={{ display: "flex", flexDirection: "column", gap: "20px", maxWidth: "320px" }}>
      {SIZES.map((size) => (
        <SliderDemo key={size} size={size} label={`Track · ${size}`} />
      ))}
    </div>
  ),
};

// The economy calibration form — a labelled percentage slider plus a fine rate
// slider with the readout suppressed (a sibling Tag shows the value).
// codemojex-node/apps/economy/src/components/CalibrationForm.tsx
export const Calibration: Story = {
  render: () => {
    const [poolPortion, setPoolPortion] = useState(0.35);
    const [akp, setAkp] = useState(0.12);
    return (
      <div style={{ display: "flex", flexDirection: "column", gap: "20px", maxWidth: "320px" }}>
        <Slider
          label="Pool portion"
          unit="%"
          min={0}
          max={100}
          step={1}
          value={Math.round(poolPortion * 100)}
          onChange={(v) => setPoolPortion(v / 100)}
        />
        <Slider min={0.05} max={0.4} step={0.001} showValue={false} value={akp} onChange={setAkp} />
      </div>
    );
  },
};

function SliderDemo({ size, label }: { size: NonNullable<SliderProps["size"]>; label: string }) {
  const [value, setValue] = useState(50);
  return <Slider size={size} label={label} unit="%" value={value} onChange={setValue} />;
}
