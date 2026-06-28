import type { Meta, StoryObj } from "@storybook/react-vite";
import { useState } from "react";
import { Search } from "@mercury/ui";

// Search has NO enum props and NO `error`/state styling (Search.prompt.md
// "Notes"), and NO app call site — source-grounded; no app call site. The controls
// restate Search.prompt.md's Props table: placeholder (text), disabled (boolean).
// `value`/`onChange`/`onSearch` are the controlled string contract — driven by the
// render's state, NOT raw controls. NO-INVENT (mx.4.md INV-5).
const meta: Meta<typeof Search> = {
  title: "Inputs/Search",
  component: Search,
  argTypes: {
    placeholder: { control: "text" },
    disabled: { control: "boolean" },
    value: { control: false },
    onChange: { control: false },
    onSearch: { control: false },
  },
  args: {
    placeholder: "Search",
    disabled: false,
  },
};
export default meta;

type Story = StoryObj<typeof Search>;

// Controlled: Search requires `value` + the string-valued `onChange`; the render
// owns the query so the clear (×) button and Enter→onSearch / Escape→clear keyboard
// contract work live.
// source-grounded; no app call site
export const Playground: Story = {
  render: (args) => {
    const [query, setQuery] = useState("");
    return <Search {...args} value={query} onChange={setQuery} />;
  },
};

// The states: an empty field, a field with a value (the × clear button appears),
// and a disabled field (clear hidden, entry blocked).
// source-grounded; no app call site
export const States: Story = {
  render: () => {
    const [empty, setEmpty] = useState("");
    const [filled, setFilled] = useState("payments");
    return (
      <div style={{ display: "flex", flexDirection: "column", gap: "16px", maxWidth: "320px" }}>
        <Search value={empty} onChange={setEmpty} placeholder="Filter jobs" onSearch={() => undefined} />
        <Search value={filled} onChange={setFilled} placeholder="Filter jobs" />
        <Search value="locked" onChange={() => undefined} disabled />
      </div>
    );
  },
};
