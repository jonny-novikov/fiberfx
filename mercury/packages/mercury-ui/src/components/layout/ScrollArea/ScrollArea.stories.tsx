import type { Meta, StoryObj } from "@storybook/react-vite";
import { ScrollArea } from "@mercury/ui";
import type { ScrollAreaScrollbars, ScrollAreaSize } from "@mercury/ui";

// Enum domains traced from ScrollArea.tsx — NO-INVENT (mx.4 INV-5).
const SCROLLBARS: ScrollAreaScrollbars[] = ["vertical", "horizontal", "both"];
const SIZES: ScrollAreaSize[] = ["sm", "md", "lg"];

// Text rows inherit --fg-primary from the base element styles, so the story needs
// no inline color (keeping the INV-2 grep clean).
const Rows = ({ count = 24 }: { count?: number }) => (
  <div style={{ display: "flex", flexDirection: "column", gap: "8px", padding: "4px" }}>
    {Array.from({ length: count }, (_, i) => (
      <p key={i} style={{ margin: 0 }}>
        Row {i + 1} — a line of scrollable content.
      </p>
    ))}
  </div>
);

const meta: Meta<typeof ScrollArea> = {
  title: "Layout/ScrollArea",
  component: ScrollArea,
  argTypes: {
    scrollbars: { control: "inline-radio", options: SCROLLBARS },
    size: { control: "inline-radio", options: SIZES },
    maxHeight: { control: "number" },
    width: { control: "number" },
  },
  args: { scrollbars: "vertical", size: "md", maxHeight: 220, width: 320 },
};
export default meta;

type Story = StoryObj<typeof ScrollArea>;

export const Playground: Story = {
  render: (args) => (
    <ScrollArea {...args}>
      <Rows />
    </ScrollArea>
  ),
};

// The three scrollbar thicknesses.
export const Sizes: Story = {
  render: () => (
    <div style={{ display: "flex", gap: "16px", alignItems: "flex-start" }}>
      {SIZES.map((size) => (
        <ScrollArea key={size} size={size} maxHeight={200} width={220}>
          <Rows />
        </ScrollArea>
      ))}
    </div>
  ),
};
