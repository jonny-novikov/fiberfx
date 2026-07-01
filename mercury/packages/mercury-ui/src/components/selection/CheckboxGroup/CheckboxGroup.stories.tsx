import type { Meta, StoryObj } from "@storybook/react-vite";
import { CheckboxGroup } from "@mercury/ui";

// Controls restate CheckboxGroup.prompt.md, verified against CheckboxGroup.tsx
// (NO-INVENT): `items` (value/label/disabled rows), `value`/`defaultValue`
// (string[]), `accent` (the shared color families), `orientation`, `disabled`.
// `onChange` fires with the next full string[] — an action, not a control.
const meta: Meta<typeof CheckboxGroup> = {
  title: "Selection/CheckboxGroup",
  component: CheckboxGroup,
  argTypes: {
    accent: { control: "select", options: ["iris", "indigo", "green", "orange", "plum", "red"] },
    orientation: { control: "inline-radio", options: ["vertical", "horizontal"] },
    disabled: { control: "boolean" },
  },
  args: {
    items: [
      { value: "email", label: "Email" },
      { value: "sms", label: "SMS" },
      { value: "push", label: "Push notifications" },
    ],
    defaultValue: ["email"],
    orientation: "vertical",
    disabled: false,
  },
};
export default meta;

type Story = StoryObj<typeof CheckboxGroup>;

export const Playground: Story = {};

// Orientation + accent + a disabled row, side by side.
// showcase/src/pages/components/SelectionPage.tsx (the multi-select column).
export const States: Story = {
  render: () => (
    <div style={{ display: "flex", flexDirection: "column", gap: "24px" }}>
      <CheckboxGroup
        defaultValue={["email"]}
        items={[
          { value: "email", label: "Email" },
          { value: "sms", label: "SMS" },
          { value: "push", label: "Push (disabled)", disabled: true },
        ]}
      />
      <CheckboxGroup
        accent="green"
        orientation="horizontal"
        defaultValue={["email", "sms"]}
        items={[
          { value: "email", label: "Email" },
          { value: "sms", label: "SMS" },
          { value: "push", label: "Push" },
        ]}
      />
    </div>
  ),
};
