import type { Meta, StoryObj } from "@storybook/react-vite";
import { fn } from "storybook/test"; // SB 10.4.6 CORE subpath — zero new dependency (mx.8.2-INV6)
import { IconButton } from "@mercury/ui";
import type { IconButtonVariant, IconButtonSize, IconButtonShape } from "@mercury/ui";

// Enum domains traced from IconButton.tsx (the exported variant/size/shape
// unions — byte-equal to ButtonProps' variant/size minus `inverse`) —
// NO-INVENT (mx.4 INV-5).
const VARIANTS: IconButtonVariant[] = ["primary", "secondary", "outline", "ghost", "destructive"];
const SIZES: IconButtonSize[] = ["sm", "md", "lg"];
const SHAPES: IconButtonShape[] = ["circle", "square"];

// Controls restate IconButton.prompt.md: `icon` (a glyph from the Icon set),
// `label` (→ aria-label), `variant`, `size`, `shape`, `disabled`.
const meta: Meta<typeof IconButton> = {
  title: "Actions/IconButton",
  component: IconButton,
  argTypes: {
    icon: { control: "select", options: ["close", "plus", "search", "trash", "bell", "download", "cog", "copy"] },
    label: { control: "text" },
    variant: { control: "inline-radio", options: VARIANTS },
    size: { control: "inline-radio", options: SIZES },
    shape: { control: "inline-radio", options: SHAPES },
    disabled: { control: "boolean" },
    onClick: { control: false }, // spied via args, not a control widget (mx.8.2-D2)
  },
  args: {
    icon: "close",
    label: "Close",
    variant: "secondary",
    size: "md",
    shape: "circle",
    onClick: fn(), // the spy — logs to the SB core Actions panel on click (mx.8.2-INV7)
  },
};
export default meta;

type Story = StoryObj<typeof IconButton>;

export const Playground: Story = {};

// All five variants (sharing the Button token surface) at the default round shape.
export const Variants: Story = {
  render: () => (
    <div style={{ display: "flex", alignItems: "center", gap: "12px" }}>
      {VARIANTS.map((v) => (
        <IconButton key={v} icon="bell" label={v} variant={v} />
      ))}
    </div>
  ),
};

// Sizes (sm/md/lg) and the two shapes — circle (--radius-full) vs square.
export const SizesAndShapes: Story = {
  render: () => (
    <div style={{ display: "flex", flexDirection: "column", gap: "16px" }}>
      <div style={{ display: "flex", alignItems: "center", gap: "12px" }}>
        {SIZES.map((s) => (
          <IconButton key={s} icon="search" label={`search ${s}`} variant="primary" size={s} />
        ))}
      </div>
      <div style={{ display: "flex", alignItems: "center", gap: "12px" }}>
        {SHAPES.map((sh) => (
          <IconButton key={sh} icon="plus" label={`add ${sh}`} variant="outline" shape={sh} />
        ))}
      </div>
    </div>
  ),
};
