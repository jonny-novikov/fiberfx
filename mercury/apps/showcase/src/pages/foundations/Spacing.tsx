import { Page, PageHead, Section } from "../../chrome/Page";

const SPACING_STEPS = [2, 4, 8, 12, 16, 24, 32, 48, 64, 96];

const RADII = [0, 4, 6, 8, 12, 16, 24, 9999].map((r) => ({
  r: r === 9999 ? "9999px" : r + "px",
  label: r === 9999 ? "full" : r + "px",
}));

const SHADOWS = [100, 200, 300, 400, 500];

export function Spacing() {
  return (
    <Page>
      <PageHead
        eyebrow="Foundations"
        title="Spacing, radius & elevation"
        lede="A 4-point scale, a small radius token set, and a layered shadow ramp. Fewer choices, more consistency."
      />

      <Section title="Spacing scale" />
      <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>
        {SPACING_STEPS.map((n) => (
          <div key={n} style={{ display: "flex", alignItems: "center", gap: 16 }}>
            <div
              style={{ width: 56, font: "500 12px/1 var(--font-secondary)", color: "rgb(var(--fg-tertiary))" }}
            >
              {n}px
            </div>
            <div style={{ height: 20, borderRadius: 4, background: "rgb(var(--bg-brand))", width: n }} />
          </div>
        ))}
      </div>

      <Section title="Radius" />
      <div style={{ display: "flex", gap: 16, flexWrap: "wrap" }}>
        {RADII.map((r) => (
          <div key={r.label} style={{ textAlign: "center" }}>
            <div
              style={{
                width: 72,
                height: 72,
                background: "rgb(var(--bg-brand-subtle))",
                border: "1px solid rgb(var(--border-brand))",
                borderRadius: r.r,
              }}
            />
            <div style={{ font: "500 12px/1.6 var(--font-secondary)", color: "rgb(var(--fg-secondary))" }}>
              {r.label}
            </div>
          </div>
        ))}
      </div>

      <Section title="Elevation" />
      <div
        style={{
          display: "grid",
          gridTemplateColumns: "repeat(auto-fit,minmax(160px,1fr))",
          gap: 20,
          padding: 32,
          background: "rgb(var(--bg-secondary))",
          borderRadius: 12,
        }}
      >
        {SHADOWS.map((sh) => (
          <div
            key={sh}
            style={{
              height: 100,
              borderRadius: 10,
              background: "rgb(var(--bg-primary))",
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              font: "600 13px/1 var(--font-primary)",
              boxShadow: `var(--shadow-${sh})`,
            }}
          >
            shadow-{sh}
          </div>
        ))}
      </div>
    </Page>
  );
}
