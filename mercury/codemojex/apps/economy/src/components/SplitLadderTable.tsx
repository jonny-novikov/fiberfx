import { useUnit } from "effector-react";
import { Card, Table } from "@mercury/ui";
import type { Column } from "@mercury/ui";
import { $ladderRows } from "../store/derived";
import { usd, dia, pct } from "../model/format";
import { Mono } from "./Mono";

interface LadderDisplay extends Record<string, unknown> {
  keys: number;
  stars: number;
  akp: number;
  poolDiamonds: number;
  poolUsd: number;
  houseUsd: number;
  housePct: number;
}

const COLS: Column<LadderDisplay>[] = [
  { key: "keys", label: "Package", render: (r) => <Mono>{r.keys} keys</Mono> },
  { key: "stars", label: "Stars", align: "right", render: (r) => <Mono>{r.stars}⭐</Mono> },
  { key: "akp", label: "akp", align: "right", render: (r) => <Mono>{usd(r.akp, 4)}</Mono> },
  { key: "pool", label: "Pool", align: "right", render: (r) => <Mono>{`${dia(r.poolDiamonds)} (${usd(r.poolUsd)})`}</Mono> },
  { key: "house", label: "House", align: "right", render: (r) => <Mono>{usd(r.houseUsd)}</Mono> },
  { key: "housePct", label: "House %", align: "right", render: (r) => <Mono>{pct(r.housePct)}</Mono> },
];

/** Per-guess split for each package rung — how the cost-per-key spread moves the pool. */
export function SplitLadderTable() {
  const rows = useUnit($ladderRows).map<LadderDisplay>((r) => ({
    keys: r.keys,
    stars: r.stars,
    akp: r.akp,
    poolDiamonds: r.split.poolDiamonds,
    poolUsd: r.split.poolUsd,
    houseUsd: r.split.houseUsd,
    housePct: r.split.housePct,
  }));
  return (
    <Card variant="raised">
      <p className="ecn-card-title">Per-guess split across the package ladder</p>
      <Table<LadderDisplay> columns={COLS} data={rows} striped getRowKey={(r) => r.keys} />
    </Card>
  );
}
