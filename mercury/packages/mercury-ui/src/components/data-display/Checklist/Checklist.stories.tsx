import type { Meta, StoryObj } from "@storybook/react-vite";
import { Checklist } from "@mercury/ui";
import type { ChecklistItem } from "@mercury/ui";

// Checklist is a data-prop component: `items` (ChecklistItem[]) drives the rows,
// each toggling its ✓/○ marker by `met`. Controls restate Checklist.prompt.md —
// `items`/`className` are structured props, not raw controls. Sample data is the
// live password-rules list from a real call site (cited).
// showcase/src/pages/patterns/AuthFlowPage.tsx

const passwordRules: ChecklistItem[] = [
  { label: "8+ characters", met: true },
  { label: "Upper & lower case", met: true },
  { label: "A number", met: false },
];

const meta: Meta<typeof Checklist> = {
  title: "Data Display/Checklist",
  component: Checklist,
  argTypes: {
    items: { control: false },
    className: { control: false },
  },
  args: {
    items: passwordRules,
  },
};
export default meta;

type Story = StoryObj<typeof Checklist>;

export const Playground: Story = {};

// The met / partial / unmet states of the same rule set.
export const States: Story = {
  render: () => {
    const rules = (length: boolean, mixedCase: boolean, number: boolean): ChecklistItem[] => [
      { label: "8+ characters", met: length },
      { label: "Upper & lower case", met: mixedCase },
      { label: "A number", met: number },
    ];
    return (
      <div style={{ display: "flex", gap: "32px", flexWrap: "wrap" }}>
        <Checklist items={rules(false, false, false)} />
        <Checklist items={rules(true, true, false)} />
        <Checklist items={rules(true, true, true)} />
      </div>
    );
  },
};
