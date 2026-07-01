import type { Meta, StoryObj } from "@storybook/react-vite";
import { fn } from "storybook/test"; // SB 10.4.6 CORE subpath — zero new dependency (mx.8.2-INV6)
import { Link, Icon } from "@mercury/ui";
import type { LinkSize, LinkProps } from "@mercury/ui";

// The enum language, traced from Link.tsx (the LinkSize union + the inline
// `type` union on LinkProps) and restated in Link.prompt.md — NO-INVENT
// (mx.4.md). An invented member fails to compile.
const SIZES: LinkSize[] = ["sm", "md"];
const TYPES: NonNullable<LinkProps["type"]>[] = ["button", "submit", "reset"];

// Controls restate Link.prompt.md: `href` (text — set ⇒ <a>, else <button>),
// `size` (sm|md inline-radio), `muted`/`disabled` (boolean), `type` (the native
// button type, used in button mode), `target`/`rel`/`aria-label` (anchor/a11y
// text). `leading`/`trailing`/`onClick` are NOT raw controls — the icon slots
// are driven by a story arg rendering a real <Icon /> (the Button exemplar).
const meta: Meta<typeof Link> = {
  title: "Actions/Link",
  component: Link,
  argTypes: {
    href: { control: "text" },
    size: { control: "inline-radio", options: SIZES },
    muted: { control: "boolean" },
    disabled: { control: "boolean" },
    type: { control: "inline-radio", options: TYPES },
    target: { control: "text" },
    rel: { control: "text" },
    "aria-label": { control: "text" },
    children: { control: "text" },
    leading: { control: false },
    trailing: { control: false },
    onClick: { control: false },
  },
  args: {
    children: "Forgot password?",
    href: "#",
    size: "md",
    muted: false,
    disabled: false,
    type: "button",
    onClick: fn(), // the spy — logs to the SB core Actions panel on click (mx.8.2-INV7; onClick argType already control:false)
  },
};
export default meta;

type Story = StoryObj<typeof Link>;

export const Playground: Story = {};

// The size ramp — the LinkSize union iterated (md 14px, sm 13px).
export const Sizes: Story = {
  render: () => (
    <div style={{ display: "flex", flexDirection: "column", gap: "12px", alignItems: "flex-start" }}>
      {SIZES.map((size) => (
        <Link key={size} href="#" size={size}>
          {size} link
        </Link>
      ))}
    </div>
  ),
};

// The state vocabulary: brand vs muted, the icon slots (a real <Icon />), the
// disabled state, and button mode (no href → <button>).
// Grounded in showcase/src/pages/components/LinkPage.tsx + patterns/AuthFlowPage.tsx.
export const States: Story = {
  render: () => (
    <div style={{ display: "flex", flexDirection: "column", gap: "12px", alignItems: "flex-start" }}>
      <Link href="#">Brand link</Link>
      <Link href="#" muted>
        Privacy policy
      </Link>
      <Link href="#" leading={<Icon name="arrow" size={14} />}>
        Back to sign in
      </Link>
      <Link href="#" trailing={<Icon name="chevron-right" size={14} />}>
        Continue
      </Link>
      <Link disabled>Resend in 28s</Link>
      <Link size="sm">Resend code</Link>
    </div>
  ),
};
