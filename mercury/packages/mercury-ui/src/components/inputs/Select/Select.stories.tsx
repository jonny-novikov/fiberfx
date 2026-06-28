import type { Meta, StoryObj } from "@storybook/react-vite";
import { Select } from "@mercury/ui";
import type { SelectOption } from "@mercury/ui";

// Select is a data-prop component: `options: SelectOption[]` drives it
// (Select.prompt.md). The controls restate the Props table: label/hint/error/
// placeholder (text), disabled/required (boolean); `options` is data (control:false,
// passed as args/sample). `onChange` is the NATIVE event (e.target.value), unlike
// Search/AuthCode. SelectOption typed by the exported union — NO-INVENT (mx.4.md
// INV-5).
const OPTIONS: SelectOption[] = [
  { label: "Daily", value: "daily" },
  { label: "Weekly", value: "weekly" },
  { label: "Monthly", value: "monthly" },
  { label: "Never", value: "never", disabled: true },
];

const meta: Meta<typeof Select> = {
  title: "Inputs/Select",
  component: Select,
  argTypes: {
    label: { control: "text" },
    hint: { control: "text" },
    error: { control: "text" },
    placeholder: { control: "text" },
    disabled: { control: "boolean" },
    required: { control: "boolean" },
    options: { control: false },
  },
  args: {
    label: "Digest frequency",
    options: OPTIONS,
    placeholder: "Choose a cadence",
    disabled: false,
    required: false,
  },
};
export default meta;

type Story = StoryObj<typeof Select>;

export const Playground: Story = {};

// Hint / error precedence + disabled, from Select.prompt.md.
export const States: Story = {
  render: () => (
    <div style={{ display: "flex", flexDirection: "column", gap: "16px", maxWidth: "320px" }}>
      <Select label="Digest frequency" options={OPTIONS} hint="How often to email you" defaultValue="weekly" />
      <Select label="Digest frequency" options={OPTIONS} error="Pick a cadence" placeholder="Choose a cadence" />
      <Select label="Locked" options={OPTIONS} defaultValue="daily" disabled />
    </div>
  ),
};

// Data-prop story — the real economy calibration "Average key price (akp)" select,
// driven by a `pkgOptions` array (a "Manual akp" row + one option per PACKAGE, each
// labeled `${keys} keys · ${stars}⭐`, value `String(keys)`).
// codemojex-node/apps/economy/src/components/CalibrationForm.tsx
export const CalibratePackage: Story = {
  render: () => {
    const pkgOptions: SelectOption[] = [
      { label: "Manual akp", value: "manual" },
      { label: "100 keys · 100⭐", value: "100" },
      { label: "500 keys · 450⭐", value: "500" },
      { label: "1200 keys · 1000⭐", value: "1200" },
    ];
    return (
      <div style={{ maxWidth: "320px" }}>
        <Select label="Average key price (akp)" options={pkgOptions} defaultValue="500" />
      </div>
    );
  },
};
