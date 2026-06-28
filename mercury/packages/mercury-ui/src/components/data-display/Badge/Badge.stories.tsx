import type { Meta, StoryObj } from "@storybook/react-vite";
import { Badge } from "@mercury/ui";
import type { BadgeVariant, BadgeProps } from "@mercury/ui";

// The five-family tone subset, traced from Badge.tsx (the BadgeVariant union)
// and restated in Badge.prompt.md — NO-INVENT. Badge has no neutral/discovery
// (those live on Chip/Tag).
const VARIANTS: BadgeVariant[] = ["brand", "negative", "positive", "caution", "info"];
// `size` has no exported union — typed from the prop so an invented size fails tsc.
const SIZES: NonNullable<BadgeProps["size"]>[] = ["sm", "md", "lg"];

// Controls restate Badge.prompt.md: `variant` (the five-tone select, default
// negative), `size` (sm|md|lg, default md). `children` is the count/short label.
const meta: Meta<typeof Badge> = {
  title: "Data Display/Badge",
  component: Badge,
  argTypes: {
    variant: { control: "select", options: VARIANTS },
    size: { control: "inline-radio", options: SIZES },
  },
  args: {
    children: "3",
    variant: "negative",
    size: "md",
  },
};
export default meta;

type Story = StoryObj<typeof Badge>;

export const Playground: Story = {};

// The five status families.
// showcase/src/pages/components/ChipBadgePage.tsx
export const Variants: Story = {
  render: () => (
    <div style={{ display: "flex", gap: "12px", alignItems: "center" }}>
      <Badge variant="negative">3</Badge>
      <Badge variant="caution">12</Badge>
      <Badge variant="positive">Done</Badge>
      <Badge variant="brand">New</Badge>
      <Badge variant="info">i</Badge>
    </div>
  ),
};

// The size ramp across every tone.
export const Sizes: Story = {
  render: () => (
    <div style={{ display: "flex", flexDirection: "column", gap: "16px" }}>
      {VARIANTS.map((variant) => (
        <div key={variant} style={{ display: "flex", gap: "12px", alignItems: "center" }}>
          {SIZES.map((size) => (
            <Badge key={size} variant={variant} size={size}>
              {variant}
            </Badge>
          ))}
        </div>
      ))}
    </div>
  ),
};
