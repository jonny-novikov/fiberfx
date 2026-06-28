import type { Meta, StoryObj } from "@storybook/react-vite";
import { Avatar } from "@mercury/ui";
import type { AvatarStatus } from "@mercury/ui";

// The status-dot language, traced from Avatar.tsx (the AvatarStatus union →
// `--bg-<status>`) and restated in Avatar.prompt.md — NO-INVENT. There is no
// brand/neutral/discovery status dot.
const STATUSES: AvatarStatus[] = ["positive", "caution", "negative", "info"];

// Controls restate Avatar.prompt.md: `name` (drives initials + hue), `src`
// (an image URL — renders <img> over a backplate), `size` (square px, default
// 40; font + dot scale from it), `status` (the corner status-dot select).
const meta: Meta<typeof Avatar> = {
  title: "Data Display/Avatar",
  component: Avatar,
  argTypes: {
    name: { control: "text" },
    src: { control: "text" },
    size: { control: { type: "number", min: 16, max: 96, step: 1 } },
    status: { control: "select", options: STATUSES },
  },
  args: {
    name: "Ada Lovelace",
    size: 40,
  },
};
export default meta;

type Story = StoryObj<typeof Avatar>;

export const Playground: Story = {};

// The size ramp — initials hashed to a deterministic hue from the name.
// showcase/src/pages/components/AvatarPage.tsx
export const Sizes: Story = {
  render: () => (
    <div style={{ display: "flex", gap: "16px", alignItems: "center" }}>
      <Avatar name="Ada Lovelace" size={24} />
      <Avatar name="Ada Lovelace" size={40} />
      <Avatar name="Ada Lovelace" size={56} />
      <Avatar name="Ada Lovelace" size={80} />
    </div>
  ),
};

// Each status family as a corner dot.
// showcase/src/pages/components/AvatarPage.tsx
export const Statuses: Story = {
  render: () => (
    <div style={{ display: "flex", gap: "16px", alignItems: "center" }}>
      {STATUSES.map((status) => (
        <Avatar key={status} name="Grace Hopper" size={48} status={status} />
      ))}
    </div>
  ),
};

// An image over the backplate instead of initials.
export const WithImage: Story = {
  args: {
    name: "Radia Perlman",
    src: "https://i.pravatar.cc/96?img=5",
    size: 64,
  },
};
