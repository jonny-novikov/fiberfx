import { Card } from "@mercury/ui";
import { ReceiveIcon, SendIcon } from "../icons";
import type { ActRow } from "../data";

/** The recent-activity feed — Mercury Card shell, app-specific rows inside. */
export function ActivityList({ rows }: { rows: ActRow[] }) {
  return (
    <Card padding={0} style={{ overflow: "hidden" }}>
      {rows.map((r, i) => (
        <div className="em-actrow" key={`${r.title}-${i}`}>
          <div className="em-actrow-ic">{r.positive ? <ReceiveIcon size={18} /> : <SendIcon size={18} />}</div>
          <div className="em-actrow-body">
            <div className="em-actrow-t">{r.title}</div>
            <div className="em-actrow-m">{r.meta}</div>
          </div>
          <div className={`em-actrow-amt ${r.positive ? "is-pos" : "is-neg"}`}>{r.amount}</div>
        </div>
      ))}
    </Card>
  );
}
