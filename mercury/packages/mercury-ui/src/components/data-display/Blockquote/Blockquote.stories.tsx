import type { Meta, StoryObj } from "@storybook/react-vite";
import { Blockquote } from "@mercury/ui";
import type { BlockquoteProps, BlockquoteSize } from "@mercury/ui";

// Enum domains traced from Blockquote.tsx (BlockquoteSize exported type; the
// `accent` union is inline on BlockquoteProps) — NO-INVENT (mx.4 INV-5): an
// invented size/accent is a compile error here.
const SIZES: BlockquoteSize[] = ["sm", "md", "lg"];
type BlockquoteAccent = NonNullable<BlockquoteProps["accent"]>;
const ACCENTS: BlockquoteAccent[] = ["iris", "indigo", "green", "orange", "plum", "red"];

const meta: Meta<typeof Blockquote> = {
  title: "Data Display/Blockquote",
  component: Blockquote,
  argTypes: {
    size: { control: "inline-radio", options: SIZES },
    accent: { control: "select", options: ACCENTS },
    cite: { control: "text" },
    children: { control: "text" },
  },
  args: {
    size: "md",
    cite: "— The BCS law",
    children: "The only values that cross a boundary are identities, and messages about identities.",
  },
};
export default meta;

type Story = StoryObj<typeof Blockquote>;

export const Playground: Story = {};

// The three sizes, stacked.
export const Sizes: Story = {
  render: () => (
    <div style={{ display: "flex", flexDirection: "column", gap: "20px", maxWidth: "480px" }}>
      {SIZES.map((size) => (
        <Blockquote key={size} size={size} cite={`— size ${size}`}>
          A quotation set off by a leading rule, in secondary ink.
        </Blockquote>
      ))}
    </div>
  ),
};

// Accent rules + attribution inks resolve to the `--<ramp>-9` / `--<ramp>-11` families.
export const Accents: Story = {
  render: () => (
    <div style={{ display: "flex", flexDirection: "column", gap: "16px", maxWidth: "480px" }}>
      {ACCENTS.map((accent) => (
        <Blockquote key={accent} accent={accent} cite={`— ${accent}`}>
          A pull quote carried on the {accent} ramp.
        </Blockquote>
      ))}
    </div>
  ),
};
