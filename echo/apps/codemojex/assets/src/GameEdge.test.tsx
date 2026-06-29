import "@testing-library/jest-dom/vitest"; // augments vitest's Assertion with the DOM matchers (toBeInTheDocument, …)
import { describe, expect, it, vi } from "vitest";
import { act, fireEvent, render, screen, within } from "@testing-library/react";
import { GameEdge } from "@/GameEdge";
import type { Bridge, EmojiSet, GameProps, GameView } from "@/types";

// Decouple the tests from sprite-sheet math (background-position pixels). We exercise
// GameEdge's OWN logic — picks, the six-emoji cap, submit, toasts, the bridge wiring —
// through the real child components (EmojiKeyboard/EmojiSlots/GuessActions/…), stubbing
// only the pure styling helper so a missing sprite URL can never break a behavioural test.
vi.mock("@/components/sprite", () => ({ cellStyle: () => ({}) }));

// Six distinct "XXYY" codes plus two spares, so we can overshoot the CODE_LEN=6 cap.
const CODES = ["0000", "0011", "0022", "0033", "0044", "0055", "0066", "0077"];

function makeSet(): EmojiSet {
  return { id: "ES1", sprite_url: "https://cdn/sprite.png", cell_size: 40, cols: 4, rows: 4, codes: CODES };
}

function makeView(over: Partial<GameView> = {}): GameView {
  return {
    game: "GAM1",
    room: null,
    emojiset: makeSet(),
    ends_ms: null,
    prize_pool: 0,
    prize_usd: 10,
    guess_fee: 1,
    free: false,
    status: "open",
    totals: { players: 2, attempts: 5 },
    ...over,
  };
}

function makeProps(over: Partial<GameProps> = {}): GameProps {
  return { view: makeView(), leaderboard: [], history: [], me: "PLR1", ...over };
}

// A bridge whose onServerEvent captures the host callback, so tests can push server
// events (`emit`) the way GameLive would, and whose teardown is observable (`off`).
function makeBridge() {
  let cb: ((name: string, payload: any) => void) | null = null;
  const off = vi.fn();
  const bridge: Bridge = {
    pushEvent: vi.fn(),
    onServerEvent: vi.fn((fn: (name: string, payload: any) => void) => {
      cb = fn;
      return off;
    }),
  };
  const emit = (name: string, payload?: any) => act(() => cb?.(name, payload));
  return { bridge, off, emit };
}

function renderGame(over: Partial<GameProps> = {}) {
  const { bridge, off, emit } = makeBridge();
  const props = makeProps(over);
  const utils = render(<GameEdge {...props} bridge={bridge} />);
  return { ...utils, bridge, off, emit, props };
}

const submitBtn = () => screen.getByRole("button", { name: /Угадать/ });
const tap = (code: string) => fireEvent.click(screen.getByLabelText(code));

describe("GameEdge", () => {
  it("renders the game shell from server props", () => {
    renderGame();
    expect(screen.getByText("$10")).toBeInTheDocument(); // InfoDashboard prize
    expect(screen.getAllByRole("button", { name: /^00\d\d$/ })).toHaveLength(CODES.length); // keyboard keys
    expect(submitBtn()).toBeDisabled(); // nothing picked yet
  });

  it("subscribes to server events on mount and unsubscribes on unmount", () => {
    const { off, bridge, unmount } = renderGame();
    expect(bridge.onServerEvent).toHaveBeenCalledTimes(1);
    expect(off).not.toHaveBeenCalled();
    unmount();
    expect(off).toHaveBeenCalledTimes(1);
  });

  it("enables submit only after a full six-emoji code, then pushes it over the bridge", () => {
    const { bridge } = renderGame();
    CODES.slice(0, 5).forEach(tap);
    expect(submitBtn()).toBeDisabled(); // 5 of 6
    tap(CODES[5]); // 6th
    expect(submitBtn()).toBeEnabled();

    fireEvent.click(submitBtn());
    expect(bridge.pushEvent).toHaveBeenCalledTimes(1);
    expect(bridge.pushEvent).toHaveBeenCalledWith("submit_guess", { emojis: CODES.slice(0, 6) });
    expect(submitBtn()).toBeDisabled(); // picks cleared after a submit
  });

  it("caps a guess at six emojis", () => {
    const { bridge } = renderGame();
    CODES.slice(0, 7).forEach(tap); // tap seven distinct
    fireEvent.click(submitBtn());
    expect(bridge.pushEvent).toHaveBeenCalledWith("submit_guess", { emojis: CODES.slice(0, 6) });
  });

  it("disables a key once it has been used", () => {
    renderGame();
    expect(screen.getByLabelText(CODES[0])).toBeEnabled();
    tap(CODES[0]);
    expect(screen.getByLabelText(CODES[0])).toBeDisabled();
  });

  it("clears a pick when its slot is tapped, re-enabling the key", () => {
    renderGame();
    tap(CODES[0]);
    expect(screen.getByLabelText(CODES[0])).toBeDisabled();
    fireEvent.click(screen.getByLabelText("slot 1"));
    expect(screen.getByLabelText(CODES[0])).toBeEnabled();
  });

  it("does not submit while the code is incomplete", () => {
    const { bridge } = renderGame();
    CODES.slice(0, 3).forEach(tap);
    fireEvent.click(submitBtn()); // disabled → no-op
    expect(bridge.pushEvent).not.toHaveBeenCalled();
  });

  it("disables the keyboard when the round is not open", () => {
    renderGame({ view: makeView({ status: "revealing" }) });
    CODES.forEach((c) => expect(screen.getByLabelText(c)).toBeDisabled());
  });

  it("shows a loading message when there is no emoji set yet", () => {
    renderGame({ view: makeView({ emojiset: null }) });
    expect(screen.getByText("Загрузка клавиатуры…")).toBeInTheDocument();
    expect(screen.queryByLabelText(CODES[0])).not.toBeInTheDocument();
  });

  it.each([
    ["insufficient_keys", "Недостаточно ключей"],
    ["bad_guess", "Неверный код"],
    ["closed", "Игра завершена"],
    ["expired", "Игра завершена"],
    ["something_else", "Не удалось отправить"],
  ])("maps a guess_rejected reason '%s' to a toast", (reason, text) => {
    const { emit } = renderGame();
    emit("guess_rejected", { reason });
    expect(screen.getByText(text)).toBeInTheDocument();
  });

  it("toasts when the code is revealed", () => {
    const { emit } = renderGame();
    emit("revealed");
    expect(screen.getByText("Код раскрыт")).toBeInTheDocument();
  });

  it("toasts a golden win with the diamond payout", () => {
    const { emit } = renderGame();
    emit("golden_win", { diamonds: 5 });
    expect(screen.getByText("Победа! +5💎")).toBeInTheDocument();
  });

  it("dismisses a toast when it is clicked", () => {
    const { emit } = renderGame();
    emit("revealed");
    fireEvent.click(screen.getByText("Код раскрыт"));
    expect(screen.queryByText("Код раскрыт")).not.toBeInTheDocument();
  });

  it("renders only the most recent eight attempts", () => {
    const history = Array.from({ length: 10 }, (_v, i) => ({ emojis: [CODES[0]], points: i, at_ms: i }));
    renderGame({ history });
    const heading = screen.getByRole("heading", { name: "Твои попытки" });
    const list = within(heading.parentElement as HTMLElement).getByRole("list");
    expect(within(list).getAllByRole("listitem")).toHaveLength(8);
  });

  it("hides the leaderboard while a golden room is gathering", () => {
    renderGame({
      view: makeView({ status: "gathering" }),
      leaderboard: [{ player: "PLR2", name: "Ann", score: 3, is_me: false }],
    });
    expect(screen.getByText("Сбор участников…")).toBeInTheDocument();
    expect(screen.queryByText("Таблица лидеров")).not.toBeInTheDocument();
  });
});
