import { COMPLETED_AREA, COMPLETED_PATH, FAILED_PATH, GRID_LINES, X_TICKS, Y_TICKS } from "../data";

/* Job-throughput line chart: completed (filled) + failed lines over a grid. */
export function ThroughputChart() {
  return (
    <div className="eqd-chart">
      <svg viewBox="0 0 1000 300" preserveAspectRatio="none" className="eqd-chart__svg">
        {GRID_LINES.map((y) => (
          <line key={y} x1="0" x2="1000" y1={y} y2={y} className="eqd-chart__grid" />
        ))}
        <path d={COMPLETED_AREA} fill="url(#eqdgrad)" stroke="none" />
        <path d={COMPLETED_PATH} fill="none" stroke="rgb(var(--green-9))" strokeWidth="2.5" />
        <path d={FAILED_PATH} fill="none" stroke="rgb(var(--red-9))" strokeWidth="2.5" />
        <defs>
          <linearGradient id="eqdgrad" x1="0" x2="0" y1="0" y2="1">
            <stop offset="0%" stopColor="rgb(var(--green-9))" stopOpacity="0.28" />
            <stop offset="100%" stopColor="rgb(var(--green-9))" stopOpacity="0" />
          </linearGradient>
        </defs>
      </svg>
      <div className="eqd-chart__yaxis">
        {Y_TICKS.map((t) => (
          <span key={t}>{t}</span>
        ))}
      </div>
      <div className="eqd-chart__xaxis">
        {X_TICKS.map((t) => (
          <span key={t}>{t}</span>
        ))}
      </div>
    </div>
  );
}
