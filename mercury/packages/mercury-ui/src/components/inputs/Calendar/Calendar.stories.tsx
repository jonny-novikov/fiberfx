import type { Meta, StoryObj } from "@storybook/react-vite";
import { useState } from "react";
import { Calendar } from "@mercury/ui";
import { CalendarDate, parseDate } from "@mercury/core";
import type { DateValue } from "@mercury/core";

const meta: Meta<typeof Calendar> = {
  title: "Inputs/Calendar",
  component: Calendar,
  argTypes: {
    accent: { control: "select", options: ["iris", "indigo", "green", "orange", "plum", "red"] },
    locale: { control: "text" },
    firstDayOfWeek: { control: "number" },
    value: { control: false },
    defaultValue: { control: false },
  },
};
export default meta;
type Story = StoryObj<typeof Calendar>;

export const Playground: Story = {};
export const Uncontrolled: Story = { args: { defaultValue: parseDate("2024-03-15") } };
export const Accent: Story = { args: { accent: "indigo", defaultValue: parseDate("2024-03-15") } };
export const Controlled: Story = {
  render: () => {
    const [date, setDate] = useState<DateValue | undefined>(new CalendarDate(2024, 3, 15));
    return <Calendar value={date} onChange={setDate} accent="green" />;
  },
};
