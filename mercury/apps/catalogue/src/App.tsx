import { useState } from "react";
import type { CSSProperties } from "react";
import { Button, Chip, Tag, Badge, Avatar, Alert, Progress, Tabs, Card, Segmented, Icon } from "@mercury/ui";
import { useTheme, setTheme } from "@mercury/effector";

type Page = "colors" | "type" | "components";
const RAMPS = ["slate", "iris", "indigo"] as const;
const STATUS = [
  ["Brand", "--iris-9"], ["Active", "--indigo-9"], ["Positive", "--green-9"],
  ["Negative", "--red-9"], ["Caution", "--orange-9"], ["Discovery", "--plum-9"],
] as const;
const TYPE: Array<{ name: string; style: CSSProperties; sample: string }> = [
  { name: "Display · DM Serif", style: { font: "400 48px/1 var(--font-display)", letterSpacing: "-0.02em" }, sample: "Design with intent." },
  { name: "Heading · Mono 32", style: { font: "700 32px/1 var(--font-secondary)", letterSpacing: "-0.01em" }, sample: "Queues, jobs & batches" },
  { name: "H3 · Sans 20", style: { font: "600 20px/1.3 var(--font-primary)" }, sample: "Components should feel inevitable." },
  { name: "Body · Sans 16", style: { font: "400 16px/1.6 var(--font-primary)" }, sample: "Body copy carries the longest weight of reading." },
  { name: "Mono · 14", style: { font: "400 14px/1.6 var(--font-secondary)" }, sample: "const token = 'iris-9';" },
];

export function App() {
  const theme = useTheme();
  const [page, setPage] = useState<Page>("colors");
  const [tab, setTab] = useState<"underline" | "pills">("underline");

  return (
    <div style={{ display: "grid", gridTemplateColumns: "248px 1fr", height: "100vh", background: "rgb(var(--bg-primary))", color: "rgb(var(--fg-primary))", fontFamily: "var(--font-primary)" }}>
      <aside style={{ background: "rgb(var(--bg-secondary))", borderRight: "1px solid rgb(var(--border-secondary))", padding: "20px 12px" }}>
        <div style={{ display: "flex", alignItems: "center", gap: 10, padding: "0 8px 18px" }}>
          <span style={{ width: 30, height: 30, borderRadius: 8, background: "rgb(var(--bg-brand-subtle))", color: "rgb(var(--fg-brand))", display: "inline-flex", alignItems: "center", justifyContent: "center" }}>
            <Icon name="bolt" size={17} />
          </span>
          <div>
            <strong style={{ display: "block", letterSpacing: "-0.01em" }}>Mercury</strong>
            <span style={{ font: "500 10px/1 var(--font-secondary)", letterSpacing: "0.12em", textTransform: "uppercase", color: "rgb(var(--fg-tertiary))" }}>Catalogue</span>
          </div>
        </div>
        {(["colors", "type", "components"] as Page[]).map((p) => (
          <button key={p} onClick={() => setPage(p)} style={navStyle(page === p)}>
            {p === "colors" ? "Colors" : p === "type" ? "Typography" : "Components"}
          </button>
        ))}
      </aside>

      <main style={{ overflowY: "auto" }}>
        <header style={{ display: "flex", alignItems: "center", gap: 16, padding: "16px 32px", borderBottom: "1px solid rgb(var(--border-secondary))" }}>
          <h2 style={{ margin: 0, font: "700 20px/1 var(--font-primary)", letterSpacing: "-0.01em" }}>
            {page === "colors" ? "Colors" : page === "type" ? "Typography" : "Components"}
          </h2>
          <div style={{ flex: 1 }} />
          <Segmented<"light" | "dark"> segments={[{ label: "Light", value: "light" }, { label: "Dark", value: "dark" }]} value={theme} onChange={setTheme} size="sm" />
        </header>

        <div style={{ padding: 32, maxWidth: 960, display: "flex", flexDirection: "column", gap: 24 }}>
          {page === "colors" && (
            <>
              {RAMPS.map((r) => (
                <div key={r}>
                  <div style={{ font: "600 13px/1 var(--font-primary)", color: "rgb(var(--fg-secondary))", marginBottom: 8, textTransform: "capitalize" }}>{r}</div>
                  <div style={{ display: "grid", gridTemplateColumns: "repeat(12, 1fr)", gap: 6 }}>
                    {Array.from({ length: 12 }, (_, i) => i + 1).map((n) => (
                      <div key={n} title={`--${r}-${n}`} style={{ height: 46, borderRadius: 6, background: `rgb(var(--${r}-${n}))`, display: "flex", alignItems: "flex-end", justifyContent: "center", paddingBottom: 4, boxShadow: "inset 0 0 0 1px rgb(var(--border-secondary) / .5)" }}>
                        <span style={{ font: "600 9px/1 var(--font-secondary)", color: `rgb(var(--${n >= 9 ? "slate-1" : "slate-12"}))` }}>{n}</span>
                      </div>
                    ))}
                  </div>
                </div>
              ))}
              <div>
                <div style={{ font: "700 10px/1 var(--font-primary)", letterSpacing: "0.1em", textTransform: "uppercase", color: "rgb(var(--fg-tertiary))", marginBottom: 12 }}>Solid status</div>
                <div style={{ display: "flex", gap: 16, flexWrap: "wrap" }}>
                  {STATUS.map(([label, v]) => (
                    <div key={label} style={{ display: "flex", alignItems: "center", gap: 10 }}>
                      <span style={{ width: 30, height: 30, borderRadius: 8, background: `rgb(var(${v}))` }} />
                      <b style={{ font: "500 13px/1.2 var(--font-primary)" }}>{label}</b>
                    </div>
                  ))}
                </div>
              </div>
            </>
          )}

          {page === "type" && TYPE.map((t) => (
            <div key={t.name} style={{ padding: "18px 0", borderBottom: "1px solid rgb(var(--border-secondary))" }}>
              <div style={{ font: "500 12px/1 var(--font-secondary)", color: "rgb(var(--fg-tertiary))", marginBottom: 10, letterSpacing: "0.06em", textTransform: "uppercase" }}>{t.name}</div>
              <div style={t.style}>{t.sample}</div>
            </div>
          ))}

          {page === "components" && (
            <>
              <Card style={{ display: "flex", gap: 12, flexWrap: "wrap" }}>
                <Button>Primary</Button>
                <Button variant="secondary">Secondary</Button>
                <Button variant="outline">Outline</Button>
                <Button variant="destructive">Delete</Button>
              </Card>
              <Card style={{ display: "flex", gap: 10, flexWrap: "wrap", alignItems: "center" }}>
                <Chip variant="brand">Pro</Chip>
                <Tag tone="positive">Live</Tag>
                <Tag tone="caution">Pending</Tag>
                <Badge variant="brand">New</Badge>
                <Avatar name="Grace Hopper" status="positive" />
              </Card>
              <Card style={{ display: "flex", flexDirection: "column", gap: 14 }}>
                <Alert tone="success" title="Payment received">Your invoice has been paid.</Alert>
                <Progress value={72} variant="positive" />
                <Tabs<"underline" | "pills">
                  tabs={[{ label: "Underline", value: "underline" }, { label: "Pills", value: "pills" }]}
                  value={tab}
                  onChange={setTab}
                  variant={tab}
                />
              </Card>
            </>
          )}
        </div>
      </main>
    </div>
  );
}

function navStyle(active: boolean): CSSProperties {
  return {
    display: "block", width: "100%", textAlign: "left", border: 0, cursor: "pointer",
    padding: "8px 12px", borderRadius: 8, marginBottom: 2, font: "500 14px/1 var(--font-primary)",
    background: active ? "rgb(var(--bg-brand-subtle))" : "transparent",
    color: active ? "rgb(var(--fg-brand))" : "rgb(var(--fg-secondary))",
    fontWeight: active ? 600 : 500,
  };
}
