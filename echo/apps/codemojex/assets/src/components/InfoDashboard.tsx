import { useEffect, useState } from "react";
import type { GameView } from "@/types";

// The header strip: prize (USD), live player/attempt totals, and a countdown from
// ends_ms (absent while a Golden Room is still gathering).
export function InfoDashboard(props: { view: GameView }) {
  const { view } = props;
  const remaining = useCountdown(view.ends_ms);
  return (
    <header className="info">
      <div className="info__prize">
        <span className="info__label">Банк</span>
        <span className="info__value">${view.prize_usd}</span>
      </div>
      <div className="info__stat">
        <span className="info__label">Игроки</span>
        <span className="info__value">{view.totals?.players ?? 0}</span>
      </div>
      <div className="info__stat">
        <span className="info__label">Попытки</span>
        <span className="info__value">{view.totals?.attempts ?? 0}</span>
      </div>
      <div className="info__timer">{view.status === "gathering" ? gather(view) : remaining}</div>
    </header>
  );
}

function gather(view: GameView) {
  const g = view.gather;
  if (!g) return "Сбор";
  return g.threshold ? `Сбор ${g.paid}/${g.threshold}` : `Сбор ${g.paid}`;
}

function useCountdown(endsMs: number | null) {
  const [now, setNow] = useState(() => Date.now());
  useEffect(() => {
    if (!endsMs) return;
    const id = setInterval(() => setNow(Date.now()), 1000);
    return () => clearInterval(id);
  }, [endsMs]);
  if (!endsMs) return "—";
  const ms = Math.max(0, endsMs - now);
  const h = Math.floor(ms / 3_600_000);
  const m = Math.floor((ms % 3_600_000) / 60_000);
  const s = Math.floor((ms % 60_000) / 1000);
  return `${h}:${String(m).padStart(2, "0")}:${String(s).padStart(2, "0")}`;
}
