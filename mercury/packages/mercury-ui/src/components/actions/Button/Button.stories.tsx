import type { Meta, StoryObj } from "@storybook/react-vite";
import { Button, Icon } from "@mercury/ui";
import type { ButtonVariant, ButtonSize } from "@mercury/ui";

// The enum language, traced from Button.tsx (the ButtonVariant / ButtonSize
// unions) and restated in Button.prompt.md — NO-INVENT (mx.3.md INV-7).
const VARIANTS: ButtonVariant[] = [
  "primary",
  "secondary",
  "outline",
  "ghost",
  "destructive",
  "inverse",
];
const SIZES: ButtonSize[] = ["sm", "md", "lg"];

// Controls restate Button.prompt.md: `variant` (six-value select), `size`
// (sm|md|lg inline-radio), `loading`/`fullWidth`/`disabled` (boolean).
// `leading`/`trailing` are NOT raw controls — they are driven by a story arg
// rendering a real <Icon /> (mx.3.llms.md "Story shapes").
const meta: Meta<typeof Button> = {
  title: "Actions/Button",
  component: Button,
  argTypes: {
    variant: { control: "select", options: VARIANTS },
    size: { control: "inline-radio", options: SIZES },
    loading: { control: "boolean" },
    fullWidth: { control: "boolean" },
    disabled: { control: "boolean" },
    leading: { control: false },
    trailing: { control: false },
  },
  args: {
    children: "Button",
    variant: "primary",
    size: "md",
    loading: false,
    fullWidth: false,
    disabled: false,
  },
};
export default meta;

type Story = StoryObj<typeof Button>;

export const Playground: Story = {};

// The full matrix: six variants × three sizes.
export const Variants: Story = {
  render: () => (
    <div style={{ display: "flex", flexDirection: "column", gap: "16px" }}>
      {VARIANTS.map((variant) => (
        <div key={variant} style={{ display: "flex", gap: "12px", alignItems: "center" }}>
          {SIZES.map((size) => (
            <Button key={size} variant={variant} size={size}>
              {variant} {size}
            </Button>
          ))}
        </div>
      ))}
    </div>
  ),
};

// The leading slot — a real <Icon /> per Button.prompt.md
// (`leading={<Icon name="download" size={14} />}`).
export const WithIcon: Story = {
  args: {
    children: "Download",
    leading: <Icon name="download" size={14} />,
  },
};
