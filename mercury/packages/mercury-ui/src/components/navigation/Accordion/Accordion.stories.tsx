import type { Meta, StoryObj } from "@storybook/react-vite";
import { Accordion } from "@mercury/ui";
import type { AccordionItemData, AccordionProps } from "@mercury/ui";

// `type` restated from AccordionProps (source-typed) — NO-INVENT (mx.4.md INV-5).
const TYPES: NonNullable<AccordionProps["type"]>[] = ["single", "multiple"];

// source-grounded; no app call site — the panels are built from Accordion.tsx.
const FAQ_ITEMS: AccordionItemData[] = [
  {
    value: "what",
    title: "What is Mercury?",
    content: <p>A token-driven, presentational React design system.</p>,
  },
  {
    value: "how",
    title: "How do I theme it?",
    content: <p>Flip a token set on an ancestor — every component re-reads it.</p>,
  },
  {
    value: "more",
    title: "Where are the docs?",
    content: <p>In each component's co-located contract.</p>,
  },
];

// A stack carrying a disabled row — restates the `AccordionItemData.disabled?` member.
// source-grounded; no app call site.
const SHIPPING_ITEMS: AccordionItemData[] = [
  { value: "a", title: "Shipping", content: <p>Ships in 2-3 days.</p> },
  { value: "b", title: "Returns", content: <p>30-day window.</p> },
  { value: "c", title: "Archived", content: <p>Unavailable.</p>, disabled: true },
];

// Controls restate Accordion.prompt.md: `type` (single|multiple), `collapsible`
// (boolean), `defaultValue` (an item value, single mode), `items` driven by the
// render (control: false). Accordion is uncontrolled — no controlled wrapper.
const meta: Meta<typeof Accordion> = {
  title: "Navigation/Accordion",
  component: Accordion,
  argTypes: {
    type: { control: "inline-radio", options: TYPES },
    collapsible: { control: "boolean" },
    defaultValue: { control: "select", options: ["what", "how", "more"] },
    items: { control: false },
  },
  args: {
    items: FAQ_ITEMS,
    type: "single",
    collapsible: true,
    defaultValue: "what",
  },
};
export default meta;

type Story = StoryObj<typeof Accordion>;

export const Playground: Story = {};

// Both fold modes side by side: single keeps one open, multiple accumulates.
export const Modes: Story = {
  render: () => (
    <div style={{ display: "flex", flexDirection: "column", gap: "32px", maxWidth: "520px" }}>
      {TYPES.map((type) => (
        <div key={type} style={{ display: "flex", flexDirection: "column", gap: "12px" }}>
          <span
            style={{
              fontFamily: "var(--font-secondary)",
              fontSize: "var(--text-body-100-size)",
              lineHeight: "var(--text-body-100-lh)",
              color: "rgb(var(--fg-secondary))",
            }}
          >
            {type}
          </span>
          <Accordion items={FAQ_ITEMS} type={type} defaultValue={type === "multiple" ? ["what", "how"] : "what"} />
        </div>
      ))}
    </div>
  ),
};

// A disabled row renders disabled and is skipped by roving focus.
export const WithDisabledItem: Story = {
  args: {
    items: SHIPPING_ITEMS,
    type: "multiple",
    defaultValue: ["a"],
  },
};
