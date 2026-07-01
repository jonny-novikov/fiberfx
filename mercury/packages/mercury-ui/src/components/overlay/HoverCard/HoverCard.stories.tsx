import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, userEvent, within } from "storybook/test"; // SB 10.4.6 CORE subpath
import { HoverCard } from "@mercury/ui";
import type { HoverCardPlacement } from "@mercury/ui";

// The placement ramp, traced from HoverCardPlacement — NO-INVENT.
const PLACEMENTS: HoverCardPlacement[] = ["top", "bottom", "left", "right"];

// A small profile card used as `content` across the demos.
const Profile = () => (
  <div style={{ display: "flex", flexDirection: "column", gap: "4px" }}>
    <strong style={{ fontWeight: 600 }}>Jane Doe</strong>
    <span>Product design · San Francisco</span>
  </div>
);

// Controls restate HoverCard.prompt.md: `children` (the focusable anchor),
// `content` (the card body), `placement` (the anchored side), `openDelay` /
// `closeDelay` (the hover/focus timers), `width` (px).
const meta: Meta<typeof HoverCard> = {
  title: "Overlay/HoverCard",
  component: HoverCard,
  argTypes: {
    children: { control: "text" },
    content: { control: false },
    placement: { control: "inline-radio", options: PLACEMENTS },
    openDelay: { control: "number" },
    closeDelay: { control: "number" },
    width: { control: "number" },
  },
  args: {
    children: "Hover me",
    content: <Profile />,
    placement: "bottom",
    openDelay: 250,
    closeDelay: 150,
    width: 280,
  },
};
export default meta;

type Story = StoryObj<typeof HoverCard>;

// Hover the text to reveal the card (plain text is not focusable — the keyboard
// path is proven in the a11y story below).
export const Playground: Story = {};

// The placement states — each card anchors to a different side of a focusable
// button; generous padding so no card clips the frame.
export const Placements: Story = {
  render: () => (
    <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "80px", padding: "120px" }}>
      {PLACEMENTS.map((p) => (
        <HoverCard key={p} placement={p} content={<Profile />}>
          <button type="button">Anchor {p}</button>
        </HoverCard>
      ))}
    </div>
  ),
};

// INV-A11Y (the FOCUS proof, S-4/S-8) — FOCUS, not only hover, opens the card:
// tab to the anchor button, then the role="dialog" card appears.
export const A11yFocus: Story = {
  name: "a11y — focus opens the card",
  render: () => (
    <div style={{ padding: "80px" }}>
      <HoverCard openDelay={80} content={<Profile />}>
        <button type="button">Jane Doe</button>
      </HoverCard>
    </div>
  ),
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    const body = within(canvasElement.ownerDocument.body);
    const anchor = canvas.getByRole("button", { name: "Jane Doe" });

    await expect(body.queryByRole("dialog")).toBeNull();

    // Keyboard focus (not hover) must open the card.
    await userEvent.tab();
    await expect(anchor).toHaveFocus();
    await body.findByRole("dialog", {}, { timeout: 80 + 800 });
  },
};
