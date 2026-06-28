import type { Meta, StoryObj } from "@storybook/react-vite";
import { Card, Button } from "@mercury/ui";
import type { CardProps } from "@mercury/ui";

// The elevation language, traced from Card.tsx (the `variant` union) and restated
// in Card.prompt.md — NO-INVENT (mx.4.md INV-5). Card exports no dedicated union
// type, so the options are typed by the source prop itself: an invented member is
// a compile error.
const VARIANTS: NonNullable<CardProps["variant"]>[] = ["flat", "raised", "floating"];

// Controls restate Card.prompt.md: `variant` (three-value select), `padding`
// (number), `title` (text — the header label), `actions` (a ReactNode slot, NOT a
// raw control: driven by a story arg rendering a real <Button /> per the Button
// exemplar). `children` is the card body.
const meta: Meta<typeof Card> = {
  title: "Data Display/Card",
  component: Card,
  argTypes: {
    variant: { control: "select", options: VARIANTS },
    padding: { control: { type: "number", min: 0, max: 64, step: 2 } },
    title: { control: "text" },
    actions: { control: false },
  },
  args: {
    variant: "flat",
    padding: 20,
    children: "A padded surface for grouping related content.",
  },
};
export default meta;

type Story = StoryObj<typeof Card>;

export const Playground: Story = {};

// The elevation ramp: flat → raised → floating.
export const Variants: Story = {
  render: () => (
    <div style={{ display: "flex", gap: "16px", flexWrap: "wrap" }}>
      {VARIANTS.map((variant) => (
        <Card key={variant} variant={variant} style={{ minWidth: 180 }}>
          <strong>{variant}</strong>
        </Card>
      ))}
    </div>
  ),
};

// The header row — `title` left, `actions` (a real <Button />) right. Absorbs the
// economy card-header pattern (`.ecn-card-title` + flex space-between):
// codemojex-node/apps/economy/src/components/RevenueFlow.tsx + MarginCurve.tsx.
export const WithHeader: Story = {
  args: {
    variant: "raised",
    title: "Revenue flow / guess",
    actions: (
      <Button size="sm" variant="outline">
        Edit
      </Button>
    ),
    children: "Where one guess's gross goes: gross → net | store-fee → pool | margin.",
  },
};
