import type { ReactNode } from "react";
import { useUnit } from "effector-react";
import { Card, Table, Stat } from "@mercury/ui";
import type { Column } from "@mercury/ui";
import { $prizePool } from "../store/derived";
import { usd, dia, keys } from "../model/format";
import { Mono } from "./Mono";

interface MetricRow extends Record<string, unknown> {
  metric: string;
  value: ReactNode;
}

const COLS: Column<MetricRow>[] = [
  { key: "metric", label: "Metric", render: (r) => r.metric },
  { key: "value", label: "Value", align: "right", render: (r) => r.value },
];

/** N×G prize-pool estimation + per-player economics. */
export function PrizePoolTable() {
  const pp = useUnit($prizePool);
  const rows: MetricRow[] = [
    { metric: "Total guesses (N × G)", value: <Mono>{pp.totalGuesses}</Mono> },
    { metric: "Gross consumed", value: <Mono>{usd(pp.grossConsumed)}</Mono> },
    { metric: "Spend / player", value: <Mono>{`${keys(pp.spendPerPlayerKeys)} (${usd(pp.spendPerPlayerUsd)})`}</Mono> },
    { metric: "Winner takes", value: <Mono>{`${usd(pp.winnerTakesUsd)} · ${dia(pp.poolDiamonds)} · ${pp.winnerTakesKeysInGame} keys`}</Mono> },
  ];
  return (
    <Card variant="raised">
      <p className="ecn-card-title">
        Prize pool — {pp.players} players × {pp.guessesEach} guesses
      </p>
      <div className="ecn-kpis" style={{ marginBottom: "var(--space-16)" }}>
        <Stat label="Prize pool" value={usd(pp.poolUsd)} hint={dia(pp.poolDiamonds)} />
        <Stat label="House revenue" value={usd(pp.houseUsd)} deltaTone="brand" />
        <Stat label="Winner takes" value={`${pp.winnerTakesKeysInGame} keys`} hint={usd(pp.winnerTakesUsd)} />
      </div>
      <Table<MetricRow> columns={COLS} data={rows} striped getRowKey={(r) => r.metric} />
    </Card>
  );
}
