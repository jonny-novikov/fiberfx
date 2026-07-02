import { Badge, Button, Card } from "@mercury/ui";

const SWATCHES = ["--bg-brand", "--bg-brand-subtle", "--fg-on-brand", "--indigo-3"] as const;

export function App() {
  return (
    <main style={{ padding: 24, maxWidth: 720, margin: "0 auto" }}>
      <h1>@mercury/showcase — the spine</h1>
      <p>
        Source-resolved via the workspace alias; the stylesheet arrives through the barrel. The registry,
        shell, stories, and docs surfaces land at mx.9.2–9.5.
      </p>
      <Card>
        <Button>Primary action</Button> <Badge>alias-live</Badge>
      </Card>
      <section aria-label="token swatches">
        {SWATCHES.map((token) => (
          <div
            key={token}
            style={{ background: `rgb(var(${token}))`, padding: 8, marginTop: 8 }}
          >
            <code>{token}</code>
          </div>
        ))}
      </section>
    </main>
  );
}
