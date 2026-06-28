import { useUnit } from "effector-react";
import { Card, Chart } from "@mercury/ui";
import { $housePctCurve } from "../store/derived";

/** House share of each guess as the average key price rises (integer-floor staircase is faithful). */
export function HousePctCurve() {
  const g = useUnit($housePctCurve);
  return (
    <Card variant="raised">
      <p className="ecn-card-title">House % of each guess vs avg key price</p>
      <Chart viewBox={g.viewBox} series={g.series} gridY={g.gridY} yTicks={g.yTicks} xTicks={g.xTicks} gradients={g.gradients} ariaLabel={g.ariaLabel} />
    </Card>
  );
}
