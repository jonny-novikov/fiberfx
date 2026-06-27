import { test, expect } from "vitest";
import { render, screen } from "@testing-library/react";
import { Button } from "../src/index";

// The React render floor (jsdom project): proves @testing-library/react@16 +
// React 19 render the package's public Button. This is also the automated
// stand-in for SP-0's manual "apps still render" smoke.
test("renders a Button with its label and the mx-btn class", () => {
  render(<Button>Go</Button>);
  const btn = screen.getByRole("button", { name: "Go" });
  expect(btn).toBeInTheDocument();
  expect(btn).toHaveClass("mx-btn");
});
