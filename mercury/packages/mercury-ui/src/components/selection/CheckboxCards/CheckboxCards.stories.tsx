import type { Meta, StoryObj } from "@storybook/react-vite";
import { CheckboxCards } from "@mercury/ui";

// Controls restate CheckboxCards.prompt.md, verified against CheckboxCards.tsx
// (NO-INVENT): `items` (value/label/description/icon/disabled cards),
// `value`/`defaultValue` (string[]), `accent`, `columns`, `size`. `onChange`
// fires with the next full string[] — an action, not a control. Icons are real
// IconName glyphs (foundations/Icon).
const meta: Meta<typeof CheckboxCards> = {
  title: "Selection/CheckboxCards",
  component: CheckboxCards,
  argTypes: {
    accent: { control: "select", options: ["iris", "indigo", "green", "orange", "plum", "red"] },
    size: { control: "inline-radio", options: ["sm", "md", "lg"] },
    columns: { control: { type: "number", min: 1, max: 4 } },
  },
  args: {
    columns: 1,
    size: "md",
    defaultValue: ["analytics"],
    items: [
      { value: "analytics", label: "Analytics", description: "Dashboards and export.", icon: "trending-up" },
      { value: "support", label: "Priority support", description: "Same-day replies.", icon: "bolt" },
      { value: "audit", label: "Audit log", description: "Every change, retained.", icon: "shield" },
    ],
  },
};
export default meta;

type Story = StoryObj<typeof CheckboxCards>;

export const Playground: Story = {};

// A two-column accented grid with a disabled card.
// showcase/src/pages/components/SelectionPage.tsx (the card column).
export const States: Story = {
  render: () => (
    <CheckboxCards
      columns={2}
      accent="indigo"
      defaultValue={["analytics"]}
      items={[
        { value: "analytics", label: "Analytics", description: "Dashboards and export.", icon: "trending-up" },
        { value: "support", label: "Priority support", description: "Same-day replies.", icon: "bolt" },
        { value: "audit", label: "Audit log", description: "Every change, retained.", icon: "shield" },
        { value: "sso", label: "SSO", description: "Enterprise only.", icon: "users", disabled: true },
      ]}
    />
  ),
};
