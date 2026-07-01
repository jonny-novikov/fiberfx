/**
 * The mount-contract proof (HSE-INV1/INV6): the model-driven mount keeps the
 * outward contract byte-compatible — mount(el, props, bridge) -> {update,
 * unmount} renders GameEdge from the initial props with no fallback flash,
 * update() re-renders through the model, one-off server events still reach
 * GameEdge's toasts through the raw bridge, unmount cleans the container —
 * and remount() (the hot-swap half) rebuilds the tree from the RETAINED props.
 */
import "@testing-library/jest-dom/vitest";
import { describe, it, expect, vi } from "vitest";
import { act } from "@testing-library/react";
import { createRoot } from "react-dom/client";
import { mount, remount, GameEdge, type LiveMount } from "@/index";
import type { Bridge, GameProps } from "@/types";

vi.mock("@/components/sprite", () => ({ cellStyle: () => ({}) }));

function makeProps(me: string, prizeUsd: number | string): GameProps {
  return {
    view: {
      game: "GAM1",
      room: null,
      emojiset: null,
      ends_ms: null,
      prize_pool: 0,
      prize_usd: prizeUsd,
      guess_fee: 1,
      free: false,
      status: "open",
    },
    leaderboard: [],
    history: [],
    me,
  };
}

function makeBridge() {
  const listeners = new Set<(name: string, payload: unknown) => void>();
  const bridge: Bridge = {
    pushEvent: vi.fn(),
    onServerEvent: (cb) => {
      listeners.add(cb);
      return () => listeners.delete(cb);
    },
  };
  const emit = (name: string, payload?: unknown) =>
    act(() => {
      for (const cb of listeners) cb(name, payload);
    });
  return { bridge, emit };
}

describe("mount (the model-driven LiveView path)", () => {
  it("renders GameEdge from the initial props immediately, and exports GameEdge", () => {
    const el = document.createElement("div");
    document.body.appendChild(el);
    const { bridge } = makeBridge();

    let handle!: ReturnType<typeof mount>;
    act(() => {
      handle = mount(el, makeProps("PLR1", 10), bridge);
    });

    expect(el.textContent).toContain("$10"); // InfoDashboard prize — no fallback flash
    expect(typeof handle.update).toBe("function");
    expect(typeof handle.unmount).toBe("function");
    expect(typeof GameEdge).toBe("function");

    act(() => handle.unmount());
    expect(el.innerHTML).toBe("");
    el.remove();
  });

  it("update() re-renders through the model with the fresh props", () => {
    const el = document.createElement("div");
    document.body.appendChild(el);
    const { bridge } = makeBridge();

    let handle!: ReturnType<typeof mount>;
    act(() => {
      handle = mount(el, makeProps("PLR1", 10), bridge);
    });
    act(() => handle.update(makeProps("PLR1", 25)));

    expect(el.textContent).toContain("$25");
    expect(el.textContent).not.toContain("$10");
    act(() => handle.unmount());
    el.remove();
  });

  it("one-off server events still reach GameEdge's toast through the raw bridge", () => {
    const el = document.createElement("div");
    document.body.appendChild(el);
    const { bridge, emit } = makeBridge();

    let handle!: ReturnType<typeof mount>;
    act(() => {
      handle = mount(el, makeProps("PLR1", 10), bridge);
    });
    emit("revealed", {});

    expect(el.textContent).toContain("Код раскрыт");
    act(() => handle.unmount());
    el.remove();
  });

  it("remount() rebuilds the tree from the RETAINED props (the hot-swap seed)", () => {
    const el = document.createElement("div");
    document.body.appendChild(el);
    const { bridge } = makeBridge();

    // The facade a prior module instance would have retained: latest props recorded.
    const live: LiveMount = {
      el,
      bridge,
      props: makeProps("PLR1", 77),
      root: createRoot(el),
      apply: () => {},
    };
    act(() => remount(live));

    expect(el.textContent).toContain("$77");
    act(() => live.root.unmount());
    el.remove();
  });
});
