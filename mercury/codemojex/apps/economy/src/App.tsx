import { useState } from "react";
import { Tabs } from "@mercury/ui";
import { CalibrationForm } from "./components/CalibrationForm";
import { CalibrateView } from "./views/CalibrateView";
import { PrizePoolView } from "./views/PrizePoolView";
import { AdvancedView } from "./views/AdvancedView";

type View = "calibrate" | "pool" | "advanced";

const TABS: { label: string; value: View }[] = [
  { label: "Calibrate", value: "calibrate" },
  { label: "Prize Pool", value: "pool" },
  { label: "Advanced", value: "advanced" },
];

export function App() {
  const [view, setView] = useState<View>("calibrate");
  return (
    <div className="ecn">
      <header className="ecn-head">
        <span className="ecn-head__brand">Codemojex · Economy</span>
        <span className="ecn-head__sub">Revenue-model calibration console</span>
      </header>
      <div className="ecn-body">
        <aside className="ecn-rail">
          <CalibrationForm />
        </aside>
        <main className="ecn-main">
          <Tabs<View> tabs={TABS} value={view} onChange={setView} variant="pills" />
          {view === "calibrate" && <CalibrateView />}
          {view === "pool" && <PrizePoolView />}
          {view === "advanced" && <AdvancedView />}
        </main>
      </div>
    </div>
  );
}
