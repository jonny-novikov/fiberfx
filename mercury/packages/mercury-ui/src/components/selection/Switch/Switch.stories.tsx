import type { Meta, StoryObj } from "@storybook/react-vite";
import { Switch } from "@mercury/ui";

// Controls restate Switch.prompt.md (verified against Switch.tsx — NO-INVENT,
// mx.4.md INV-5): `checked` / `disabled` (boolean), `label` (text), `name` /
// `id` (native form attrs). `onChange` fires with the new boolean. The input
// is a native checkbox with role="switch".
const meta: Meta<typeof Switch> = {
  title: "Selection/Switch",
  component: Switch,
  argTypes: {
    checked: { control: "boolean" },
    disabled: { control: "boolean" },
    label: { control: "text" },
    name: { control: "text" },
    id: { control: "text" },
  },
  args: {
    label: "Notifications",
    checked: true,
    disabled: false,
  },
};
export default meta;

type Story = StoryObj<typeof Switch>;

export const Playground: Story = {};

// On / off / disabled — the immediate-setting surface.
// showcase/src/pages/components/SelectionPage.tsx (the settings toggles).
export const States: Story = {
  render: () => (
    <div style={{ display: "flex", flexDirection: "column", gap: "12px" }}>
      <Switch label="On" checked />
      <Switch label="Off" checked={false} />
      <Switch label="Disabled · on" checked disabled />
      <Switch label="Disabled · off" checked={false} disabled />
    </div>
  ),
};
