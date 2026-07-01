import type { Meta, StoryObj } from "@storybook/react-vite";
import { RadioCards } from "@mercury/ui";

// Controls restate RadioCards.prompt.md, verified against RadioCards.tsx
// (NO-INVENT): `items` (value/label/description/icon/disabled cards),
// `value`/`defaultValue` (string), `accent`, `columns`, `size`. `onChange`
// fires with the selected value — an action, not a control. Icons are real
// IconName glyphs (foundations/Icon).
const meta: Meta<typeof RadioCards> = {
  title: "Selection/RadioCards",
  component: RadioCards,
  argTypes: {
    accent: { control: "select", options: ["iris", "indigo", "green", "orange", "plum", "red"] },
    size: { control: "inline-radio", options: ["sm", "md", "lg"] },
    columns: { control: { type: "number", min: 1, max: 4 } },
  },
  args: {
    columns: 1,
    size: "md",
    defaultValue: "standard",
    items: [
      { value: "standard", label: "Standard", description: "3–5 business days.", icon: "credit-card" },
      { value: "express", label: "Express", description: "Next business day.", icon: "bolt" },
      { value: "pickup", label: "Store pickup", description: "Ready in 2 hours.", icon: "home" },
    ],
  },
};
export default meta;

type Story = StoryObj<typeof RadioCards>;

export const Playground: Story = {};

// A two-column accented grid with a disabled card.
// showcase/src/pages/components/SelectionPage.tsx (the card column).
export const States: Story = {
  render: () => (
    <RadioCards
      columns={2}
      accent="green"
      defaultValue="standard"
      items={[
        { value: "standard", label: "Standard", description: "3–5 business days.", icon: "credit-card" },
        { value: "express", label: "Express", description: "Next business day.", icon: "bolt" },
        { value: "pickup", label: "Store pickup", description: "Ready in 2 hours.", icon: "home" },
        { value: "freight", label: "Freight", description: "Bulk only.", icon: "bank", disabled: true },
      ]}
    />
  ),
};
