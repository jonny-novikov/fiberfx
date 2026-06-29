import type { Meta, StoryObj } from "@storybook/react-vite";
import { Heading } from "@mercury/ui";
import type { HeadingProps, HeadingSize, HeadingWeight } from "@mercury/ui";

// Enum domains traced from Heading.tsx (HeadingSize / HeadingWeight exported
// types; the `accent` union is inline on HeadingProps) — NO-INVENT (mx.4 INV-5):
// an invented size/weight/accent is a compile error here.
const SIZES: HeadingSize[] = [1, 2, 3, 4, 5, 6, 7, 8, 9];
const WEIGHTS: HeadingWeight[] = ["regular", "medium", "semibold", "bold"];
type HeadingAccent = NonNullable<HeadingProps["accent"]>;
const ACCENTS: HeadingAccent[] = ["iris", "indigo", "green", "orange", "plum", "red"];

// Controls restate Heading.prompt.md: `size` (1..9, display sizes 5–9 ride DM
// Mono), `weight`, `align`, `accent` (ramp ink) and `truncate`.
const meta: Meta<typeof Heading> = {
  title: "Foundations/Heading",
  component: Heading,
  argTypes: {
    size: { control: "inline-radio", options: SIZES },
    weight: { control: "inline-radio", options: WEIGHTS },
    align: { control: "inline-radio", options: ["left", "center", "right"] },
    accent: { control: "select", options: ACCENTS },
    truncate: { control: "boolean" },
    children: { control: "text" },
  },
  args: {
    size: 6,
    weight: "bold",
    children: "The quick brown fox",
  },
};
export default meta;

type Story = StoryObj<typeof Heading>;

export const Playground: Story = {};

// The full size scale — sizes 5–9 render in DM Mono (the display face), 1–4 in
// DM Sans, the canon split.
export const Sizes: Story = {
  render: () => (
    <div style={{ display: "flex", flexDirection: "column", gap: "12px" }}>
      {SIZES.map((s) => (
        <Heading key={s} size={s}>
          Heading size {s}
        </Heading>
      ))}
    </div>
  ),
};

// Accent inks resolve to the `--<ramp>-11` token families (class-driven, no runtime helper).
export const Accents: Story = {
  render: () => (
    <div style={{ display: "flex", flexDirection: "column", gap: "8px" }}>
      {ACCENTS.map((a) => (
        <Heading key={a} size={4} accent={a}>
          {a} heading
        </Heading>
      ))}
    </div>
  ),
};
