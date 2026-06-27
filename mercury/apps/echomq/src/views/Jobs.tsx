import { Button, Card, Table, Tag } from "@mercury/ui";
import type { Column } from "@mercury/ui";
import { JOB_ROWS, TONE } from "../data";
import type { JobRow } from "../data";
import { useSelected } from "../store";

const COLS: Column<JobRow>[] = [
  { key: "id", label: "Job ID", render: (j) => <span className="eqd-mono">{j.id}</span> },
  {
    key: "name",
    label: "Name",
    render: (j) => (
      <span className="eqd-mono" style={{ color: "rgb(var(--fg-primary))", fontWeight: 500 }}>
        {j.name}
      </span>
    ),
  },
  { key: "status", label: "Status", render: (j) => <Tag tone={TONE[j.status]}>{j.status}</Tag> },
  { key: "attempts", label: "Attempts" },
  { key: "duration", label: "Duration", align: "right" },
  { key: "age", label: "Added", align: "right" },
];

export function Jobs() {
  const selected = useSelected();
  return (
    <Card className="eqd-panel" padding="20px 22px">
      <div className="eqd-panelbar">
        <h6 className="eqd-panelh">Recent Jobs · {selected}</h6>
        <span className="eqd-muted">8 of 2,431 jobs</span>
      </div>
      <Table columns={COLS} data={JOB_ROWS} striped getRowKey={(j) => j.id} />
      <div style={{ display: "flex", justifyContent: "flex-end", gap: 6, marginTop: 16 }}>
        <Button variant="secondary" size="sm">
          ‹ Prev
        </Button>
        <Button size="sm">1</Button>
        <Button variant="secondary" size="sm">
          2
        </Button>
        <Button variant="secondary" size="sm">
          3
        </Button>
        <Button variant="secondary" size="sm">
          Next ›
        </Button>
      </div>
    </Card>
  );
}
