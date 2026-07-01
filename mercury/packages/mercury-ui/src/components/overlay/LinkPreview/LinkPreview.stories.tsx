import type { Meta, StoryObj } from "@storybook/react-vite";
import { LinkPreview } from "@mercury/ui";
import type { LinkPreviewPlacement } from "@mercury/ui";

// The placement ramp, traced from LinkPreviewPlacement — NO-INVENT.
const PLACEMENTS: LinkPreviewPlacement[] = ["top", "bottom"];

// A compact URL-preview card used as `content`.
const Preview = () => (
  <div style={{ display: "flex", flexDirection: "column", gap: "6px" }}>
    <strong style={{ fontWeight: 600 }}>Mercury Design System</strong>
    <span>A token-driven, presentational React component library.</span>
    <span style={{ fontSize: "12px" }}>mercury.jonnify.com</span>
  </div>
);

// Controls restate LinkPreview.prompt.md: `children` (the focusable link),
// `content` (the preview body), `placement` (above/below), `openDelay`, `width`.
// There is NO `closeDelay` — the preview hides on a fixed 120ms grace.
const meta: Meta<typeof LinkPreview> = {
  title: "Overlay/LinkPreview",
  component: LinkPreview,
  argTypes: {
    children: { control: "text" },
    content: { control: false },
    placement: { control: "inline-radio", options: PLACEMENTS },
    openDelay: { control: "number" },
    width: { control: "number" },
  },
  args: {
    children: "mercury.jonnify.com",
    content: <Preview />,
    placement: "bottom",
    openDelay: 300,
    width: 300,
  },
};
export default meta;

type Story = StoryObj<typeof LinkPreview>;

// Hover the anchor text to reveal the preview (S-5 — the render proof).
export const Playground: Story = {};

// The two placements — a preview above and below a focusable link.
export const Placements: Story = {
  render: () => (
    <div style={{ display: "flex", gap: "120px", padding: "160px 120px" }}>
      {PLACEMENTS.map((p) => (
        <LinkPreview key={p} placement={p} content={<Preview />}>
          <a href="#">Preview {p}</a>
        </LinkPreview>
      ))}
    </div>
  ),
};
