import { Avatar, Button, Card, Chip, Progress, Segmented, Table, Tag } from "@mercury/ui";
import type { Column } from "@mercury/ui";
import { useState } from "react";
import { Page, PageHead } from "../../chrome/Page";

interface Initiative extends Record<string, unknown> {
  name: string;
  owner: string;
  status: "positive" | "caution" | "info";
  progress: number;
  due: string;
}

const metrics: { label: string; value: string; delta: string; variant: "positive" | "negative" }[] = [
  { label: "MRR", value: "$142,310", delta: "+12.4%", variant: "positive" },
  { label: "Active users", value: "8,291", delta: "+3.2%", variant: "positive" },
  { label: "Churn", value: "1.8%", delta: "-0.4pt", variant: "positive" },
  { label: "Avg. latency", value: "112 ms", delta: "+18 ms", variant: "negative" },
];

const rows: Initiative[] = [
  { name: "Onboarding revamp", owner: "Grace Hopper", status: "positive", progress: 92, due: "Apr 24" },
  { name: "Pricing v3", owner: "Ada Lovelace", status: "caution", progress: 58, due: "May 02" },
  { name: "API rate limit tier", owner: "Alan Turing", status: "info", progress: 34, due: "May 14" },
  { name: "Mobile deep-links", owner: "Katherine Johnson", status: "positive", progress: 76, due: "Apr 28" },
];

const statusLabel: Record<Initiative["status"], string> = {
  positive: "On track",
  caution: "At risk",
  info: "Planned",
};

const cols: Column<Initiative>[] = [
  {
    key: "name",
    label: "Initiative",
    render: (r) => <strong style={{ font: "600 13px/1.4 var(--font-primary)" }}>{r.name}</strong>,
  },
  {
    key: "owner",
    label: "Owner",
    render: (r) => (
      <span style={{ display: "inline-flex", alignItems: "center", gap: 8 }}>
        <Avatar name={r.owner} size={22} />
        {r.owner}
      </span>
    ),
  },
  {
    key: "status",
    label: "Status",
    render: (r) => <Tag tone={r.status}>{statusLabel[r.status]}</Tag>,
  },
  {
    key: "progress",
    label: "Progress",
    render: (r) => (
      <div style={{ display: "flex", alignItems: "center", gap: 10, minWidth: 160 }}>
        <div style={{ flex: 1 }}>
          <Progress size="sm" value={r.progress} variant={r.status === "caution" ? "caution" : "brand"} />
        </div>
        <span
          style={{
            font: "500 12px/1 var(--font-secondary)",
            color: "rgb(var(--fg-secondary))",
            width: 32,
            textAlign: "right",
          }}
        >
          {r.progress}%
        </span>
      </div>
    ),
  },
  {
    key: "due",
    label: "Due",
    align: "right",
    render: (r) => (
      <span style={{ font: "500 13px/1 var(--font-secondary)", color: "rgb(var(--fg-secondary))" }}>{r.due}</span>
    ),
  },
];

export function DashboardPage() {
  const [range, setRange] = useState("30d");

  return (
    <Page>
      <PageHead
        eyebrow="Patterns"
        title="Dashboard"
        lede="Metrics, status chips, progress bars and a live table composed together."
      />

      <div style={{ display: "flex", alignItems: "center", gap: 12, marginBottom: 24 }}>
        <Segmented<string>
          segments={[
            { label: "7 days", value: "7d" },
            { label: "30 days", value: "30d" },
            { label: "90 days", value: "90d" },
          ]}
          value={range}
          onChange={setRange}
        />
        <div style={{ flex: 1 }} />
        <Button variant="secondary">Export</Button>
        <Button>New initiative</Button>
      </div>

      <div style={{ display: "grid", gridTemplateColumns: "repeat(4,1fr)", gap: 12, marginBottom: 24 }}>
        {metrics.map((m) => (
          <Card key={m.label} padding={18}>
            <div style={{ font: "500 12px/1 var(--font-primary)", color: "rgb(var(--fg-secondary))", marginBottom: 10 }}>
              {m.label}
            </div>
            <div style={{ font: "700 24px/1 var(--font-primary)", letterSpacing: "-0.02em" }}>{m.value}</div>
            <div style={{ marginTop: 8 }}>
              <Chip size="sm" variant={m.variant}>
                {m.delta}
              </Chip>
            </div>
          </Card>
        ))}
      </div>

      <Table columns={cols} data={rows} striped getRowKey={(r) => r.name} />
    </Page>
  );
}
