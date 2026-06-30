import { useState } from "react";
import { Card, Table, Segmented } from "@mercury/ui";
import type { Column } from "@mercury/ui";
import { RAILS } from "../model/packages";
import type { RailId } from "../model/packages";
import { usd } from "../model/format";
import { Mono } from "./Mono";

interface RailDisplay extends Record<string, unknown> {
  id: RailId;
  label: string;
  minor: string;
  factor: string;
  usdPerUnit: number;
}

const COLS: Column<RailDisplay>[] = [
  { key: "label", label: "Rail", render: (r) => <strong>{r.label}</strong> },
  { key: "minor", label: "Minor unit", render: (r) => <Mono>{r.minor}</Mono> },
  { key: "factor", label: "Factor", align: "right", render: (r) => <Mono>{r.factor}</Mono> },
  { key: "usdPerUnit", label: "USD / unit", align: "right", render: (r) => <Mono>{usd(r.usdPerUnit, 4)}</Mono> },
];

/** The four pay-in rails normalized to one canonical USD basis (the F3 fold). */
export function RailPanel() {
  const [rail, setRail] = useState<RailId>("stars");
  const rows = RAILS.map<RailDisplay>((r) => ({
    id: r.id,
    label: r.label,
    minor: r.minor,
    factor: r.factor.toLocaleString("en-US"),
    usdPerUnit: r.usdPerUnit,
  }));
  const sel = RAILS.find((r) => r.id === rail) ?? RAILS[0]!;
  return (
    <Card variant="raised">
      <p className="ecn-card-title">Pay-in rails → canonical USD</p>
      <Table<RailDisplay> columns={COLS} data={rows} striped getRowKey={(r) => r.id} />
      <div style={{ marginTop: "var(--space-12)", display: "flex", flexDirection: "column", gap: "var(--space-8)" }}>
        <Segmented<RailId> value={rail} onChange={setRail} fullWidth size="sm" segments={RAILS.map((r) => ({ label: r.label, value: r.id }))} />
        <p className="ecn-mono" style={{ margin: 0, color: "rgb(var(--fg-secondary))", fontSize: 13 }}>
          1 {sel.label} ≈ {usd(sel.usdPerUnit, 4)} canonical USD{sel.id === "ton" ? " · 200⭐ = 1 TON (Telegram-pinned)" : ""}
        </p>
      </div>
    </Card>
  );
}
