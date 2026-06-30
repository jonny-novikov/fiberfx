import type { Meta, StoryObj } from "@storybook/react-vite";
import { Code } from "@mercury/ui";
import type { CodeProps, CodeVariant, CodeSize } from "@mercury/ui";

// Enum domains traced from Code.tsx (CodeVariant/CodeSize exported; the `accent`
// union is inline on CodeProps) — NO-INVENT (mx.4 INV-5).
const VARIANTS: CodeVariant[] = ["soft", "solid", "outline", "ghost"];
const SIZES: CodeSize[] = ["sm", "md", "lg"];
type CodeAccent = NonNullable<CodeProps["accent"]>;
const ACCENTS: CodeAccent[] = ["iris", "indigo", "green", "orange", "plum", "red"];

const meta: Meta<typeof Code> = {
  title: "Data Display/Code",
  component: Code,
  argTypes: {
    variant: { control: "inline-radio", options: VARIANTS },
    size: { control: "inline-radio", options: SIZES },
    accent: { control: "select", options: ACCENTS },
    block: { control: "boolean" },
    children: { control: "text" },
  },
  args: { variant: "soft", size: "md", block: false, children: "pnpm install @mercury/ui" },
};
export default meta;

type Story = StoryObj<typeof Code>;

export const Playground: Story = {};

// The four surface treatments.
export const Variants: Story = {
  render: () => (
    <div style={{ display: "flex", gap: "12px", alignItems: "center", flexWrap: "wrap" }}>
      {VARIANTS.map((variant) => (
        <Code key={variant} variant={variant}>
          {variant}
        </Code>
      ))}
    </div>
  ),
};

// Accent re-skins the soft surface from each ramp.
export const Accents: Story = {
  render: () => (
    <div style={{ display: "flex", gap: "12px", alignItems: "center", flexWrap: "wrap" }}>
      {ACCENTS.map((accent) => (
        <Code key={accent} accent={accent} variant="soft">
          {accent}
        </Code>
      ))}
    </div>
  ),
};

// A multi-line block.
export const Block: Story = {
  args: {
    block: true,
    children: 'const id = BrandedId.mint("JOB");\nawait queue.enqueue(id);',
  },
};
