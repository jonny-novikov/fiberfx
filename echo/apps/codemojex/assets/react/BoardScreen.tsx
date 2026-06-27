import { useEffect, useMemo, useState } from "react";
import type { BoardProps, Bridge, Code } from "./types";
import { EmojiSlots } from "./components/EmojiSlots";
import { EmojiKeyboard } from "./components/EmojiKeyboard";
import { GuessActions } from "./components/GuessActions";
import { Leaderboard } from "./components/Leaderboard";
import { InfoDashboard } from "./components/InfoDashboard";

const CODE_LEN = 6;

// The board island. Server props are authoritative (view/leaderboard/history);
// the only client-owned state is the in-flight picks. Submit, lock, and unlock go
// out over bridge.pushEvent; scored updates arrive as fresh props (the host calls
// update()), and one-off events (reject/reveal/win) via bridge.onServerEvent.
export function BoardScreen(props: BoardProps & { bridge: Bridge }) {
  const { view, leaderboard, history, me, bridge } = props;
  const [picks, setPicks] = useState<Code[]>([]);
  const [toast, setToast] = useState<string | null>(null);

  const used = useMemo(() => new Set(picks), [picks]);

  useEffect(() => {
    const off = bridge.onServerEvent((name, payload) => {
      if (name === "guess_rejected") setToast(rejectText(payload?.reason));
      if (name === "revealed") setToast("Код раскрыт");
      if (name === "golden_win") setToast(`Победа! +${payload?.diamonds ?? ""}💎`);
    });
    return off;
  }, [bridge]);

  const tap = (code: Code) => {
    if (picks.length >= CODE_LEN || used.has(code)) return;
    setPicks((p) => [...p, code]);
  };
  const clearAt = (i: number) => setPicks((p) => p.filter((_c, idx) => idx !== i));
  const submit = () => {
    if (picks.length !== CODE_LEN) return;
    bridge.pushEvent("submit_guess", { emojis: picks });
    setPicks([]);
  };

  const set = view.emojiset;
  const ready = picks.length === CODE_LEN && view.status === "open";

  return (
    <div className="board">
      <InfoDashboard view={view} />
      {toast && (
        <div className="board__toast" onClick={() => setToast(null)}>
          {toast}
        </div>
      )}

      <EmojiSlots picks={picks} set={set} onClear={clearAt} length={CODE_LEN} />
      <GuessActions ready={ready} fee={view.guess_fee} free={view.free} onSubmit={submit} />

      {set ? (
        <EmojiKeyboard set={set} used={used} onTap={tap} disabled={view.status !== "open"} />
      ) : (
        <div className="board__empty">Загрузка клавиатуры…</div>
      )}

      <Leaderboard rows={leaderboard} me={me} hidden={view.status === "gathering"} />

      {history.length > 0 && (
        <div className="board__history">
          <h3>Твои попытки</h3>
          <ul>
            {history.slice(0, 8).map((h, i) => (
              <li key={i}>
                {h.emojis.join(" ")} {typeof h.points === "number" ? `· ${h.points}` : ""}
              </li>
            ))}
          </ul>
        </div>
      )}
    </div>
  );
}

function rejectText(reason?: string) {
  switch (reason) {
    case "insufficient_keys":
      return "Недостаточно ключей";
    case "bad_guess":
      return "Неверный код";
    case "closed":
    case "expired":
      return "Игра завершена";
    default:
      return "Не удалось отправить";
  }
}
