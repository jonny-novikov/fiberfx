import type { Meta, StoryObj } from "@storybook/react-vite";
import { Input, Icon } from "@mercury/ui";

// Input has NO enum props — `type` is the native HTML attr (passed through via
// …rest), not a Mercury style enum (Input.prompt.md "Notes"). The controls are a
// rendered restatement of Input.prompt.md's Props table: label/hint/error/
// placeholder (text), disabled/required (boolean). `leading`/`trailing` are slots,
// NOT raw controls — driven by a story arg rendering a real <Icon /> (the Button
// exemplar). NO-INVENT (mx.4.md INV-5).
const meta: Meta<typeof Input> = {
  title: "Inputs/Input",
  component: Input,
  argTypes: {
    label: { control: "text" },
    hint: { control: "text" },
    error: { control: "text" },
    placeholder: { control: "text" },
    disabled: { control: "boolean" },
    required: { control: "boolean" },
    leading: { control: false },
    trailing: { control: false },
  },
  args: {
    label: "Email",
    placeholder: "you@company.com",
    disabled: false,
    required: false,
  },
};
export default meta;

type Story = StoryObj<typeof Input>;

export const Playground: Story = {};

// The hint-vs-error precedence + disabled/required states from Input.prompt.md
// "Examples": `error` takes the place of `hint`; `required` renders the ` *` marker.
export const States: Story = {
  render: () => (
    <div style={{ display: "flex", flexDirection: "column", gap: "16px", maxWidth: "320px" }}>
      <Input label="Workspace" placeholder="acme" hint="3–32 characters" />
      <Input label="Subdomain" defaultValue="mercury" error="That subdomain is already taken" />
      <Input label="Full name" placeholder="Ada Lovelace" required />
      <Input label="Locked" defaultValue="read-only" disabled />
    </div>
  ),
};

// The leading slot — a real <Icon /> per Input.prompt.md
// (`leading={<Icon name="search" size={14} />}`).
export const WithIcon: Story = {
  args: {
    label: "Search",
    placeholder: "Search documentation",
    type: "search",
    leading: <Icon name="search" size={14} />,
  },
};
