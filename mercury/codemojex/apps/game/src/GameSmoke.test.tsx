import "@testing-library/jest-dom/vitest"; // augments vitest's Assertion with the DOM matchers (toBeInTheDocument, …)
import { describe, expect, it } from "vitest";
import { render, screen } from "@testing-library/react";
import { GameSmoke } from "@/GameSmoke";
import { cn } from "@/lib/cn";
import i18n from "@/i18n/i18n";

// The foundation smoke (cmt.4.1-INV3). jsdom computes no Tailwind pixels (the vitest
// config carries no @tailwindcss/vite), so the suite asserts the wiring — render,
// t(), cn(), the className strings — never getComputedStyle; the pixel proof is
// Operator-observed via the hot-load loop.
describe("GameSmoke", () => {
  it("renders without throwing, showing the translated smoke string", () => {
    render(<GameSmoke />);
    const label = i18n.t("smoke.ping");
    expect(label).not.toBe("smoke.ping"); // i18n initialized — the key resolved from a bundled locale
    expect(screen.getByText(label)).toBeInTheDocument();
  });

  it("merges conflicting Tailwind utilities through cn (last wins)", () => {
    expect(cn("p-2", false && "x", "p-4")).toBe("p-4");
  });

  it("carries the Classic utility set on the rendered tree", () => {
    const { container } = render(<GameSmoke />);
    expect(container.querySelector(".cmjx-game")).not.toBeNull(); // the scope root
    const surface = container.querySelector(".bg-card");
    expect(surface).not.toBeNull();
    expect(surface!.className).toContain("text-primary");
    expect(screen.getByText(i18n.t("smoke.ping")).className).toContain("text-2xs");
  });
});
