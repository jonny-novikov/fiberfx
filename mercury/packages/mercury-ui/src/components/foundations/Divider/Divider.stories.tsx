import type { Meta, StoryObj } from "@storybook/react-vite";
import { Divider } from "@mercury/ui";
import type { DividerProps } from "@mercury/ui";

// The orientation enum, traced from Divider.tsx (the inline
// "horizontal" | "vertical" union on DividerProps) and restated in
// Divider.prompt.md — NO-INVENT (mx.4.md INV-5). Divider exports no standalone
// orientation type, so the array is typed by the prop union itself; an invented
// member is a compile error.
type DividerOrientation = NonNullable<DividerProps["orientation"]>;
const ORIENTATIONS: DividerOrientation[] = ["horizontal", "vertical"];

// Controls restate Divider.prompt.md: `orientation` (horizontal|vertical
// inline-radio) + `label` (plain text — the contract's "pass plain text ('or'),
// not a pre-styled node"; a label turns the plain rule into the "— or —"
// splitter, rendered uppercase by the style). `className` is the escape-hatch
// prop, not restated as a control (the Icon/Button exemplars omit it too).
const meta: Meta<typeof Divider> = {
  title: "Foundations/Divider",
  component: Divider,
  argTypes: {
    orientation: { control: "inline-radio", options: ORIENTATIONS },
    label: { control: "text" },
  },
  args: {
    orientation: "horizontal",
    label: "or",
  },
  // A horizontal divider is width:100% (Divider.prompt.md "Width"), so the demo
  // is wrapped in a fixed-width column for it to fill a realistic container.
  decorators: [
    (Story) => (
      <div style={{ width: "320px", padding: "16px" }}>
        <Story />
      </div>
    ),
  ],
};
export default meta;

type Story = StoryObj<typeof Divider>;

export const Playground: Story = {};

// The rendered forms of the rule, grounded in the contract's cited call sites:
// the plain <hr>, the labelled "— or —" splitter (showcase DividerPage +
// AuthFlowPage), the labelled section breaks (economy CalibrationForm), and the
// vertical inline rule shown in a row that gives it a height to fill.
export const States: Story = {
  render: () => (
    <div style={{ display: "flex", flexDirection: "column", gap: "24px", width: "320px" }}>
      {/* Plain rule + labelled splitters — showcase/src/pages/components/DividerPage.tsx */}
      <Divider />
      <Divider label="or" />
      <Divider label="or continue with email" />
      {/* The "or" between SSO and email sign-in — showcase/src/pages/patterns/AuthFlowPage.tsx */}
      <Divider label="or sign in with email" />
      {/* Labelled section breaks in a calibration form — codemojex-node/apps/economy/src/components/CalibrationForm.tsx */}
      <Divider label="store fees" />
      <Divider label="prize pool" />
      {/* Vertical — inline, fills the row height — showcase/src/pages/components/DividerPage.tsx */}
      <div
        style={{
          display: "flex",
          alignItems: "center",
          gap: "12px",
          height: "20px",
          color: "rgb(var(--fg-primary))",
          fontFamily: "var(--font-secondary)",
          fontSize: "var(--text-body-100-size)",
          lineHeight: "var(--text-body-100-lh)",
        }}
      >
        <span>Edit</span>
        <Divider orientation="vertical" />
        <span>Delete</span>
        <Divider orientation="vertical" />
        <span>Share</span>
      </div>
    </div>
  ),
};
