import type { Meta, StoryObj } from "@storybook/react-vite";
import { Collapsible } from "@mercury/ui";
import type { CollapsibleProps } from "@mercury/ui";

// Enum domain traced from Collapsible.tsx (the `accent` union is inline on
// CollapsibleProps) — NO-INVENT (mx.4 INV-5): an invented accent is a compile error here.
type CollapsibleAccent = NonNullable<CollapsibleProps["accent"]>;
const ACCENTS: CollapsibleAccent[] = ["iris", "indigo", "green", "orange", "plum", "red"];

const meta: Meta<typeof Collapsible> = {
  title: "Layout/Collapsible",
  component: Collapsible,
  argTypes: {
    title: { control: "text" },
    defaultOpen: { control: "boolean" },
    bordered: { control: "boolean" },
    accent: { control: "select", options: ACCENTS },
    width: { control: "number" },
    children: { control: "text" },
  },
  args: {
    title: "Connection details",
    defaultOpen: false,
    bordered: true,
    accent: "iris",
    width: 360,
    children: "Host, port, and credentials for the upstream service.",
  },
};
export default meta;

type Story = StoryObj<typeof Collapsible>;

export const Playground: Story = {};

// Pre-expanded, showing the disclosed body and the open-state toggle tint.
export const Open: Story = {
  args: { title: "Advanced", defaultOpen: true },
};

// Accent toggle tints (open) resolve to the `--<ramp>-3` / `--<ramp>-11` families.
export const Accents: Story = {
  render: () => (
    <div style={{ display: "flex", flexDirection: "column", gap: "12px" }}>
      {ACCENTS.map((accent) => (
        <Collapsible key={accent} title={`${accent} disclosure`} accent={accent} defaultOpen>
          The toggle is tinted on the {accent} ramp when open.
        </Collapsible>
      ))}
    </div>
  ),
};
