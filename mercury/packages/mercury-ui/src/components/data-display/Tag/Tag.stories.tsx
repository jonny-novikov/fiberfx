import type { Meta, StoryObj } from "@storybook/react-vite";
import { Tag } from "@mercury/ui";
import type { ChipVariant, TagProps } from "@mercury/ui";

// The tone language, traced from Tag.tsx (`tone?: ChipVariant`, passed straight
// to Chip's `variant`) and restated in Tag.prompt.md — NO-INVENT. An unknown
// tone is a compile error.
const TONES: ChipVariant[] = ["neutral", "brand", "positive", "negative", "caution", "info", "discovery"];
// `size` has no exported union — typed from the prop so an invented size fails tsc.
const SIZES: NonNullable<TagProps["size"]>[] = ["sm", "md", "lg"];

// Controls restate Tag.prompt.md: `tone` (the ChipVariant select), `dot`
// (boolean — the 6px currentColor dot, default on), `size` (sm|md|lg, default
// sm). `children` is the label text.
const meta: Meta<typeof Tag> = {
  title: "Data Display/Tag",
  component: Tag,
  argTypes: {
    tone: { control: "select", options: TONES },
    dot: { control: "boolean" },
    size: { control: "inline-radio", options: SIZES },
  },
  args: {
    children: "Healthy",
    tone: "positive",
    dot: true,
    size: "sm",
  },
};
export default meta;

type Story = StoryObj<typeof Tag>;

export const Playground: Story = {};

// The full tone set, each with its leading dot.
export const Tones: Story = {
  render: () => (
    <div style={{ display: "flex", flexWrap: "wrap", gap: "12px", alignItems: "center" }}>
      {TONES.map((tone) => (
        <Tag key={tone} tone={tone}>
          {tone}
        </Tag>
      ))}
    </div>
  ),
};

// Dotless tags — the dense-flow form the economy revenue flow uses.
// codemojex-node/apps/economy/src/components/RevenueFlow.tsx
export const Dotless: Story = {
  render: () => (
    <div style={{ display: "flex", gap: "12px", alignItems: "center" }}>
      <Tag tone="info" dot={false}>
        gross
      </Tag>
      <Tag tone="positive" dot={false}>
        +$0.018 margin
      </Tag>
      <Tag tone="negative" dot={false}>
        −$0.004 margin
      </Tag>
    </div>
  ),
};
