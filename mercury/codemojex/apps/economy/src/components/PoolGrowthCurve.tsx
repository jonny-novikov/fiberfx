import { useUnit } from "effector-react";
import { Card, Chart } from "@mercury/ui";
import { $poolGrowthCurve } from "../store/derived";

/** Prize-pool diamonds accumulated as the room's guesses land (linear in total guesses). */
export function PoolGrowthCurve() {
  const g = useUnit($poolGrowthCurve);
  return (
    <Card variant="raised">
      <p className="ecn-card-title">Prize-pool growth vs total guesses</p>
      <Chart viewBox={g.viewBox} series={g.series} gridY={g.gridY} yTicks={g.yTicks} xTicks={g.xTicks} gradients={g.gradients} ariaLabel={g.ariaLabel} />
    </Card>
  );
}
