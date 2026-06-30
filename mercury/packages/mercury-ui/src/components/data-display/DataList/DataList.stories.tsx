import type { Meta, StoryObj } from "@storybook/react-vite";
import { DataList } from "@mercury/ui";
import type { DataListEntry, DataListOrientation, DataListSize } from "@mercury/ui";

// Enum domains traced from DataList.tsx — NO-INVENT (mx.4 INV-5): an invented
// orientation/size is a compile error here.
const ORIENTATIONS: DataListOrientation[] = ["horizontal", "vertical"];
const SIZES: DataListSize[] = ["sm", "md", "lg"];

const SAMPLE: DataListEntry[] = [
  { label: "Account", value: "ACME Holdings" },
  { label: "Status", value: "Active" },
  { label: "Plan", value: "Enterprise" },
  { label: "Renews", value: "30 Jun 2026" },
];

const meta: Meta<typeof DataList> = {
  title: "Data Display/DataList",
  component: DataList,
  argTypes: {
    orientation: { control: "inline-radio", options: ORIENTATIONS },
    size: { control: "inline-radio", options: SIZES },
    labelWidth: { control: "number" },
  },
  args: { orientation: "horizontal", size: "md", items: SAMPLE },
};
export default meta;

type Story = StoryObj<typeof DataList>;

export const Playground: Story = {};

// Side-by-side vs stacked.
export const Orientations: Story = {
  render: () => (
    <div style={{ display: "flex", flexDirection: "column", gap: "32px", maxWidth: "420px" }}>
      {ORIENTATIONS.map((orientation) => (
        <DataList key={orientation} orientation={orientation} items={SAMPLE} />
      ))}
    </div>
  ),
};

// The three type/gap sizes.
export const Sizes: Story = {
  render: () => (
    <div style={{ display: "flex", flexDirection: "column", gap: "32px", maxWidth: "420px" }}>
      {SIZES.map((size) => (
        <DataList key={size} size={size} items={SAMPLE} />
      ))}
    </div>
  ),
};
