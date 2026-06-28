import type { Meta, StoryObj } from "@storybook/react-vite";
import { Chip, Icon } from "@mercury/ui";
import type { ChipVariant, ChipProps } from "@mercury/ui";

// The seven status tones, traced from Chip.tsx (the ChipVariant union) and
// restated in Chip.prompt.md — NO-INVENT. An unknown tone is a compile error.
const VARIANTS: ChipVariant[] = ["neutral", "brand", "positive", "negative", "caution", "info", "discovery"];
// `size` has no exported union — typed from the prop so an invented size fails tsc.
const SIZES: NonNullable<ChipProps["size"]>[] = ["sm", "md", "lg"];

// Controls restate Chip.prompt.md: `variant` (the seven-tone select), `size`
// (sm|md|lg), `selected` (boolean). `leading`/`onRemove`/`onClick`/`className`
// are NOT raw controls — slots/handlers are driven by story args/render
// (the Button exemplar).
const meta: Meta<typeof Chip> = {
  title: "Data Display/Chip",
  component: Chip,
  argTypes: {
    variant: { control: "select", options: VARIANTS },
    size: { control: "inline-radio", options: SIZES },
    selected: { control: "boolean" },
    leading: { control: false },
    onRemove: { control: false },
    onClick: { control: false },
    className: { control: false },
  },
  args: {
    children: "Live",
    variant: "positive",
    size: "md",
    selected: false,
  },
};
export default meta;

type Story = StoryObj<typeof Chip>;

export const Playground: Story = {};

// The full tone set.
// showcase/src/pages/components/ChipBadgePage.tsx
export const Variants: Story = {
  render: () => (
    <div style={{ display: "flex", flexWrap: "wrap", gap: "12px", alignItems: "center" }}>
      {VARIANTS.map((variant) => (
        <Chip key={variant} variant={variant}>
          {variant}
        </Chip>
      ))}
    </div>
  ),
};

// The size ramp.
export const Sizes: Story = {
  render: () => (
    <div style={{ display: "flex", gap: "12px", alignItems: "center" }}>
      {SIZES.map((size) => (
        <Chip key={size} variant="brand" size={size}>
          Pro
        </Chip>
      ))}
    </div>
  ),
};

// The leading slot — a real <Icon /> per Chip.prompt.md (`leading` is a ReactNode
// slot, never a raw control).
export const WithLeadingIcon: Story = {
  args: {
    children: "Verified",
    variant: "info",
    leading: <Icon name="shield" size={12} />,
  },
};

// Removable + selectable — onRemove renders the trailing × button.
// showcase/src/pages/components/ChipBadgePage.tsx
export const Removable: Story = {
  args: {
    children: "design",
    variant: "neutral",
    onRemove: () => {},
  },
};
