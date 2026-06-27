import { Card, Progress, Switch } from "@mercury/ui";
import { PROC_DATA } from "../data";
import { toggleProc, useProcRunning } from "../store";

export function Processors() {
  const running = useProcRunning();
  return (
    <div className="eqd-procgrid">
      {PROC_DATA.map((p, i) => (
        <Card key={p.name} className="eqd-proc" padding="20px 22px">
          <div className="eqd-proc__top">
            <div className="eqd-row__name">{p.name}</div>
            <Switch checked={running[i]} onChange={() => toggleProc(i)} label={running[i] ? "Running" : "Paused"} />
          </div>
          <div className="eqd-proc__stats">
            <div>
              <span>Concurrency</span>
              <b>{p.concurrency}</b>
            </div>
            <div>
              <span>Active</span>
              <b style={{ color: "rgb(var(--indigo-9))" }}>{p.active}</b>
            </div>
            <div>
              <span>Rate</span>
              <b>{p.rate}</b>
            </div>
          </div>
          <div className="eqd-progtop">
            <span>Utilisation</span>
            <span>{p.util}%</span>
          </div>
          <Progress value={p.util} variant={p.tone} />
        </Card>
      ))}
    </div>
  );
}
