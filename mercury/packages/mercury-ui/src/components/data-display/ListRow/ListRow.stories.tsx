import type { Meta, StoryObj } from "@storybook/react-vite";
import { ListRow, Card, Icon } from "@mercury/ui";

// Controls restate ListRow.prompt.md: `label`/`description`/`value` are text;
// `leading`/`trailing` are ReactNode slots (NOT raw controls — driven by a story
// arg rendering a real <Icon /> per the Button exemplar); `onClick` decides the
// interactive <button> vs static <div> root. NO-INVENT (mx.4.md INV-5).
const meta: Meta<typeof ListRow> = {
  title: "Data Display/ListRow",
  component: ListRow,
  argTypes: {
    label: { control: "text" },
    description: { control: "text" },
    value: { control: "text" },
    leading: { control: false },
    trailing: { control: false },
    onClick: { control: false },
  },
  args: {
    label: "Profile",
    value: "Ana Ruiz",
    leading: <Icon name="user" size={18} />,
    trailing: <Icon name="chevron-right" size={18} />,
  },
};
export default meta;

type Story = StoryObj<typeof ListRow>;

export const Playground: Story = {};

// A settings list — interactive rows (leading icon + label + value + chevron),
// grouped in a Card. Generalizes apps/mobile/src/chrome/Row.tsx.
const SETTINGS = [
  { icon: "user", label: "Profile", value: "Ana Ruiz" },
  { icon: "bell", label: "Notifications", value: "On" },
  { icon: "shield", label: "Security", value: "2FA enabled" },
  { icon: "credit-card", label: "Payment methods", value: "Visa ···· 4242" },
] as const;

export const SettingsList: Story = {
  render: () => (
    <Card padding={0} style={{ overflow: "hidden", maxWidth: 360 }}>
      {SETTINGS.map((row) => (
        <ListRow
          key={row.label}
          leading={<Icon name={row.icon} size={18} />}
          label={row.label}
          value={row.value}
          trailing={<Icon name="chevron-right" size={18} />}
          onClick={() => {}}
        />
      ))}
    </Card>
  ),
};

// An activity feed — static rows (leading icon + label/description + amount),
// grouped in a Card. Generalizes apps/mobile/src/chrome/ActivityList.tsx.
const ACTIVITY = [
  { icon: "arrow-down-left", label: "Received from Ana", meta: "Today · 2:14 PM", amount: "+$240.00" },
  { icon: "arrow-up-right", label: "Sent to Marco", meta: "Yesterday · 9:02 AM", amount: "-$58.00" },
  { icon: "credit-card", label: "Card top-up", meta: "Jun 24 · 6:30 PM", amount: "+$500.00" },
] as const;

export const ActivityFeed: Story = {
  render: () => (
    <Card padding={0} style={{ overflow: "hidden", maxWidth: 360 }}>
      {ACTIVITY.map((row) => (
        <ListRow
          key={row.label}
          leading={<Icon name={row.icon} size={18} />}
          label={row.label}
          description={row.meta}
          value={row.amount}
        />
      ))}
    </Card>
  ),
};
