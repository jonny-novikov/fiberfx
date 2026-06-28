import { useState } from "react";
import type { Meta, StoryObj } from "@storybook/react-vite";
import { Radio } from "@mercury/ui";

// Controls restate Radio.prompt.md (verified against Radio.tsx — NO-INVENT,
// mx.4.md INV-5): `value` (required, the option key echoed by onChange),
// `checked` / `disabled` (boolean), `label` (text), `name` (the group key),
// `id` (native). `onChange` fires with this radio's `value` string.
const meta: Meta<typeof Radio> = {
  title: "Selection/Radio",
  component: Radio,
  argTypes: {
    value: { control: "text" },
    checked: { control: "boolean" },
    disabled: { control: "boolean" },
    label: { control: "text" },
    name: { control: "text" },
    id: { control: "text" },
  },
  args: {
    value: "monthly",
    label: "Monthly",
    name: "billing",
    checked: true,
    disabled: false,
  },
};
export default meta;

type Story = StoryObj<typeof Radio>;

export const Playground: Story = {};

// The composition pattern — there is no RadioGroup wrapper: same `name`,
// one parent useState, `checked={selected === value}`.
// showcase/src/pages/components/SelectionPage.tsx (the billing-cadence group).
export const Group: Story = {
  render: () => {
    const [billing, setBilling] = useState("monthly");
    return (
      <div style={{ display: "flex", flexDirection: "column", gap: "12px" }}>
        <Radio name="billing" value="monthly" label="Monthly" checked={billing === "monthly"} onChange={setBilling} />
        <Radio name="billing" value="quarterly" label="Quarterly" checked={billing === "quarterly"} onChange={setBilling} />
        <Radio name="billing" value="yearly" label="Yearly — save 20%" checked={billing === "yearly"} onChange={setBilling} />
        <Radio name="billing" value="never" label="Disabled option" disabled />
      </div>
    );
  },
};
