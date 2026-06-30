import type { Meta, StoryObj } from "@storybook/react-vite";
import { Spinner } from "@mercury/ui";
import type { SpinnerProps, SpinnerSize } from "@mercury/ui";

// Enum domains traced from Spinner.tsx (SpinnerSize exported type; the `accent`
// union is inline on SpinnerProps) — NO-INVENT (mx.4 INV-5): an invented
// size/accent is a compile error here.
const SIZES: SpinnerSize[] = ["sm", "md", "lg"];
type SpinnerAccent = NonNullable<SpinnerProps["accent"]>;
const ACCENTS: SpinnerAccent[] = ["iris", "indigo", "green", "orange", "plum", "red"];

const meta: Meta<typeof Spinner> = {
  title: "Feedback/Spinner",
  component: Spinner,
  argTypes: {
    size: { control: "inline-radio", options: SIZES },
    accent: { control: "select", options: ACCENTS },
    label: { control: "text" },
  },
  args: { size: "md", label: "Loading" },
};
export default meta;

type Story = StoryObj<typeof Spinner>;

export const Playground: Story = {};

// The three named sizes.
export const Sizes: Story = {
  render: () => (
    <div style={{ display: "flex", alignItems: "center", gap: "16px" }}>
      {SIZES.map((size) => (
        <Spinner key={size} size={size} />
      ))}
    </div>
  ),
};

// Accent arcs resolve to the `--<ramp>-9` token families.
export const Accents: Story = {
  render: () => (
    <div style={{ display: "flex", alignItems: "center", gap: "16px" }}>
      {ACCENTS.map((accent) => (
        <Spinner key={accent} size="lg" accent={accent} label={`Loading (${accent})`} />
      ))}
    </div>
  ),
};
