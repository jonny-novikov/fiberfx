import type { Meta, StoryObj } from "@storybook/react-vite";
import { Icon } from "@mercury/ui";
import type { IconName } from "@mercury/ui";

// The full IconName set, traced from Icon.tsx (the ICONS keys) and restated in Icon.prompt.md.
// NO-INVENT (mx.8.1-INV8): IconName = keyof (ICONS: Record<string, ReactNode>) widens to `string`,
// so an unknown name is NOT a compile error — this array is verified against the ICONS keys by
// hand (set-equality), not the type.
const ICON_NAMES: IconName[] = [
  "arrow",
  "arrow-up-right",
  "arrow-down-left",
  "check",
  "close",
  "plus",
  "minus",
  "search",
  "star",
  "bell",
  "cog",
  "user",
  "users",
  "home",
  "list",
  "mail",
  "wallet",
  "credit-card",
  "shield",
  "globe",
  "help-circle",
  "chevron-right",
  "chevron-down",
  "alert",
  "info",
  "download",
  "upload",
  "trash",
  "refresh",
  "copy",
  "pause",
  "play",
  "repeat",
  "trending-up",
  "bank",
  "bolt",
  "flow",
  "batch",
];

// Controls are a rendered restatement of Icon.prompt.md: `name` (the IconName
// set), `size` (number, default 16), `strokeWidth` (number, default 2).
const meta: Meta<typeof Icon> = {
  title: "Foundations/Icon",
  component: Icon,
  argTypes: {
    name: { control: "select", options: ICON_NAMES },
    size: { control: { type: "number", min: 8, max: 96, step: 1 } },
    strokeWidth: { control: { type: "number", min: 0.5, max: 4, step: 0.5 } },
  },
  args: { name: "bolt", size: 24, strokeWidth: 2 },
};
export default meta;

type Story = StoryObj<typeof Icon>;

export const Playground: Story = {};

// Every glyph in the set with its name — the leaf surface proven whole.
export const Gallery: Story = {
  render: () => (
    <div
      style={{
        display: "grid",
        gridTemplateColumns: "repeat(auto-fill, minmax(104px, 1fr))",
        gap: "12px",
      }}
    >
      {ICON_NAMES.map((name) => (
        <div
          key={name}
          style={{
            display: "flex",
            flexDirection: "column",
            alignItems: "center",
            gap: "8px",
            padding: "16px 8px",
            border: "1px solid rgb(var(--border-primary))",
            borderRadius: "var(--radius-8)",
            background: "rgb(var(--bg-secondary))",
            color: "rgb(var(--fg-primary))",
          }}
        >
          <Icon name={name} size={24} />
          <span
            style={{
              fontFamily: "var(--font-secondary)",
              fontSize: "var(--text-body-100-size)",
              lineHeight: "var(--text-body-100-lh)",
              color: "rgb(var(--fg-secondary))",
            }}
          >
            {name}
          </span>
        </div>
      ))}
    </div>
  ),
};
