import type { Meta, StoryObj } from "@storybook/react-vite";
import { Table, Tag, Chip, Avatar } from "@mercury/ui";
import type { Column } from "@mercury/ui";

// Table is a data-prop component: a render-based story carries realistic sample
// data shaped to TableProps<Row>, grounded in real call sites (cited). Controls
// restate Table.prompt.md — `striped` (boolean); `columns`/`data`/`getRowKey`
// are structured data props, not raw controls.

// ── Sample 1: the showcase services table (Chip/Tag/Avatar cell renderers) ──
// showcase/src/pages/components/TablePage.tsx
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

const serviceRows: ServiceRow[] = [
  { name: "acme-production", env: "prod", status: "positive", latency: "112 ms", traffic: "12.4k", owner: "Grace Hopper" },
  { name: "acme-staging", env: "stage", status: "caution", latency: "204 ms", traffic: "840", owner: "Ada Lovelace" },
  { name: "acme-preview", env: "preview", status: "info", latency: "98 ms", traffic: "212", owner: "Alan Turing" },
  { name: "acme-marketing", env: "prod", status: "positive", latency: "76 ms", traffic: "8.1k", owner: "Katherine Johnson" },
  { name: "acme-sandbox", env: "dev", status: "negative", latency: "—", traffic: "0", owner: "Linus Torvalds" },
];

const serviceCols: Column<ServiceRow>[] = [
  { key: "name", label: "Service", render: (r) => <strong style={{ fontFamily: "var(--font-secondary)" }}>{r.name}</strong> },
  {
    key: "env",
    label: "Env",
    render: (r) => (
      <Chip variant="neutral" size="sm">
        {r.env}
      </Chip>
    ),
  },
  { key: "status", label: "Status", render: (r) => <Tag tone={r.status}>{STATUS_LABEL[r.status]}</Tag> },
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

const meta: Meta<typeof Table<ServiceRow>> = {
  title: "Data Display/Table",
  component: Table,
  argTypes: {
    striped: { control: "boolean" },
    columns: { control: false },
    data: { control: false },
    getRowKey: { control: false },
  },
  args: {
    columns: serviceCols,
    data: serviceRows,
    striped: true,
    getRowKey: (r) => r.name,
  },
};
export default meta;

type Story = StoryObj<typeof Table<ServiceRow>>;

export const Playground: Story = {};

// ── Sample 2: the economy prize-pool metrics table (right-aligned values) ──
// codemojex-node/apps/economy/src/components/PrizePoolTable.tsx
interface MetricRow extends Record<string, unknown> {
  metric: string;
  value: string;
}

const metricCols: Column<MetricRow>[] = [
  { key: "metric", label: "Metric", render: (r) => r.metric },
  { key: "value", label: "Value", align: "right", render: (r) => <span style={{ fontFamily: "var(--font-mono)" }}>{r.value}</span> },
];

const metricRows: MetricRow[] = [
  { metric: "Total guesses (N × G)", value: "1,200" },
  { metric: "Gross consumed", value: "$240.00" },
  { metric: "Spend / player", value: "60 keys ($2.00)" },
  { metric: "Winner takes", value: "$96.00 · 960💎 · 48 keys" },
];

export const PrizePool: Story = {
  render: () => <Table<MetricRow> columns={metricCols} data={metricRows} striped getRowKey={(r) => r.metric} />,
};
