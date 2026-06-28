import type { Meta, StoryObj } from "@storybook/react-vite";
import { PasswordStrength } from "@mercury/ui";
import type { StrengthVariant } from "@mercury/ui";

// The variant language, traced from PasswordStrength.tsx (the StrengthVariant
// union — narrower than ProgressVariant: no brand/info) and restated in
// PasswordStrength.prompt.md — NO-INVENT (mx.4.md INV-5).
const STRENGTHS: StrengthVariant[] = ["negative", "caution", "positive"];

// Controls restate PasswordStrength.prompt.md: `score` (0–100 number → the bar
// value), `label` (the strength word, text), `variant` (three-value inline-radio).
// `className` is a styling pass-through, not a control.
const meta: Meta<typeof PasswordStrength> = {
  title: "Feedback/PasswordStrength",
  component: PasswordStrength,
  argTypes: {
    score: { control: { type: "number", min: 0, max: 100, step: 1 } },
    label: { control: "text" },
    variant: { control: "inline-radio", options: STRENGTHS },
  },
  args: {
    score: 30,
    label: "Weak",
    variant: "negative",
  },
  decorators: [
    (Story) => (
      <div style={{ width: "320px" }}>
        <Story />
      </div>
    ),
  ],
};
export default meta;

type Story = StoryObj<typeof PasswordStrength>;

export const Playground: Story = {};

// The three steps of the good/bad scale — score + label + variant move together,
// as the @mercury/effector passwordStrength() helper derives them on the auth flow.
// showcase/src/pages/patterns/AuthFlowPage.tsx
export const States: Story = {
  render: () => (
    <div style={{ display: "flex", flexDirection: "column", gap: "16px", width: "320px" }}>
      <PasswordStrength score={30} label="Weak" variant="negative" />
      <PasswordStrength score={65} label="Fair" variant="caution" />
      <PasswordStrength score={95} label="Strong" variant="positive" />
    </div>
  ),
};
