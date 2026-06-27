import { Tabs } from "@mercury/ui";
import { MetricStrip } from "./chrome/MetricStrip";
import { Sidebar } from "./chrome/Sidebar";
import { Topbar } from "./chrome/Topbar";
import { Overview } from "./views/Overview";
import { Jobs } from "./views/Jobs";
import { Groups } from "./views/Groups";
import { Batches } from "./views/Batches";
import { Processors } from "./views/Processors";
import { VIEWS, setView, useView } from "./store";
import type { View } from "./store";

function renderView(view: View) {
  switch (view) {
    case "Jobs":
      return <Jobs />;
    case "Job Groups":
      return <Groups />;
    case "Batches":
      return <Batches />;
    case "Processors":
      return <Processors />;
    case "Overview":
    default:
      return <Overview />;
  }
}

export function App() {
  const view = useView();
  return (
    <div className="eqd">
      <Sidebar />
      <main className="eqd-main">
        <Topbar />
        <div className="eqd-scroll">
          <MetricStrip />
          <div className="eqd-tabs-row">
            <Tabs<View> tabs={VIEWS.map((v) => ({ label: v, value: v }))} value={view} onChange={setView} />
          </div>
          {renderView(view)}
        </div>
      </main>
    </div>
  );
}
