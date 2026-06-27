import { Card, Segmented } from "@mercury/ui";
import { Donut } from "../charts/Donut";
import { ThroughputChart } from "../charts/ThroughputChart";
import { PROCESSED_ARCS, PROCESSED_TOTAL, QUEUED_ARCS, QUEUED_TOTAL, STATS } from "../data";
import { setRange, useRange } from "../store";
import type { Range } from "../store";

const RANGES: { label: string; value: Range }[] = [
  { label: "1 min", value: "1m" },
  { label: "5 min", value: "5m" },
  { label: "15 min", value: "15m" },
  { label: "30 min", value: "30m" },
  { label: "1 hour", value: "1h" },
];

const TIMINGS: { title: string; rows: [string, string, string][] }[] = [
  {
    title: "Response Time — Time in Queue",
    rows: [
      ["Min", "322 ms", "--green-9"],
      ["Median", "2.4 sec", "--indigo-9"],
      ["Max", "2.1 min", "--orange-9"],
    ],
  },
  {
    title: "Process Time — Time in Workers",
    rows: [
      ["Min", "137 ms", "--green-9"],
      ["Median", "626 ms", "--indigo-9"],
      ["Max", "3.6 sec", "--orange-9"],
    ],
  },
];

export function Overview() {
  const range = useRange();
  return (
    <>
      <div className="eqd-statgrid">
        {STATS.map((s) => (
          <Card key={s.label} className="eqd-stat" padding="16px 18px">
            <span className="l">{s.label}</span>
            <span className="v" style={{ color: s.color }}>
              {s.value}
            </span>
          </Card>
        ))}
      </div>

      <div className="eqd-grid2">
        <Card className="eqd-panel" padding="20px 22px">
          <h6 className="eqd-panelh" style={{ marginBottom: 14 }}>
            Currently Queued
          </h6>
          <div className="eqd-donutwrap">
            <Donut arcs={QUEUED_ARCS} num={QUEUED_TOTAL} cap="queued" />
            <ul className="eqd-legend">
              {QUEUED_ARCS.map((a) => (
                <li key={a.label}>
                  <span className="eqd-dot" style={{ background: a.color }} />
                  {a.label}
                  <b>{a.value}</b>
                </li>
              ))}
            </ul>
          </div>
        </Card>
        <Card className="eqd-panel" padding="20px 22px">
          <h6 className="eqd-panelh" style={{ marginBottom: 14 }}>
            Processed
          </h6>
          <div className="eqd-donutwrap">
            <Donut arcs={PROCESSED_ARCS} num={PROCESSED_TOTAL} cap="total" />
            <ul className="eqd-legend">
              {PROCESSED_ARCS.map((a) => (
                <li key={a.label}>
                  <span className="eqd-dot" style={{ background: a.color }} />
                  {a.label}
                  <b>{a.pct}</b>
                </li>
              ))}
            </ul>
          </div>
        </Card>
      </div>

      <Card className="eqd-panel" padding="20px 22px">
        <div className="eqd-panelbar">
          <h6 className="eqd-panelh">Job Throughput</h6>
          <Segmented<Range> segments={RANGES} value={range} onChange={setRange} size="sm" />
        </div>
        <div className="eqd-legend eqd-legend--inline">
          <span>
            <span className="eqd-dot" style={{ background: "rgb(var(--green-9))" }} />
            Completed
          </span>
          <span>
            <span className="eqd-dot" style={{ background: "rgb(var(--red-9))" }} />
            Failed
          </span>
        </div>
        <ThroughputChart />
      </Card>

      <div className="eqd-grid2" style={{ marginBottom: 0 }}>
        {TIMINGS.map((t) => (
          <Card key={t.title} className="eqd-panel" padding="20px 22px" style={{ marginBottom: 0 }}>
            <h6 className="eqd-panelh">{t.title}</h6>
            <div className="eqd-timing">
              {t.rows.map(([k, v, col]) => (
                <div key={k}>
                  <span>{k}</span>
                  <b style={{ color: `rgb(var(${col}))` }}>{v}</b>
                </div>
              ))}
            </div>
          </Card>
        ))}
      </div>
    </>
  );
}
