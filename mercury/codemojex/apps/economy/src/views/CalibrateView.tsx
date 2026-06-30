import { KpiRow } from "../components/KpiRow";
import { SplitLadderTable } from "../components/SplitLadderTable";
import { MarginTable } from "../components/MarginTable";
import { HousePctCurve } from "../components/HousePctCurve";
import { MarginCurve } from "../components/MarginCurve";

export function CalibrateView() {
  return (
    <>
      <KpiRow />
      <SplitLadderTable />
      <MarginTable />
      <div className="ecn-grid-2">
        <HousePctCurve />
        <MarginCurve />
      </div>
    </>
  );
}
