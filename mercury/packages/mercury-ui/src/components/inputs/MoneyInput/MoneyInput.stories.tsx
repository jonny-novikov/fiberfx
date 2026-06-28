import type { Meta, StoryObj } from "@storybook/react-vite";
import { MoneyInput } from "@mercury/ui";

// Controls restate MoneyInput.prompt.md: `currency`/`label`/`hint`/`error`/
// `placeholder` are text; `value`/`onChange` are controlled (left uncontrolled in
// the Playground). No enum props — like Input, the only stylistic state is
// `error`. NO-INVENT (mx.4.md INV-5).
const meta: Meta<typeof MoneyInput> = {
  title: "Inputs/MoneyInput",
  component: MoneyInput,
  argTypes: {
    currency: { control: "text" },
    label: { control: "text" },
    hint: { control: "text" },
    error: { control: "text" },
    placeholder: { control: "text" },
  },
  args: {
    currency: "$",
    label: "Amount",
    placeholder: "0.00",
  },
};
export default meta;

type Story = StoryObj<typeof MoneyInput>;

export const Playground: Story = {};

// Default / hint / error — the field states, grounded in the Send-screen amount
// block. apps/mobile/src/screens/Send.tsx (the `.em-amt` USD prefix + hint/error).
export const States: Story = {
  render: () => (
    <div style={{ display: "flex", flexDirection: "column", gap: "20px", maxWidth: 320 }}>
      <MoneyInput currency="USD" label="Amount" defaultValue="240.00" />
      <MoneyInput currency="USD" label="Amount" hint="Available: $4,218.40 USD" defaultValue="58.00" />
      <MoneyInput currency="USD" label="Amount" error="Exceeds available balance" defaultValue="9999.00" />
    </div>
  ),
};

// The currency affix is any string — a symbol or an ISO code.
export const Currencies: Story = {
  render: () => (
    <div style={{ display: "flex", flexDirection: "column", gap: "20px", maxWidth: 320 }}>
      <MoneyInput currency="$" label="USD" defaultValue="100.00" />
      <MoneyInput currency="€" label="EUR" defaultValue="92.40" />
      <MoneyInput currency="USD" label="ISO code" defaultValue="100.00" />
    </div>
  ),
};
