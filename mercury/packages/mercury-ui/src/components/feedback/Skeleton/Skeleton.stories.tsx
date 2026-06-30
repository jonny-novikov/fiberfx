import type { Meta, StoryObj } from "@storybook/react-vite";
import { Skeleton } from "@mercury/ui";

const meta: Meta<typeof Skeleton> = {
  title: "Feedback/Skeleton",
  component: Skeleton,
  argTypes: {
    width: { control: "text" },
    height: { control: "number" },
    radius: { control: "number" },
    circle: { control: "boolean" },
  },
  args: { width: 240, height: 16, radius: 6 },
};
export default meta;

type Story = StoryObj<typeof Skeleton>;

export const Playground: Story = {};

// A circle placeholder (avatar) beside stacked line placeholders — a loading card.
export const Shapes: Story = {
  render: () => (
    <div style={{ display: "flex", gap: "16px", alignItems: "center", maxWidth: "360px" }}>
      <Skeleton circle width={48} />
      <div style={{ display: "flex", flexDirection: "column", gap: "8px", flex: 1 }}>
        <Skeleton width="60%" height={18} />
        <Skeleton />
        <Skeleton width="80%" />
      </div>
    </div>
  ),
};
