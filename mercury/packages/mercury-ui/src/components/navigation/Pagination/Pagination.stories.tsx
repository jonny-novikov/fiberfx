import type { Meta, StoryObj } from "@storybook/react-vite";
import { useState } from "react";
import { Pagination } from "@mercury/ui";
import type { PaginationProps } from "@mercury/ui";

// `size` restated from PaginationProps (source-typed) — NO-INVENT (mx.4.md INV-5).
const SIZES: NonNullable<PaginationProps["size"]>[] = ["sm", "md"];

// Pagination is controlled (`page`/`onPageChange`); a small stateful wrapper holds
// the page so the stepper is interactive in the story.
// source-grounded; no app call site — built from Pagination.tsx.
function ControlledPagination(props: PaginationProps) {
  const [page, setPage] = useState(props.page);
  return <Pagination {...props} page={page} onPageChange={setPage} />;
}

// Controls restate Pagination.prompt.md: `page`/`count`/`siblingCount` (numbers),
// `size` (sm|md), `caption` (text), `onPageChange` the controlled callback (driven
// by the render).
const meta: Meta<typeof Pagination> = {
  title: "Navigation/Pagination",
  component: Pagination,
  argTypes: {
    page: { control: { type: "number", min: 1 } },
    count: { control: { type: "number", min: 1 } },
    siblingCount: { control: { type: "number", min: 0, max: 3, step: 1 } },
    size: { control: "inline-radio", options: SIZES },
    caption: { control: "text" },
    onPageChange: { control: false },
  },
  args: {
    page: 1,
    count: 12,
    siblingCount: 1,
    size: "md",
    caption: "Showing 1-10 of 120",
    onPageChange: () => {},
  },
  render: (args) => <ControlledPagination {...args} />,
};
export default meta;

type Story = StoryObj<typeof Pagination>;

export const Playground: Story = {};

// Both sizes: sm is the dense footer control, md the base.
export const Sizes: Story = {
  render: () => (
    <div style={{ display: "flex", flexDirection: "column", gap: "32px" }}>
      {SIZES.map((size) => (
        <div key={size} style={{ display: "flex", flexDirection: "column", gap: "12px" }}>
          <span
            style={{
              fontFamily: "var(--font-secondary)",
              fontSize: "var(--text-body-100-size)",
              lineHeight: "var(--text-body-100-lh)",
              color: "rgb(var(--fg-secondary))",
            }}
          >
            {size}
          </span>
          <ControlledPagination page={3} count={12} size={size} onPageChange={() => {}} />
        </div>
      ))}
    </div>
  ),
};

// A large count with a wider sibling window — the list collapses to ellipses.
export const Windowed: Story = {
  args: {
    page: 6,
    count: 40,
    siblingCount: 2,
    caption: "Showing 51-60 of 400",
  },
};
