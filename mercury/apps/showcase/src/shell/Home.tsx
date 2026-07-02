import { Badge, Button, Card } from "@mercury/ui";

const SWATCHES = ["--bg-brand", "--bg-brand-subtle", "--fg-on-brand", "--indigo-3"] as const;

// The mx.9.1 sanity content, relocated (the no-selection panel). The @mercury/ui
// value import keeps the barrel — and with it the stylesheet — in the graph.
export function Home() {
  return (
    <section className="showcase-home">
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
            className="showcase-home-swatch"
            style={{ background: `rgb(var(${token}))` }}
          >
            <code>{token}</code>
          </div>
        ))}
      </section>
    </section>
  );
}
