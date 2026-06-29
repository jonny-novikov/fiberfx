import type { Meta, StoryObj } from "@storybook/react-vite";
import { Separator } from "@mercury/ui";
import type { SeparatorOrientation } from "@mercury/ui";

// The orientation enum, traced from Separator.tsx (the exported
// SeparatorOrientation union) — NO-INVENT (mx.4 INV-5).
const ORIENTATIONS: SeparatorOrientation[] = ["horizontal", "vertical"];

// Controls restate Separator.prompt.md: `orientation`, `label` (horizontal only),
// `decorative` (role="none" vs role="separator"). `size` is the dynamic-length
// escape hatch, not restated as a control.
const meta: Meta<typeof Separator> = {
  title: "Foundations/Separator",
  component: Separator,
  argTypes: {
    orientation: { control: "inline-radio", options: ORIENTATIONS },
    label: { control: "text" },
    decorative: { control: "boolean" },
  },
  args: {
    orientation: "horizontal",
    label: "or",
    decorative: true,
  },
  // A horizontal separator is width:100%, so the demo is wrapped in a fixed-width
  // column for it to fill a realistic container.
  decorators: [
    (Story) => (
      <div style={{ width: "320px", padding: "16px" }}>
        <Story />
      </div>
    ),
  ],
};
export default meta;

type Story = StoryObj<typeof Separator>;

export const Playground: Story = {};

// The rendered forms: plain rule, labelled splitter, and the vertical inline rule
// shown in a row that gives it a height to fill.
export const States: Story = {
  render: () => (
    <div style={{ display: "flex", flexDirection: "column", gap: "24px", width: "320px" }}>
      <Separator />
      <Separator label="or" />
      <Separator label="or continue with email" />
      <div style={{ display: "flex", alignItems: "center", gap: "12px", height: "24px" }}>
        <span>Edit</span>
        <Separator orientation="vertical" decorative={false} />
        <span>Delete</span>
        <Separator orientation="vertical" decorative={false} />
        <span>Share</span>
      </div>
    </div>
  ),
};
