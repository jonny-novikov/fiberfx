import { useState } from "react";
import {
  Button, Icon, Input, Textarea, Search, Select,
  Checkbox, Radio, Switch, Segmented, Slider,
  Chip, Tag, Badge, Avatar, Card, Alert, Progress, Tabs, Modal, Tooltip, Table,
} from "@mercury/ui";
import type { Column } from "@mercury/ui";
import { useTheme, setTheme, toast, Toaster, createForm } from "@mercury/effector";

/* Effector-backed sign-in form (model lives outside React) */
const signIn = createForm({
  initialValues: { email: "", password: "" },
  validate: (v) => {
    const e: { email?: string; password?: string } = {};
    if (!v.email) e.email = "Email is required";
    else if (!/.+@.+\..+/.test(v.email)) e.email = "Enter a valid email";
    if (v.password.length < 8) e.password = "Use at least 8 characters";
    return e;
  },
});

const SECTIONS = ["Buttons", "Inputs", "Selection", "Data", "Feedback", "Overlays", "Table"] as const;
type Section = (typeof SECTIONS)[number];

interface ServiceRow extends Record<string, unknown> {
  name: string;
  env: string;
  status: "positive" | "caution" | "negative";
  latency: string;
}

export function App() {
  const theme = useTheme();
  const [section, setSection] = useState<Section>("Buttons");
  const [sw, setSw] = useState(true);
  const [cb, setCb] = useState(true);
  const [radio, setRadio] = useState("week");
  const [seg, setSeg] = useState<"day" | "week" | "month">("week");
  const [slider, setSlider] = useState(64);
  const [search, setSearch] = useState("");
  const [tab, setTab] = useState<"overview" | "activity" | "settings">("overview");
  const [modal, setModal] = useState(false);

  const cols: Column<ServiceRow>[] = [
    { key: "name", label: "Service", render: (r) => <strong style={{ fontFamily: "var(--font-secondary)" }}>{r.name}</strong> },
    { key: "env", label: "Env", render: (r) => <Chip size="sm">{r.env}</Chip> },
    { key: "status", label: "Status", render: (r) => <Tag tone={r.status}>{r.status === "positive" ? "Healthy" : r.status === "caution" ? "Degraded" : "Down"}</Tag> },
    { key: "latency", label: "p95", align: "right" },
  ];
  const rows: ServiceRow[] = [
    { name: "acme-production", env: "prod", status: "positive", latency: "112 ms" },
    { name: "acme-staging", env: "stage", status: "caution", latency: "204 ms" },
    { name: "acme-sandbox", env: "dev", status: "negative", latency: "—" },
  ];

  return (
    <div style={{ display: "grid", gridTemplateColumns: "240px 1fr", height: "100vh", background: "rgb(var(--bg-primary))", color: "rgb(var(--fg-primary))", fontFamily: "var(--font-primary)" }}>
      <aside style={{ background: "rgb(var(--bg-secondary))", borderRight: "1px solid rgb(var(--border-secondary))", padding: "20px 12px", overflowY: "auto" }}>
        <div style={{ display: "flex", alignItems: "center", gap: 10, padding: "0 8px 18px" }}>
          <span style={{ width: 30, height: 30, borderRadius: 8, background: "rgb(var(--bg-brand-subtle))", color: "rgb(var(--fg-brand))", display: "inline-flex", alignItems: "center", justifyContent: "center" }}>
            <Icon name="bolt" size={17} />
          </span>
          <strong style={{ letterSpacing: "-0.01em" }}>mercury/ui</strong>
        </div>
        {SECTIONS.map((s) => (
          <button
            key={s}
            onClick={() => setSection(s)}
            style={{
              display: "block", width: "100%", textAlign: "left", border: 0, cursor: "pointer",
              padding: "8px 12px", borderRadius: 8, marginBottom: 2,
              font: "500 14px/1 var(--font-primary)",
              background: section === s ? "rgb(var(--bg-brand-subtle))" : "transparent",
              color: section === s ? "rgb(var(--fg-brand))" : "rgb(var(--fg-secondary))",
              fontWeight: section === s ? 600 : 500,
            }}
          >
            {s}
          </button>
        ))}
      </aside>

      <main style={{ overflowY: "auto" }}>
        <header style={{ display: "flex", alignItems: "center", gap: 16, padding: "16px 32px", borderBottom: "1px solid rgb(var(--border-secondary))" }}>
          <h2 style={{ margin: 0, font: "700 20px/1 var(--font-primary)", letterSpacing: "-0.01em" }}>{section}</h2>
          <div style={{ flex: 1 }} />
          <Segmented<"light" | "dark">
            segments={[{ label: "Light", value: "light" }, { label: "Dark", value: "dark" }]}
            value={theme}
            onChange={setTheme}
            size="sm"
          />
        </header>

        <div style={{ padding: 32, display: "flex", flexDirection: "column", gap: 24, maxWidth: 920 }}>
          {section === "Buttons" && (
            <Card>
              <div style={{ display: "flex", flexWrap: "wrap", gap: 12, marginBottom: 16 }}>
                <Button>Primary</Button>
                <Button variant="secondary">Secondary</Button>
                <Button variant="outline">Outline</Button>
                <Button variant="ghost">Ghost</Button>
                <Button variant="destructive">Delete</Button>
                <Button variant="inverse">Inverse</Button>
              </div>
              <div style={{ display: "flex", flexWrap: "wrap", gap: 12 }}>
                <Button size="sm">Small</Button>
                <Button size="lg" leading={<Icon name="download" size={14} />}>Download</Button>
                <Button loading>Saving…</Button>
                <Button disabled>Disabled</Button>
              </div>
            </Card>
          )}

          {section === "Inputs" && (
            <>
              <Card style={{ maxWidth: 420, display: "flex", flexDirection: "column", gap: 14 }}>
                <SignInDemo />
              </Card>
              <Card style={{ display: "flex", flexDirection: "column", gap: 14, maxWidth: 420 }}>
                <Search value={search} onChange={setSearch} onSearch={(v) => toast.info(`Searching “${v}”`)} placeholder="Search services" />
                <Select label="Mode" options={[{ label: "Standalone", value: "standalone" }, { label: "Cluster", value: "cluster" }]} defaultValue="standalone" />
                <Textarea label="Notes" maxLength={160} defaultValue="" hint="Visible to your team." rows={3} />
              </Card>
            </>
          )}

          {section === "Selection" && (
            <Card style={{ display: "flex", flexDirection: "column", gap: 20 }}>
              <div style={{ display: "flex", gap: 24, flexWrap: "wrap" }}>
                <Switch checked={sw} onChange={setSw} label="Auto-refresh" />
                <Checkbox checked={cb} onChange={setCb} label="Group children" />
              </div>
              <div style={{ display: "flex", gap: 24, flexWrap: "wrap" }}>
                {["waiting", "week", "failed"].map((v) => (
                  <Radio key={v} value={v} checked={radio === v} onChange={setRadio} label={v} name="demo" />
                ))}
              </div>
              <Segmented<"day" | "week" | "month">
                segments={[{ label: "Day", value: "day" }, { label: "Week", value: "week" }, { label: "Month", value: "month" }]}
                value={seg}
                onChange={setSeg}
              />
              <Slider label="Concurrency" value={slider} onChange={setSlider} max={128} unit=" workers" />
            </Card>
          )}

          {section === "Data" && (
            <Card style={{ display: "flex", flexDirection: "column", gap: 18 }}>
              <div style={{ display: "flex", gap: 10, flexWrap: "wrap" }}>
                <Chip variant="brand">Pro</Chip>
                <Tag tone="positive">Live</Tag>
                <Tag tone="caution">Pending</Tag>
                <Tag tone="negative">Blocked</Tag>
                <Chip onRemove={() => toast.info("Removed")}>removable</Chip>
              </div>
              <div style={{ display: "flex", gap: 12, alignItems: "center" }}>
                <Badge variant="brand">New</Badge>
                <Badge variant="negative">3</Badge>
                <Avatar name="Grace Hopper" status="positive" />
                <Avatar name="Ada Lovelace" size={48} />
                <Avatar name="Alan Turing" size={32} />
              </div>
            </Card>
          )}

          {section === "Feedback" && (
            <Card style={{ display: "flex", flexDirection: "column", gap: 14 }}>
              <div style={{ display: "flex", gap: 10, flexWrap: "wrap" }}>
                <Button variant="secondary" onClick={() => toast.success("Job retried")}>Success toast</Button>
                <Button variant="secondary" onClick={() => toast.error("Connection lost")}>Error toast</Button>
                <Button variant="secondary" onClick={() => toast.warning("Approaching limit")}>Warning toast</Button>
              </div>
              <Alert tone="info" title="Heads up">A new Mercury version is available.</Alert>
              <Alert tone="success" title="Payment received">Your invoice has been paid.</Alert>
              <Progress value={64} />
              <Progress value={88} variant="positive" size="lg" />
              <Progress indeterminate variant="info" />
            </Card>
          )}

          {section === "Overlays" && (
            <Card style={{ display: "flex", gap: 12, alignItems: "center" }}>
              <Button onClick={() => setModal(true)}>Open modal</Button>
              <Tooltip content="Copy link to clipboard">
                <Button variant="secondary">Hover me</Button>
              </Tooltip>
              <Tabs<"overview" | "activity" | "settings">
                tabs={[{ label: "Overview", value: "overview" }, { label: "Activity", value: "activity" }, { label: "Settings", value: "settings" }]}
                value={tab}
                onChange={setTab}
                variant="pills"
              />
              <Modal
                open={modal}
                onClose={() => setModal(false)}
                title="Invite teammates"
                footer={<>
                  <Button variant="secondary" onClick={() => setModal(false)}>Cancel</Button>
                  <Button onClick={() => { setModal(false); toast.success("Invite sent"); }}>Send invite</Button>
                </>}
              >
                <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
                  <p style={{ margin: 0 }}>Add people to your workspace.</p>
                  <Input label="Emails" placeholder="ada@example.com" />
                </div>
              </Modal>
            </Card>
          )}

          {section === "Table" && <Table columns={cols} data={rows} striped getRowKey={(r) => r.name} />}
        </div>
      </main>

      <Toaster position="bottom-end" />
    </div>
  );
}

function SignInDemo() {
  const email = signIn.useField("email");
  const password = signIn.useField("password");
  const form = signIn.useForm();
  return (
    <>
      <h3 style={{ margin: "0 0 4px", font: "700 18px/1.2 var(--font-primary)" }}>Sign in</h3>
      <Input
        label="Email"
        type="email"
        placeholder="you@company.com"
        value={email.value}
        error={email.error}
        onChange={(e) => email.onChange(e.target.value)}
        onBlur={email.onBlur}
      />
      <Input
        label="Password"
        type="password"
        placeholder="••••••••"
        value={password.value}
        error={password.error}
        onChange={(e) => password.onChange(e.target.value)}
        onBlur={password.onBlur}
      />
      <Button
        fullWidth
        size="lg"
        onClick={() => {
          form.submit();
          if (form.isValid) toast.success("Signed in");
          else toast.error("Check the highlighted fields");
        }}
      >
        Sign in
      </Button>
    </>
  );
}
