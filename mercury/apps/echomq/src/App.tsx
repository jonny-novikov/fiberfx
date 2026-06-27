import { useState } from "react";
import type { CSSProperties } from "react";
import { Button, Card, Chip, Tag, Tabs, Table, Progress, Switch, Segmented, Icon, Avatar } from "@mercury/ui";
import type { Column } from "@mercury/ui";
import { useTheme, setTheme, toast, Toaster } from "@mercury/effector";

const COL: Record<string, string> = {
  waiting: "rgb(var(--slate-9))", active: "rgb(var(--indigo-9))", delayed: "rgb(var(--orange-9))",
  prioritized: "rgb(167 139 250)", completed: "rgb(var(--green-9))", failed: "rgb(var(--red-9))",
};
const STATS = [
  ["Waiting", "43", "waiting"], ["Active", "7", "active"], ["Delayed", "35", "delayed"],
  ["Prioritized", "81", "prioritized"], ["Completed", "51.1K", "completed"], ["Failed", "6 628", "failed"],
] as const;
const TONE: Record<string, "positive" | "info" | "negative" | "caution" | "neutral" | "discovery"> = {
  completed: "positive", active: "info", failed: "negative", delayed: "caution", waiting: "neutral", prioritized: "discovery",
};

interface Job extends Record<string, unknown> {
  id: string; name: string; status: keyof typeof TONE; attempts: string; duration: string;
}
const JOBS: Job[] = [
  { id: "#48210", name: "charge.capture", status: "completed", attempts: "1/3", duration: "412 ms" },
  { id: "#48209", name: "invoice.render", status: "active", attempts: "1/3", duration: "1.2 s" },
  { id: "#48207", name: "charge.capture", status: "failed", attempts: "3/3", duration: "2.1 min" },
  { id: "#48206", name: "fulfilment.sync", status: "delayed", attempts: "0/5", duration: "—" },
  { id: "#48204", name: "webhook.dispatch", status: "waiting", attempts: "0/3", duration: "—" },
];
const PROCS = [
  { name: "order-processing", concurrency: 24, active: 7, rate: "412/min", util: 78 },
  { name: "bulk-flows-workers", concurrency: 64, active: 31, rate: "1.2K/min", util: 91 },
  { name: "cdn-upload", concurrency: 8, active: 1, rate: "44/min", util: 18 },
  { name: "campaign-runner", concurrency: 16, active: 0, rate: "0/min", util: 0 },
];

export function App() {
  const theme = useTheme();
  const [tab, setTab] = useState<"overview" | "jobs" | "processors">("overview");
  const [running, setRunning] = useState(true);
  const [procOn, setProcOn] = useState([true, true, true, false]);

  const jobCols: Column<Job>[] = [
    { key: "id", label: "Job ID", render: (r) => <span style={{ fontFamily: "var(--font-secondary)", fontSize: 13 }}>{r.id}</span> },
    { key: "name", label: "Name", render: (r) => <span style={{ fontFamily: "var(--font-secondary)", fontSize: 13, color: "rgb(var(--fg-primary))" }}>{r.name}</span> },
    { key: "status", label: "Status", render: (r) => <Tag tone={TONE[r.status]}>{r.status}</Tag> },
    { key: "attempts", label: "Attempts" },
    { key: "duration", label: "Duration", align: "right" },
  ];

  const toggleRunning = (v: "paused" | "running") => {
    setRunning(v === "running");
    if (v === "running") toast.success("Queue resumed");
    else toast.warning("Queue paused");
  };

  return (
    <div style={{ display: "grid", gridTemplateColumns: "240px 1fr", height: "100vh", background: "rgb(var(--bg-primary))", color: "rgb(var(--fg-primary))", fontFamily: "var(--font-primary)" }}>
      <aside style={{ background: "rgb(var(--bg-secondary))", borderRight: "1px solid rgb(var(--border-secondary))", padding: 16, display: "flex", flexDirection: "column", gap: 14 }}>
        <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
          <span style={{ width: 32, height: 32, borderRadius: 8, background: "rgb(var(--bg-brand-subtle))", color: "rgb(var(--fg-brand))", display: "inline-flex", alignItems: "center", justifyContent: "center" }}>
            <Icon name="bolt" size={18} />
          </span>
          <strong style={{ letterSpacing: "-0.01em" }}>EchoMQ</strong>
          <Chip variant="brand" size="sm">Bus</Chip>
        </div>
        <div style={{ font: "700 10px/1 var(--font-primary)", letterSpacing: "0.12em", textTransform: "uppercase", color: "rgb(var(--fg-tertiary))" }}>Queues</div>
        {["order-processing", "bulk-flows", "cdn-upload", "campaign-runner"].map((q, i) => (
          <button key={q} style={{ display: "flex", justifyContent: "space-between", border: 0, background: i === 0 ? "rgb(var(--bg-selected))" : "transparent", borderRadius: 8, padding: "8px 10px", cursor: "pointer", color: i === 0 ? "rgb(var(--fg-primary))" : "rgb(var(--fg-secondary))", font: "500 13px/1 var(--font-primary)" }}>
            {q}
          </button>
        ))}
      </aside>

      <main style={{ display: "flex", flexDirection: "column", overflow: "hidden" }}>
        <header style={{ display: "flex", alignItems: "center", gap: 14, padding: "16px 28px", borderBottom: "1px solid rgb(var(--border-secondary))" }}>
          <div>
            <h2 style={{ margin: 0, font: "700 22px/1.1 var(--font-primary)", letterSpacing: "-0.01em" }}>order-processing</h2>
            <p style={{ margin: "3px 0 0", font: "400 12px/1 var(--font-primary)", color: "rgb(var(--fg-tertiary))" }}>EchoMQ Bus v8.4.0 · admin</p>
          </div>
          <div style={{ flex: 1 }} />
          <Segmented<"paused" | "running"> segments={[{ label: "Paused", value: "paused" }, { label: "Running", value: "running" }]} value={running ? "running" : "paused"} onChange={toggleRunning} size="sm" />
          <Segmented<"light" | "dark"> segments={[{ label: "Light", value: "light" }, { label: "Dark", value: "dark" }]} value={theme} onChange={setTheme} size="sm" />
        </header>

        <div style={{ flex: 1, overflowY: "auto", padding: "22px 28px 60px", display: "flex", flexDirection: "column", gap: 20 }}>
          <Tabs<"overview" | "jobs" | "processors">
            tabs={[{ label: "Overview", value: "overview" }, { label: "Jobs", value: "jobs" }, { label: "Processors", value: "processors" }]}
            value={tab}
            onChange={setTab}
          />

          {tab === "overview" && (
            <>
              <div style={{ display: "grid", gridTemplateColumns: "repeat(6, 1fr)", gap: 14 }}>
                {STATS.map(([label, value, key]) => (
                  <Card key={label} style={statCard}>
                    <span style={{ font: "700 11px/1 var(--font-primary)", letterSpacing: "0.08em", textTransform: "uppercase", color: "rgb(var(--fg-tertiary))" }}>{label}</span>
                    <span style={{ font: "700 28px/1 var(--font-secondary)", letterSpacing: "-0.02em", color: COL[key] }}>{value}</span>
                  </Card>
                ))}
              </div>
              <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 18 }}>
                {(["Currently Queued", "Processed"] as const).map((title, idx) => (
                  <Card key={title} style={{ padding: 22 }}>
                    <h6 style={panelH}>{title}</h6>
                    <div style={{ display: "flex", flexDirection: "column", gap: 12, marginTop: 14 }}>
                      {(idx === 0
                        ? [["Waiting", 43, "waiting"], ["Active", 7, "active"], ["Delayed", 35, "delayed"], ["Prioritized", 81, "prioritized"]]
                        : [["Completed", 88, "completed"], ["Failed", 12, "failed"]]
                      ).map(([l, v, k]) => (
                        <div key={l as string}>
                          <div style={{ display: "flex", justifyContent: "space-between", font: "500 12px/1 var(--font-secondary)", color: "rgb(var(--fg-secondary))", marginBottom: 6 }}>
                            <span>{l}</span><span>{v}{idx === 1 ? "%" : ""}</span>
                          </div>
                          <div style={{ height: 6, borderRadius: 999, background: "rgb(var(--bg-tertiary))", overflow: "hidden" }}>
                            <div style={{ height: "100%", width: `${idx === 1 ? (v as number) : Math.min(100, (v as number))}%`, background: COL[k as string], borderRadius: 999 }} />
                          </div>
                        </div>
                      ))}
                    </div>
                  </Card>
                ))}
              </div>
            </>
          )}

          {tab === "jobs" && (
            <Card style={{ padding: 22 }}>
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "baseline", marginBottom: 14 }}>
                <h6 style={panelH}>Recent jobs</h6>
                <span style={{ font: "400 12px/1 var(--font-primary)", color: "rgb(var(--fg-tertiary))" }}>5 of 2,431</span>
              </div>
              <Table columns={jobCols} data={JOBS} striped getRowKey={(r) => r.id} />
            </Card>
          )}

          {tab === "processors" && (
            <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 16 }}>
              {PROCS.map((p, i) => (
                <Card key={p.name} style={{ padding: 22 }}>
                  <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 18 }}>
                    <strong style={{ font: "600 15px/1.2 var(--font-primary)" }}>{p.name}</strong>
                    <Switch
                      checked={procOn[i] ?? false}
                      label={procOn[i] ? "Running" : "Paused"}
                      onChange={(v) => {
                        setProcOn((s) => s.map((x, j) => (j === i ? v : x)));
                        toast.info(`${p.name} ${v ? "resumed" : "paused"}`);
                      }}
                    />
                  </div>
                  <div style={{ display: "flex", gap: 28, marginBottom: 16 }}>
                    <Stat label="Concurrency" value={String(p.concurrency)} />
                    <Stat label="Active" value={String(p.active)} color="rgb(var(--indigo-9))" />
                    <Stat label="Rate" value={p.rate} />
                  </div>
                  <div style={{ display: "flex", justifyContent: "space-between", font: "500 12px/1 var(--font-secondary)", color: "rgb(var(--fg-secondary))", marginBottom: 8 }}>
                    <span>Utilisation</span><span>{p.util}%</span>
                  </div>
                  <Progress value={p.util} variant={p.util > 85 ? "caution" : "brand"} />
                </Card>
              ))}
            </div>
          )}

          <div style={{ display: "flex", gap: 10 }}>
            <Button variant="secondary" leading={<Icon name="refresh" size={14} />} onClick={() => toast.info("Refreshed")}>Refresh</Button>
            <Button variant="ghost" leading={<Icon name="download" size={14} />} onClick={() => toast.success("Export started")}>Export</Button>
            <span style={{ flex: 1 }} />
            <span style={{ display: "inline-flex", alignItems: "center", gap: 8 }}><Avatar name="Sam Reyes" size={28} status="positive" /><span style={{ font: "500 13px/1 var(--font-primary)", color: "rgb(var(--fg-secondary))" }}>Sam Reyes</span></span>
          </div>
        </div>
      </main>

      <Toaster position="bottom-end" />
    </div>
  );
}

function Stat({ label, value, color }: { label: string; value: string; color?: string }) {
  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 6 }}>
      <span style={{ font: "700 10px/1 var(--font-primary)", letterSpacing: "0.08em", textTransform: "uppercase", color: "rgb(var(--fg-tertiary))" }}>{label}</span>
      <b style={{ font: "700 20px/1 var(--font-secondary)", color: color ?? "rgb(var(--fg-primary))" }}>{value}</b>
    </div>
  );
}

const statCard: CSSProperties = { padding: "16px 18px", display: "flex", flexDirection: "column", gap: 10 };
const panelH: CSSProperties = { margin: 0, font: "700 12px/1 var(--font-primary)", letterSpacing: "0.08em", textTransform: "uppercase", color: "rgb(var(--fg-secondary))" };
