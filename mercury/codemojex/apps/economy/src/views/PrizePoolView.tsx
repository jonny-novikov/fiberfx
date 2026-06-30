import { PrizePoolTable } from "../components/PrizePoolTable";
import { PoolGrowthCurve } from "../components/PoolGrowthCurve";
import { RevenueFlow } from "../components/RevenueFlow";
import { ConservationBadge } from "../components/ConservationBadge";

export function PrizePoolView() {
  return (
    <>
      <PrizePoolTable />
      <div className="ecn-grid-2">
        <PoolGrowthCurve />
        <RevenueFlow />
      </div>
      <ConservationBadge />
    </>
  );
}
