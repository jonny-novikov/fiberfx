import { Page, PageHead, Section } from "../../chrome/Page";

const ink = (step: number) => (step >= 9 ? "slate-1" : "slate-12");

const RAMPS = [
  { name: "Slate · neutral", key: "slate" },
  { name: "Iris · brand", key: "iris" },
  { name: "Indigo · active", key: "indigo" },
].map((r) => ({
  ...r,
  swatches: Array.from({ length: 12 }, (_, i) => ({
    step: i + 1,
    v: r.key + "-" + (i + 1),
    ink: ink(i + 1),
  })),
}));

const ALIAS_GROUPS = [
  { name: "Surfaces", tokens: ["bg-primary", "bg-secondary", "bg-tertiary", "bg-elevated", "bg-inverse"] },
  { name: "Brand", tokens: ["bg-brand", "bg-brand-hover", "bg-brand-subtle", "fg-brand"] },
  { name: "Foregrounds", tokens: ["fg-primary", "fg-secondary", "fg-tertiary", "fg-disabled"] },
  { name: "Status", tokens: ["bg-positive", "bg-negative", "bg-caution", "bg-discovery", "bg-info"] },
  { name: "Borders", tokens: ["border-primary", "border-secondary", "border-strong", "border-focus"] },
].map((g) => ({
  name: g.name,
  tokens: g.tokens.map((t) => ({
    name: t,
    bg: t.startsWith("fg") ? "bg-secondary" : t,
    glyph: t.startsWith("fg") ? "Aa" : "",
  })),
}));

export function Colors() {
  return (
    <Page>
      <PageHead
        eyebrow="Foundations"
        title="Colors"
        lede="Three full 12-step ramps make up the core primitive layer, with solid status hues for state. Every UI uses semantic aliases — never a raw ramp step — so the same component class re-skins with a token swap."
      />

      <Section title="Ramps" hint="1 → 12, light to dark" />
      {RAMPS.map((r) => (
        <div key={r.key}>
          <p className="colcap">{r.name}</p>
          <div className="tokrow">
            {r.swatches.map((s) => (
              <div
                key={s.v}
                className="toksw"
                style={{ background: `rgb(var(--${s.v}))`, color: `rgb(var(--${s.ink}))` }}
              >
                <span className="k">{r.key}</span>
                <span>{s.step}</span>
              </div>
            ))}
          </div>
        </div>
      ))}

      <Section title="Semantic aliases" hint="What components actually consume" />
      {ALIAS_GROUPS.map((g) => (
        <div key={g.name} style={{ marginBottom: 20 }}>
          <div className="fieldlabel">{g.name}</div>
          <div className="alias-grid">
            {g.tokens.map((t) => (
              <div key={t.name} className="alias">
                <div
                  className="sw"
                  style={{ background: `rgb(var(--${t.bg}))`, color: `rgb(var(--${t.name}))` }}
                >
                  {t.glyph}
                </div>
                <div className="nm">--{t.name}</div>
              </div>
            ))}
          </div>
        </div>
      ))}
    </Page>
  );
}
