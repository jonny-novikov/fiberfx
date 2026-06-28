import type { Meta, StoryObj } from "@storybook/react-vite";
import { Tooltip, Button } from "@mercury/ui";

// Tooltip has NO enum props (Tooltip.prompt.md "The enum language": none; the
// .tsx surface is exactly `content` + `children`). `content` is the hover label
// (a text control); `children` is the trigger slot, driven by a story arg
// rendering a real <Button/> (the Button-exemplar slot rule), never a raw
// control. Reveal is pure CSS off the wrapper's :hover (Tooltip.tsx).
const meta: Meta<typeof Tooltip> = {
  title: "Overlay/Tooltip",
  component: Tooltip,
  argTypes: {
    content: { control: "text" },
    children: { control: false },
  },
  args: {
    content: "Copy link to clipboard",
    children: <Button variant="secondary">Share</Button>,
  },
};
export default meta;

type Story = StoryObj<typeof Tooltip>;

// Hover the trigger to reveal the label.
export const Playground: Story = {};

// No enum to iterate (source-grounded; Tooltip has no enum props) — the states
// story varies the wrapped trigger instead: a caption per Button variant, the
// showcase "Tooltip (bonus)" row.
// showcase/src/pages/components/ModalPage.tsx
export const OnTriggers: Story = {
  render: () => (
    <div style={{ display: "flex", gap: "24px", alignItems: "center" }}>
      <Tooltip content="Copy link to clipboard">
        <Button variant="secondary">Share</Button>
      </Tooltip>
      <Tooltip content="You've got mail">
        <Button variant="ghost">Inbox</Button>
      </Tooltip>
      <Tooltip content="Save changes">
        <Button>Save</Button>
      </Tooltip>
    </div>
  ),
};
