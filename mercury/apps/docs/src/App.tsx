import { useEffect, useState } from "react";
import { Button, Chip, Tag, Switch, Input, Alert, Card, Segmented, Badge, Progress, Icon } from "@mercury/ui";
import { useTheme, setTheme, toast, Toaster, createForm } from "@mercury/effector";

const NAV = [
  { group: "Getting started", items: [["introduction", "Introduction"], ["install", "Installation"], ["quickstart", "Quickstart"]] },
  { group: "Foundations", items: [["tokens", "Design tokens"], ["color", "Color"], ["typography", "Typography"], ["spacing", "Spacing & radius"]] },
  { group: "Components", items: [["components", "Overview"]] },
  { group: "Usage", items: [["effector", "Effector"], ["accessibility", "Accessibility"], ["changelog", "Changelog"]] },
] as const;
const TOC = NAV.flatMap((g) => g.items.map(([id, label]) => ({ id, label })));
const COUNTS: Record<string, string> = { tokens: "84", components: "22" };

const settings = createForm({
  initialValues: { replyTo: "team@acme.co", digest: true, updates: false },
  validate: (v) => (!/.+@.+\..+/.test(v.replyTo) ? { replyTo: "Enter a valid email" } : {}),
});

export function App() {
  const theme = useTheme();
  const [active, setActive] = useState("introduction");
  const [installTab, setInstallTab] = useState<"pnpm" | "npm" | "yarn">("pnpm");

  useEffect(() => {
    const ids = TOC.map((t) => t.id);
    const onScroll = () => {
      let cur = ids[0]!;
      for (const id of ids) {
        const el = document.getElementById(id);
        if (el && el.getBoundingClientRect().top - 90 <= 1) cur = id;
      }
      setActive(cur);
    };
    onScroll();
    window.addEventListener("scroll", onScroll, { passive: true });
    return () => window.removeEventListener("scroll", onScroll);
  }, []);

  const installCmd = { pnpm: "pnpm add @mercury/ui @mercury/effector", npm: "npm i @mercury/ui @mercury/effector", yarn: "yarn add @mercury/ui @mercury/effector" }[installTab];

  return (
    <>
      <nav className="dx-nav">
        <a className="dx-brand" href="../site/index.html"><img src="../../site/assets/mercury-logo.png" alt="" />mercury</a>
        <div className="dx-nav-links">
          <a href="../site/index.html">Home</a>
          <a className="is-active" href="#introduction">Docs</a>
          <a href="../showcase/index.html">Showcase</a>
          <a href="../catalogue/index.html">Catalogue</a>
        </div>
        <div style={{ marginLeft: "auto", display: "flex", gap: 10, alignItems: "center" }}>
          <Segmented<"light" | "dark"> size="sm" value={theme} onChange={setTheme} segments={[{ label: "Light", value: "light" }, { label: "Dark", value: "dark" }]} />
          <Button size="sm" variant="secondary" leading={<Icon name="download" size={14} />} onClick={() => toast.success("Copied install command")}>Install</Button>
        </div>
      </nav>

      <div className="dx-crumb"><a href="../site/index.html">Home</a><span>/</span>Documentation<span>/</span>Getting started</div>

      <header className="dx-hero">
        <div>
          <div className="eyebrow">Documentation · v2.4</div>
          <h1>Everything you need to <em>ship.</em></h1>
          <p>Install the package, pull in tokens, drop components on the canvas. Foundations, components and usage live next to each other — so your next feature takes hours, not sprints.</p>
        </div>
        <div className="dx-hero-meta">
          <div><strong>22+</strong>Components</div>
          <div><strong>84</strong>Color tokens</div>
          <div><strong>3</strong>Families</div>
        </div>
      </header>

      <div className="dx-shell">
        <aside className="dx-sidebar">
          {NAV.map((g) => (
            <div className="dx-sgroup" key={g.group}>
              <h6>{g.group}</h6>
              {g.items.map(([id, label]) => (
                <a key={id} href={`#${id}`} className={active === id ? "is-active" : ""}>
                  {label}
                  {COUNTS[id] && <span className="count">{COUNTS[id]}</span>}
                </a>
              ))}
            </div>
          ))}
        </aside>

        <main className="dx-main">
          <section id="introduction">
            <div className="dx-eyebrow">Introduction</div>
            <h2>A UI kit that <em>stays out of the way.</em></h2>
            <p>Mercury ships framework-agnostic CSS primitives, a React component library, and an Effector adapter that all speak the same token vocabulary. Install one package and get consistent typography, color, spacing, focus rings and motion across every surface.</p>
            <p>It's designed to be <strong>boring in the right places</strong>. Defaults are opinionated so you rarely need overrides; tokens are exposed when you do.</p>
            <div className="dx-tiles">
              <div className="dx-tile"><div className="n">01</div><h4>Tokens</h4><p>84 color tokens plus type, space, radius, shadow — as CSS variables.</p></div>
              <div className="dx-tile"><div className="n">02</div><h4>Components</h4><p>22+ presentational React components with full TypeScript types.</p></div>
              <div className="dx-tile"><div className="n">03</div><h4>Effector</h4><p>Theme, toasts and forms as pluggable stores — components stay dumb.</p></div>
            </div>
          </section>

          <section id="install">
            <div className="dx-eyebrow">Installation</div>
            <h2>Install in one line.</h2>
            <p>Distributed as <code>@mercury/ui</code> (components + token CSS) and <code>@mercury/effector</code> (state). Peers: React 18+ and Effector 23+.</p>
            <Segmented<"pnpm" | "npm" | "yarn"> value={installTab} onChange={setInstallTab} size="sm" segments={[{ label: "pnpm", value: "pnpm" }, { label: "npm", value: "npm" }, { label: "yarn", value: "yarn" }]} />
            <div className="dx-code"><span className="tag">Terminal</span><pre>{installCmd}</pre></div>
            <h3>Import the stylesheet</h3>
            <p>The library entry imports its CSS; or pull it in explicitly once at your app root:</p>
            <div className="dx-code"><span className="tag">main.tsx</span><pre>{`import "@mercury/ui/styles.css";   // tokens + components
import { initTheme } from "@mercury/effector";

initTheme(); // syncs <html> theme class + persists`}</pre></div>
          </section>

          <section id="quickstart">
            <div className="dx-eyebrow">Quickstart</div>
            <h2>Your first screen.</h2>
            <p>A settings card from the primitives you'll use most — <code>Card</code>, <code>Input</code>, <code>Switch</code>, <code>Button</code> — backed by an Effector <code>createForm</code> model.</p>
            <div className="dx-demo">
              <SettingsDemo />
            </div>
            <div className="dx-code"><span className="tag">TSX</span><pre>{`const form = createForm({
  initialValues: { replyTo: "", digest: true },
  validate: (v) => (!v.replyTo ? { replyTo: "Required" } : {}),
});

function Settings() {
  const replyTo = form.useField("replyTo");
  const digest = form.useField("digest");
  return (
    <Card>
      <Input label="Reply-to" value={replyTo.value} error={replyTo.error}
        onChange={(e) => replyTo.onChange(e.target.value)} />
      <Switch checked={digest.value} onChange={digest.onChange} label="Weekly digest" />
      <Button onClick={() => toast.success("Saved")}>Save changes</Button>
    </Card>
  );
}`}</pre></div>
          </section>

          <section id="tokens">
            <div className="dx-eyebrow">Foundations</div>
            <h2>Design tokens.</h2>
            <p>Tokens are the single source of truth. Every component reads from them — rebranding means editing token values, not 22 components.</p>
            <table className="dx-table">
              <thead><tr><th>Namespace</th><th>Prefix</th><th>Example</th></tr></thead>
              <tbody>
                <tr><td><strong>Color</strong></td><td><code>--bg-* --fg-*</code></td><td className="desc"><code>--bg-brand</code>, <code>--fg-secondary</code></td></tr>
                <tr><td><strong>Scales</strong></td><td><code>--iris-* --slate-*</code></td><td className="desc"><code>--iris-9</code>, <code>--slate-12</code></td></tr>
                <tr><td><strong>Type</strong></td><td><code>--font-* --text-*</code></td><td className="desc"><code>--font-primary</code>, <code>--text-heading-300-size</code></td></tr>
                <tr><td><strong>Radius</strong></td><td><code>--radius-*</code></td><td className="desc"><code>--radius-12</code></td></tr>
                <tr><td><strong>Elevation</strong></td><td><code>--shadow-*</code></td><td className="desc"><code>--shadow-300</code></td></tr>
              </tbody>
            </table>
          </section>

          <section id="color">
            <div className="dx-eyebrow">Foundations</div>
            <h2>Color.</h2>
            <p>Two layers: <strong>scales</strong> (raw 12-step ramps) and <strong>semantic aliases</strong> (what a color means). Use aliases in product code — they retint across light/dark and brand swaps.</p>
            <div style={{ display: "grid", gridTemplateColumns: "repeat(12,1fr)", gap: 6, margin: "12px 0 18px" }}>
              {Array.from({ length: 12 }, (_, i) => i + 1).map((n) => (
                <div key={n} title={`--iris-${n}`} style={{ height: 40, borderRadius: 6, background: `rgb(var(--iris-${n}))`, boxShadow: "inset 0 0 0 1px rgb(var(--border-secondary) / .5)" }} />
              ))}
            </div>
            <table className="dx-table">
              <thead><tr><th>Token</th><th>Role</th></tr></thead>
              <tbody>
                <tr><td><code>--bg-brand</code> · iris 9</td><td className="desc">Primary brand — filled buttons, focus, key moments.</td></tr>
                <tr><td><code>--bg-active</code> · indigo 9</td><td className="desc">Interaction — links, checked, selection.</td></tr>
                <tr><td><code>--bg-positive / negative / caution</code></td><td className="desc">Status — success, error, warning.</td></tr>
              </tbody>
            </table>
            <div className="dx-callout"><div className="ic">!</div><div><h5>Don't hard-code hex.</h5><p>Reference a token. <code>color: #5b5bd6</code> breaks in dark mode; use <code>rgb(var(--fg-brand))</code>.</p></div></div>
          </section>

          <section id="typography">
            <div className="dx-eyebrow">Foundations</div>
            <h2>Typography.</h2>
            <p>Three DM families: <strong>DM Sans</strong> for UI, <strong>DM Mono</strong> as a display/data face, <strong>DM Serif Display</strong> for editorial moments.</p>
            <table className="dx-table">
              <thead><tr><th>Role</th><th>Size / Line</th><th>Family</th></tr></thead>
              <tbody>
                <tr><td>Display</td><td>48–72 / 1.05</td><td className="desc">DM Serif Display</td></tr>
                <tr><td>Heading 300</td><td>36 / 40</td><td className="desc">DM Mono · 700</td></tr>
                <tr><td>Body 400</td><td>16 / 24</td><td className="desc">DM Sans · 400</td></tr>
                <tr><td>Mono 200</td><td>12 / 16</td><td className="desc">DM Mono</td></tr>
              </tbody>
            </table>
          </section>

          <section id="spacing">
            <div className="dx-eyebrow">Foundations</div>
            <h2>Spacing &amp; radius.</h2>
            <p>A 4-point spacing scale and a small radius set keep rhythm consistent. Icon buttons round fully; cards use <code>--radius-12</code> to <code>--radius-16</code>.</p>
            <table className="dx-table">
              <thead><tr><th>Token</th><th>px</th><th>Token</th><th>px</th></tr></thead>
              <tbody>
                <tr><td><code>--space-4</code></td><td>4</td><td><code>--radius-8</code></td><td>8</td></tr>
                <tr><td><code>--space-8</code></td><td>8</td><td><code>--radius-12</code></td><td>12</td></tr>
                <tr><td><code>--space-16</code></td><td>16</td><td><code>--radius-16</code></td><td>16</td></tr>
                <tr><td><code>--space-24</code></td><td>24</td><td><code>--radius-full</code></td><td>9999</td></tr>
              </tbody>
            </table>
          </section>

          <section id="components">
            <div className="dx-eyebrow">Components</div>
            <h2>22+ components, one vocabulary.</h2>
            <p>Every component is presentational and styled by tokens. A live peek:</p>
            <div className="dx-demo">
              <Button>Primary</Button>
              <Button variant="outline">Outline</Button>
              <Chip variant="brand">Pro</Chip>
              <Tag tone="positive">Live</Tag>
              <Badge variant="negative">3</Badge>
            </div>
            <div className="dx-demo" style={{ flexDirection: "column", alignItems: "stretch" }}>
              <Alert tone="success" title="Payment received">Your invoice has been paid.</Alert>
              <Progress value={72} variant="positive" />
            </div>
            {[
              ["Button", "Six variants, three sizes, leading/trailing slots.", "stable"],
              ["Input · Textarea · Search", "Labels, hints, validation, adornments.", "stable"],
              ["Select · Checkbox · Radio · Switch · Segmented · Slider", "The full selection set.", "stable"],
              ["Chip · Tag · Badge · Avatar", "Status, filters, counts, identity.", "stable"],
              ["Card · Alert · Progress · Tabs", "Surfaces, feedback, navigation.", "stable"],
              ["Modal · Tooltip · Table · AuthCode", "Overlays, data, verification.", "stable"],
            ].map(([nm, ds, st]) => (
              <div className="dx-comp" key={nm}>
                <div className="nm">{nm}</div>
                <div className="ds">{ds}</div>
                <Tag tone="positive">{st}</Tag>
                <div className="ver">v2.4</div>
              </div>
            ))}
          </section>

          <section id="effector">
            <div className="dx-eyebrow">Usage · Effector</div>
            <h2>Pluggable state.</h2>
            <p>State lives outside React in <code>@mercury/effector</code>. The theme toggle in the top bar, these toasts, and the quickstart form all run on Effector stores.</p>
            <div className="dx-demo">
              <Button variant="secondary" onClick={() => toast.success("Job retried")}>Success toast</Button>
              <Button variant="secondary" onClick={() => toast.error("Connection lost")}>Error toast</Button>
              <Button variant="secondary" onClick={() => toast.info("Sync started")}>Info toast</Button>
            </div>
            <div className="dx-code"><span className="tag">TSX</span><pre>{`import { useTheme, setTheme, toast, Toaster, createForm } from "@mercury/effector";

const theme = useTheme();        // reactive "light" | "dark"
setTheme("dark");
toast.success("Saved");          // render <Toaster /> once near root`}</pre></div>
          </section>

          <section id="accessibility">
            <div className="dx-eyebrow">Usage</div>
            <h2>Accessibility.</h2>
            <ul>
              <li>Focus rings use <code>--ring-focus</code> and never disappear.</li>
              <li>Color is never the only channel — status uses color + icon + text.</li>
              <li>Every <code>label</code> prop becomes a visible label and an accessible name.</li>
              <li>Modal traps Escape; controls are keyboard-navigable.</li>
            </ul>
          </section>

          <section id="changelog">
            <div className="dx-eyebrow">Release notes</div>
            <h2>Changelog.</h2>
            <h3>v2.4 — June 2026</h3>
            <ul>
              <li>New: <code>@mercury/effector</code> adapter — theme, toast, <code>createForm</code>.</li>
              <li>New: Vite library build (ESM + types) and three example apps.</li>
              <li>Add: <code>Button</code> gains <code>outline</code> and <code>inverse</code> variants.</li>
            </ul>
          </section>
        </main>

        <aside className="dx-toc">
          <h6>On this page</h6>
          {TOC.map((t) => (
            <a key={t.id} href={`#${t.id}`} className={active === t.id ? "is-active" : ""}>{t.label}</a>
          ))}
        </aside>
      </div>

      <Toaster position="bottom-end" />
    </>
  );
}

function SettingsDemo() {
  const replyTo = settings.useField("replyTo");
  const digest = settings.useField("digest");
  const updates = settings.useField("updates");
  return (
    <Card style={{ width: "100%", maxWidth: 420, padding: 24, display: "flex", flexDirection: "column", gap: 14 }}>
      <h3 style={{ margin: 0, font: "700 18px/1.2 var(--font-primary)" }}>Notifications</h3>
      <Input
        label="Reply-to address"
        value={replyTo.value}
        error={replyTo.error}
        onChange={(e) => replyTo.onChange(e.target.value)}
        onBlur={replyTo.onBlur}
      />
      <Switch checked={digest.value} onChange={digest.onChange} label="Weekly digest" />
      <Switch checked={updates.value} onChange={updates.onChange} label="Product updates" />
      <Button onClick={() => toast.success("Settings saved")}>Save changes</Button>
    </Card>
  );
}
