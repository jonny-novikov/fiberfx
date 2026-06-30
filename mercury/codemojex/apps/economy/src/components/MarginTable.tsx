import { useUnit } from "effector-react";
import { Card, Table, Alert } from "@mercury/ui";
import type { Column } from "@mercury/ui";
import { $marginRows } from "../store/derived";
import { usd, pct, signedUsd, signedPct } from "../model/format";
import { Mono } from "./Mono";

interface MarginDisplay extends Record<string, unknown> {
  channel: string;
  storeFee: number;
  netReceived: number;
  poolOwed: number;
  margin: number;
  squeezePct: number;
  negative: boolean;
}

const toned = (negative: boolean, text: string) => (
  <Mono>
    <span style={{ color: negative ? "rgb(var(--fg-negative))" : "rgb(var(--fg-positive))" }}>{text}</span>
  </Mono>
);

const COLS: Column<MarginDisplay>[] = [
  { key: "channel", label: "Channel", render: (r) => <span style={{ textTransform: "capitalize" }}>{r.channel}</span> },
  { key: "storeFee", label: "Store fee", align: "right", render: (r) => <Mono>{pct(r.storeFee, 0)}</Mono> },
  { key: "netReceived", label: "Net received", align: "right", render: (r) => <Mono>{usd(r.netReceived)}</Mono> },
  { key: "poolOwed", label: "Pool owed", align: "right", render: (r) => <Mono>{usd(r.poolOwed)}</Mono> },
  { key: "margin", label: "Margin", align: "right", render: (r) => toned(r.negative, signedUsd(r.margin)) },
  { key: "squeezePct", label: "Squeeze", align: "right", render: (r) => toned(r.negative, signedPct(r.squeezePct)) },
];

/** Mobile vs desktop margin against the same pool — the central calibration finding. */
export function MarginTable() {
  const margins = useUnit($marginRows);
  const rows = margins.map<MarginDisplay>((r) => ({
    channel: r.channel,
    storeFee: r.storeFee,
    netReceived: r.netReceived,
    poolOwed: r.poolOwed,
    margin: r.margin,
    squeezePct: r.squeezePct,
    negative: r.negative,
  }));
  const anyNeg = margins.some((r) => r.negative);
  const mob = margins.find((r) => r.channel === "mobile");
  const desk = margins.find((r) => r.channel === "desktop");
  return (
    <Card variant="raised">
      <p className="ecn-card-title">Store-fee margin squeeze</p>
      <Table<MarginDisplay> columns={COLS} data={rows} striped getRowKey={(r) => r.channel} />
      <div style={{ marginTop: "var(--space-12)" }}>
        <Alert tone={anyNeg ? "danger" : "warning"} title={anyNeg ? "Pool liability exceeds net revenue" : "Store-fee margin squeeze"}>
          {anyNeg
            ? `The pool owed (${mob ? usd(mob.poolOwed) : ""}) outruns net revenue on at least one channel — the platform loses money per guess there. Lower the pool portion, or switch the split basis to net akp.`
            : `Mobile keeps ${mob ? signedPct(mob.squeezePct) : ""} of each guess vs desktop ${desk ? signedPct(desk.squeezePct) : ""} — the ~${mob ? pct(mob.storeFee, 0) : ""} mobile store cut is the binding constraint on margin.`}
        </Alert>
      </div>
    </Card>
  );
}
