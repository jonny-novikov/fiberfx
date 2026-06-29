import type { Meta, StoryObj } from "@storybook/react-vite";
import { Label } from "@mercury/ui";
import type { LabelProps, LabelSize } from "@mercury/ui";

// Enum domains traced from Label.tsx (LabelSize exported; the `accent` union is
// inline on LabelProps) — NO-INVENT (mx.4 INV-5).
const SIZES: LabelSize[] = ["sm", "md", "lg"];
type LabelAccent = NonNullable<LabelProps["accent"]>;
const ACCENTS: LabelAccent[] = ["iris", "indigo", "green", "orange", "plum", "red"];

// Controls restate Label.prompt.md: `required` / `optional` markers, `disabled`,
// `size`, `accent` (tints the required *), `hint`.
const meta: Meta<typeof Label> = {
  title: "Inputs/Label",
  component: Label,
  argTypes: {
    required: { control: "boolean" },
    optional: { control: "boolean" },
    disabled: { control: "boolean" },
    size: { control: "inline-radio", options: SIZES },
    accent: { control: "select", options: ACCENTS },
    hint: { control: "text" },
    children: { control: "text" },
  },
  args: {
    children: "Email address",
    htmlFor: "email",
    required: true,
    hint: "We never share it.",
  },
};
export default meta;

type Story = StoryObj<typeof Label>;

export const Playground: Story = {};

// Required / optional / disabled markers and the three sizes.
export const States: Story = {
  render: () => (
    <div style={{ display: "flex", flexDirection: "column", gap: "16px" }}>
      <Label htmlFor="a" required>
        Required field
      </Label>
      <Label htmlFor="b" optional>
        Optional field
      </Label>
      <Label htmlFor="c" required hint="We never share it.">
        With a hint
      </Label>
      <Label htmlFor="d" disabled>
        Disabled field
      </Label>
      {SIZES.map((s) => (
        <Label key={s} htmlFor={`size-${s}`} size={s} required>
          Size {s}
        </Label>
      ))}
    </div>
  ),
};
