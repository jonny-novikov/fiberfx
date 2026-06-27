import { Table, Tag, Chip, Avatar } from "@mercury/ui";
import type { Column } from "@mercury/ui";
import { Page, PageHead, Section } from "../../chrome/Page";

interface ServiceRow extends Record<string, unknown> {
  name: string;
  env: string;
  status: "positive" | "caution" | "negative" | "info";
  latency: string;
  traffic: string;
  owner: string;
}

const STATUS_LABEL: Record<ServiceRow["status"], string> = {
  positive: "Healthy",
  caution: "Degraded",
  negative: "Down",
  info: "Preview",
};

function statusLabel(status: ServiceRow["status"]): string {
  return STATUS_LABEL[status];
}

const rows: ServiceRow[] = [
  { name: "acme-production", env: "prod", status: "positive", latency: "112 ms", traffic: "12.4k", owner: "Grace Hopper" },
  { name: "acme-staging", env: "stage", status: "caution", latency: "204 ms", traffic: "840", owner: "Ada Lovelace" },
  { name: "acme-preview", env: "preview", status: "info", latency: "98 ms", traffic: "212", owner: "Alan Turing" },
  { name: "acme-marketing", env: "prod", status: "positive", latency: "76 ms", traffic: "8.1k", owner: "Katherine Johnson" },
  { name: "acme-sandbox", env: "dev", status: "negative", latency: "—", traffic: "0", owner: "Linus Torvalds" },
];

const cols: Column<ServiceRow>[] = [
  {
    key: "name",
    label: "Service",
    render: (r) => <strong style={{ fontFamily: "var(--font-secondary)" }}>{r.name}</strong>,
  },
  {
    key: "env",
    label: "Env",
    render: (r) => (
      <Chip variant="neutral" size="sm">
        {r.env}
      </Chip>
    ),
  },
  {
    key: "status",
    label: "Status",
    render: (r) => <Tag tone={r.status}>{statusLabel(r.status)}</Tag>,
  },
  { key: "latency", label: "p95 Latency", align: "right" },
  { key: "traffic", label: "Traffic", align: "right" },
  {
    key: "owner",
    label: "Owner",
    render: (r) => (
      <span style={{ display: "inline-flex", alignItems: "center", gap: 8 }}>
        <Avatar name={r.owner} size={22} />
        <span style={{ color: "rgb(var(--fg-secondary))" }}>{r.owner}</span>
      </span>
    ),
  },
];

export function TablePage() {
  return (
    <Page>
      <PageHead
        eyebrow="Components"
        title="Table"
        lede="Structured data with custom cell renderers, status chips and right-aligned numerics."
      />

      <Section title="Services table" />
      <Table columns={cols} data={rows} striped getRowKey={(r) => r.name} />
    </Page>
  );
}
