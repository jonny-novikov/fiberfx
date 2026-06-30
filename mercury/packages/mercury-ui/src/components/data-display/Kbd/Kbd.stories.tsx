import type { Meta, StoryObj } from "@storybook/react-vite";
import { Kbd } from "@mercury/ui";
import type { KbdSize } from "@mercury/ui";

// Enum domain traced from Kbd.tsx — NO-INVENT (mx.4 INV-5).
const SIZES: KbdSize[] = ["sm", "md", "lg"];

const meta: Meta<typeof Kbd> = {
  title: "Data Display/Kbd",
  component: Kbd,
  argTypes: {
    size: { control: "inline-radio", options: SIZES },
    children: { control: "text" },
  },
  args: { size: "md", children: "Esc" },
};
export default meta;

type Story = StoryObj<typeof Kbd>;

export const Playground: Story = {};

// The three cap sizes.
export const Sizes: Story = {
  render: () => (
    <div style={{ display: "flex", gap: "12px", alignItems: "center" }}>
      {SIZES.map((size) => (
        <Kbd key={size} size={size}>
          K
        </Kbd>
      ))}
    </div>
  ),
};

// A multi-key chord.
export const Chord: Story = {
  render: () => (
    <div style={{ display: "flex", gap: "6px", alignItems: "center" }}>
      <Kbd>⌘</Kbd>
      <Kbd>⇧</Kbd>
      <Kbd>P</Kbd>
    </div>
  ),
};
