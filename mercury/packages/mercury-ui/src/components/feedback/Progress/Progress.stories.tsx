import type { Meta, StoryObj } from "@storybook/react-vite";
import type { ComponentProps } from "react";
import { Progress } from "@mercury/ui";
import type { ProgressVariant } from "@mercury/ui";

// The enum language, traced from Progress.tsx (the ProgressVariant union + the
// size ramp) and restated in Progress.prompt.md — NO-INVENT (mx.4.md INV-5).
const VARIANTS: ProgressVariant[] = ["brand", "positive", "negative", "caution", "info"];

// `size` is an inline union on ProgressProps, not a named export — pull it off the
// props type so an invented value still fails to compile (the NO-INVENT guard).
const SIZES: NonNullable<ComponentProps<typeof Progress>["size"]>[] = ["sm", "md", "lg"];

// Controls restate Progress.prompt.md: `variant` (five-value select), `size`
// (sm|md|lg inline-radio), `value`/`max` (number), `indeterminate` (boolean).
const meta: Meta<typeof Progress> = {
  title: "Feedback/Progress",
  component: Progress,
  argTypes: {
    variant: { control: "select", options: VARIANTS },
    size: { control: "inline-radio", options: SIZES },
    value: { control: { type: "number", min: 0, max: 100, step: 1 } },
    max: { control: { type: "number", min: 1, max: 1000, step: 1 } },
    indeterminate: { control: "boolean" },
  },
  args: {
    variant: "brand",
    size: "md",
    value: 60,
    max: 100,
    indeterminate: false,
  },
  decorators: [
    (Story) => (
      <div style={{ width: "320px" }}>
        <Story />
      </div>
    ),
  ],
};
export default meta;

type Story = StoryObj<typeof Progress>;

export const Playground: Story = {};

// Every variant at a fixed fill — the five status families proven whole.
export const Variants: Story = {
  render: () => (
    <div style={{ display: "flex", flexDirection: "column", gap: "16px", width: "320px" }}>
      {VARIANTS.map((variant) => (
        <Progress key={variant} value={60} variant={variant} />
      ))}
    </div>
  ),
};

// The three track heights (`sm` is the strength-meter height).
export const Sizes: Story = {
  render: () => (
    <div style={{ display: "flex", flexDirection: "column", gap: "16px", width: "320px" }}>
      {SIZES.map((size) => (
        <Progress key={size} value={60} size={size} />
      ))}
    </div>
  ),
};

// The indeterminate shimmer — drops aria-valuenow and ignores `value`.
export const Indeterminate: Story = {
  args: { indeterminate: true },
};
