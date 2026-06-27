import { Card, Icon, Progress, Tag, cx } from "@mercury/ui";
import type { IconName } from "@mercury/ui";
import { TONE } from "../data";
import type { FlowRow } from "../data";

/* The job-group / batch row: lead icon + name/meta, a progress bar, status. */
export function FlowRowCard({ row, icon }: { row: FlowRow; icon: IconName }) {
  return (
    <Card className="eqd-row" padding="18px 22px">
      <div className="eqd-row__lead">
        <span className="eqd-flowicon">
          <Icon name={icon} size={20} />
        </span>
        <div>
          <div className={cx("eqd-row__name", row.mono && "eqd-mono")}>{row.name}</div>
          <div className="eqd-row__meta">{row.meta}</div>
        </div>
      </div>
      <div className="eqd-row__prog">
        <div className="eqd-progtop">
          <span>
            {row.done} / {row.total}
          </span>
          <span>{row.pct}%</span>
        </div>
        <Progress value={row.pct} variant={row.tone} />
      </div>
      <Tag tone={TONE[row.status]}>{row.status}</Tag>
    </Card>
  );
}
