import type { LeaderRow } from "../types";

export function Leaderboard(props: { rows: LeaderRow[]; me: string; hidden?: boolean }) {
  const { rows, hidden } = props;
  if (hidden) return <div className="leaderboard leaderboard--hidden">Сбор участников…</div>;
  return (
    <div className="leaderboard">
      <h3 className="leaderboard__title">Таблица лидеров</h3>
      <ol className="leaderboard__list">
        {rows.map((r, i) => (
          <li key={r.player} className="leaderboard__row" data-me={r.is_me ? "1" : "0"}>
            <span className="leaderboard__rank">{i + 1}</span>
            <span className="leaderboard__name">{r.name}</span>
            <span className="leaderboard__score">{r.score}</span>
          </li>
        ))}
      </ol>
    </div>
  );
}
