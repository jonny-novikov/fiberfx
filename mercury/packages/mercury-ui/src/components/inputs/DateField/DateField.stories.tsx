import type { Meta, StoryObj } from "@storybook/react-vite";
import { useState } from "react";
import { DateField } from "@mercury/ui";
import { CalendarDate, parseDate } from "@mercury/core";
import type { DateValue } from "@mercury/core";

// DateField has NO enum props (DateField.prompt.md "The enum language"): one
// visual form, styled through tokens. The controls restate the Props table —
// label/locale (text), disabled (boolean). `value`/`defaultValue` are DateValue
// objects, not raw controls, so they are story-driven (control: false). The date
// types come from @mercury/core (INV-6). NO-INVENT (mx.4 INV-5).
const meta: Meta<typeof DateField> = {
  title: "Inputs/DateField",
  component: DateField,
  argTypes: {
    label: { control: "text" },
    locale: { control: "text" },
    disabled: { control: "boolean" },
    value: { control: false },
    defaultValue: { control: false },
  },
  args: {
    label: "Due date",
    disabled: false,
  },
};
export default meta;

type Story = StoryObj<typeof DateField>;

export const Playground: Story = {};

// Uncontrolled — seeded from an ISO string via @mercury/core's parseDate
// (DateField.prompt.md "Examples").
export const Uncontrolled: Story = {
  args: {
    label: "Due date",
    defaultValue: parseDate("2024-03-15"),
  },
};

// Controlled — a CalendarDate held in story state, wired value/onChange
// (DateField.prompt.md "Examples").
export const Controlled: Story = {
  render: () => {
    const [date, setDate] = useState<DateValue | undefined>(new CalendarDate(2024, 3, 15));
    return <DateField label="Date of birth" value={date} onChange={setDate} />;
  },
};
