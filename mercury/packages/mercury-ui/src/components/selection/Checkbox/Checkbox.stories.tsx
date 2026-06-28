import type { Meta, StoryObj } from "@storybook/react-vite";
import { Checkbox } from "@mercury/ui";

// Controls are a rendered restatement of Checkbox.prompt.md (verified against
// Checkbox.tsx — NO-INVENT, mx.4.md INV-5): `checked` / `indeterminate` /
// `disabled` (boolean), `label` (text — a ReactNode rendered as a string here),
// `name` / `value` / `id` (native form attrs). `onChange` fires with the new
// boolean, not a control.
const meta: Meta<typeof Checkbox> = {
  title: "Selection/Checkbox",
  component: Checkbox,
  argTypes: {
    checked: { control: "boolean" },
    indeterminate: { control: "boolean" },
    disabled: { control: "boolean" },
    label: { control: "text" },
    name: { control: "text" },
    value: { control: "text" },
    id: { control: "text" },
  },
  args: {
    label: "Remember me",
    checked: false,
    indeterminate: false,
    disabled: false,
  },
};
export default meta;

type Story = StoryObj<typeof Checkbox>;

export const Playground: Story = {};

// The tri-state + disabled surface, side by side.
// showcase/src/pages/components/SelectionPage.tsx (the opt-in column).
export const States: Story = {
  render: () => (
    <div style={{ display: "flex", flexDirection: "column", gap: "12px" }}>
      <Checkbox label="Unchecked" checked={false} />
      <Checkbox label="Checked" checked />
      <Checkbox label="Indeterminate" indeterminate />
      <Checkbox label="Disabled" disabled />
      <Checkbox label="Disabled · checked" checked disabled />
    </div>
  ),
};
