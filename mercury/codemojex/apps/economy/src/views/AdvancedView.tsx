import { RailPanel } from "../components/RailPanel";
import { BalanceSimPanel } from "../components/BalanceSimPanel";

export function AdvancedView() {
  return (
    <div className="ecn-grid-2">
      <RailPanel />
      <BalanceSimPanel />
    </div>
  );
}
