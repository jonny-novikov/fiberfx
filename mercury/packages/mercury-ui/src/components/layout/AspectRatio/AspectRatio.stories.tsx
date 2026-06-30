import type { Meta, StoryObj } from "@storybook/react-vite";
import { AspectRatio, Skeleton } from "@mercury/ui";

const meta: Meta<typeof AspectRatio> = {
  title: "Layout/AspectRatio",
  component: AspectRatio,
  argTypes: { ratio: { control: "number" } },
  args: { ratio: 16 / 9 },
};
export default meta;

type Story = StoryObj<typeof AspectRatio>;

// The placeholder fill is a Skeleton (its surface is class-driven — no inline ink
// in the story, keeping the INV-2 grep clean).
export const Playground: Story = {
  render: (args) => (
    <div style={{ width: "320px" }}>
      <AspectRatio {...args}>
        <Skeleton width="100%" height="100%" radius={0} />
      </AspectRatio>
    </div>
  ),
};

// Common ratios.
export const Ratios: Story = {
  render: () => (
    <div style={{ display: "flex", gap: "16px", flexWrap: "wrap" }}>
      {[16 / 9, 4 / 3, 1].map((ratio) => (
        <div key={ratio} style={{ width: "200px" }}>
          <AspectRatio ratio={ratio}>
            <Skeleton width="100%" height="100%" radius={0} />
          </AspectRatio>
        </div>
      ))}
    </div>
  ),
};
