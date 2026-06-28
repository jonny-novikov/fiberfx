import { useUnit } from "effector-react";
import { Card, Chart } from "@mercury/ui";
import { $marginCurve } from "../store/derived";

/** Margin vs pool portion for both channels; the dashed line is the zero-loss boundary. */
export function MarginCurve() {
  const g = useUnit($marginCurve);
  return (
    <Card variant="raised">
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "baseline", gap: "var(--space-12)" }}>
        <p className="ecn-card-title" style={{ margin: 0 }}>Margin vs pool portion</p>
        <span style={{ fontSize: 12, fontFamily: "var(--font-secondary)" }}>
          <span style={{ color: "rgb(var(--green-9))" }}>● desktop</span>
          {"  "}
          <span style={{ color: "rgb(var(--orange-9))" }}>● mobile</span>
        </span>
      </div>
      <div style={{ marginTop: "var(--space-8)" }}>
        <Chart
          viewBox={g.viewBox}
          series={g.series}
          gridY={g.gridY}
          yTicks={g.yTicks}
          xTicks={g.xTicks}
          markers={g.zeroY != null ? [{ y: g.zeroY }] : []}
          ariaLabel={g.ariaLabel}
        />
      </div>
    </Card>
  );
}
