import type { Meta, StoryObj } from "@storybook/react-vite";
import { RadioGroup } from "@mercury/ui";

// Controls restate RadioGroup.prompt.md, verified against RadioGroup.tsx
// (NO-INVENT): `items` (value/label/disabled rows), `value`/`defaultValue`
// (string), `name` (shared native name), `accent`, `orientation`, `disabled`.
// `onChange` fires with the selected value — an action, not a control.
const meta: Meta<typeof RadioGroup> = {
  title: "Selection/RadioGroup",
  component: RadioGroup,
  argTypes: {
    accent: { control: "select", options: ["iris", "indigo", "green", "orange", "plum", "red"] },
    orientation: { control: "inline-radio", options: ["vertical", "horizontal"] },
    disabled: { control: "boolean" },
    name: { control: "text" },
  },
  args: {
    items: [
      { value: "card", label: "Credit card" },
      { value: "bank", label: "Bank transfer" },
      { value: "wallet", label: "Wallet balance" },
    ],
    defaultValue: "card",
    orientation: "vertical",
    disabled: false,
  },
};
export default meta;

type Story = StoryObj<typeof RadioGroup>;

export const Playground: Story = {};

// Orientation + accent + a disabled row, side by side.
// showcase/src/pages/components/SelectionPage.tsx (the single-select column).
export const States: Story = {
  render: () => (
    <div style={{ display: "flex", flexDirection: "column", gap: "24px" }}>
      <RadioGroup
        defaultValue="card"
        items={[
          { value: "card", label: "Credit card" },
          { value: "bank", label: "Bank transfer" },
          { value: "wallet", label: "Wallet (disabled)", disabled: true },
        ]}
      />
      <RadioGroup
        accent="iris"
        orientation="horizontal"
        defaultValue="newest"
        items={[
          { value: "newest", label: "Newest" },
          { value: "oldest", label: "Oldest" },
          { value: "popular", label: "Popular" },
        ]}
      />
    </div>
  ),
};
