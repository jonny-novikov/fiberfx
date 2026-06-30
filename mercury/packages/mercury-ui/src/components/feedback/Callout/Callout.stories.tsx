import type { Meta, StoryObj } from "@storybook/react-vite";
import { Callout } from "@mercury/ui";
import type { CalloutIntent, CalloutVariant } from "@mercury/ui";

// Enum domains traced from Callout.tsx (CalloutIntent / CalloutVariant exported
// types) — NO-INVENT (mx.4 INV-5): an invented intent/variant is a compile error here.
const INTENTS: CalloutIntent[] = ["info", "brand", "positive", "caution", "negative", "discovery"];
const VARIANTS: CalloutVariant[] = ["soft", "surface", "outline"];

const meta: Meta<typeof Callout> = {
  title: "Feedback/Callout",
  component: Callout,
  argTypes: {
    intent: { control: "inline-radio", options: INTENTS },
    variant: { control: "inline-radio", options: VARIANTS },
    size: { control: "inline-radio", options: ["sm", "md", "lg"] },
    title: { control: "text" },
    children: { control: "text" },
  },
  args: {
    intent: "info",
    variant: "soft",
    size: "md",
    title: "Heads up",
    children: "The export runs on the server clock — local time is not used.",
  },
};
export default meta;

type Story = StoryObj<typeof Callout>;

export const Playground: Story = {};

// Each intent on the soft fill — the semantic token families.
export const Intents: Story = {
  render: () => (
    <div style={{ display: "flex", flexDirection: "column", gap: "12px", maxWidth: "440px" }}>
      {INTENTS.map((intent) => (
        <Callout key={intent} intent={intent} title={`${intent} callout`}>
          A short note carried on the {intent} tone family.
        </Callout>
      ))}
    </div>
  ),
};

// The three fill/border treatments, holding intent constant.
export const Variants: Story = {
  render: () => (
    <div style={{ display: "flex", flexDirection: "column", gap: "12px", maxWidth: "440px" }}>
      {VARIANTS.map((variant) => (
        <Callout key={variant} intent="brand" variant={variant} title={`${variant} variant`}>
          The same intent under each treatment.
        </Callout>
      ))}
    </div>
  ),
};
