import type { Meta, StoryObj } from "@storybook/react-vite";
import { useState } from "react";
import { Textarea } from "@mercury/ui";

// Textarea has NO enum props (Textarea.prompt.md "Notes") and NO app call site —
// source-grounded; no app call site. The controls restate Textarea.prompt.md's
// Props table: label/hint/error/placeholder (text), resizable/disabled/required
// (boolean), rows/maxLength (number). NO-INVENT (mx.4.md INV-5).
const meta: Meta<typeof Textarea> = {
  title: "Inputs/Textarea",
  component: Textarea,
  argTypes: {
    label: { control: "text" },
    hint: { control: "text" },
    error: { control: "text" },
    placeholder: { control: "text" },
    resizable: { control: "boolean" },
    disabled: { control: "boolean" },
    required: { control: "boolean" },
    rows: { control: { type: "number", min: 1, max: 20, step: 1 } },
    maxLength: { control: { type: "number", min: 1, max: 1000, step: 1 } },
  },
  args: {
    label: "Bio",
    placeholder: "Tell us about yourself",
    hint: "A sentence or two.",
    resizable: false,
    disabled: false,
    required: false,
    rows: 4,
  },
};
export default meta;

type Story = StoryObj<typeof Textarea>;

export const Playground: Story = {};

// The states from Textarea.prompt.md "Examples": hint, error precedence,
// resizable, and disabled.
// source-grounded; no app call site
export const States: Story = {
  render: () => (
    <div style={{ display: "flex", flexDirection: "column", gap: "16px", maxWidth: "360px" }}>
      <Textarea label="Bio" placeholder="Tell us about yourself" hint="A sentence or two." />
      <Textarea label="Message" defaultValue="Required field left blank" error="Message is required" />
      <Textarea label="Notes" rows={6} resizable />
      <Textarea label="Locked" defaultValue="read-only" disabled />
    </div>
  ),
};

// The live character counter — `maxLength` drives the `count/maxLength` footer
// (flags `is-over` at the cap); only a controlled string `value` is measured.
// source-grounded; no app call site
export const WithCounter: Story = {
  render: () => {
    const [msg, setMsg] = useState("Counting characters live…");
    return (
      <div style={{ maxWidth: "360px" }}>
        <Textarea
          label="Message"
          maxLength={280}
          value={msg}
          onChange={(e) => setMsg(e.target.value)}
          hint="Up to 280 characters."
        />
      </div>
    );
  },
};
