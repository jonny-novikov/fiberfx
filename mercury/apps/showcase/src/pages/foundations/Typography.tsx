import type { CSSProperties } from "react";
import { Page, PageHead, Section } from "../../chrome/Page";

type Role = { meta: string; style: CSSProperties; sample: string };

const TYPE_ROLES: Role[] = [
  {
    meta: "Display / XL · 72 · 400",
    style: {
      fontFamily: "var(--font-display)",
      fontSize: 72,
      lineHeight: 1,
      letterSpacing: "-0.02em",
      fontWeight: 400,
    },
    sample: "Design with intent.",
  },
  {
    meta: "H1 · 40 · 700",
    style: {
      fontFamily: "var(--font-primary)",
      fontSize: 40,
      lineHeight: 1.1,
      letterSpacing: "-0.025em",
      fontWeight: 700,
    },
    sample: "A thoughtful system for modern products.",
  },
  {
    meta: "H2 · 28 · 700",
    style: {
      fontFamily: "var(--font-primary)",
      fontSize: 28,
      lineHeight: 1.2,
      letterSpacing: "-0.015em",
      fontWeight: 700,
    },
    sample: "Clear hierarchy, honest contrast.",
  },
  {
    meta: "H3 · 20 · 600",
    style: {
      fontFamily: "var(--font-primary)",
      fontSize: 20,
      lineHeight: 1.3,
      letterSpacing: "-0.01em",
      fontWeight: 600,
    },
    sample: "Components should feel inevitable.",
  },
  {
    meta: "Body · 16 · 400",
    style: {
      fontFamily: "var(--font-primary)",
      fontSize: 16,
      lineHeight: 1.6,
      fontWeight: 400,
    },
    sample:
      "Body copy is the backbone of every UI. It carries the longest weight of reading, so it deserves the most care — comfortable measure, generous leading, never-too-thin weight.",
  },
  {
    meta: "Small · 13 · 500",
    style: {
      fontFamily: "var(--font-primary)",
      fontSize: 13,
      lineHeight: 1.5,
      fontWeight: 500,
      color: "rgb(var(--fg-secondary))",
    },
    sample: "Smaller copy for captions, hints and supporting text.",
  },
  {
    meta: "Mono · 14 · 400",
    style: {
      fontFamily: "var(--font-secondary)",
      fontSize: 14,
      lineHeight: 1.6,
      fontWeight: 400,
    },
    sample: "const token = 'iris-9';",
  },
];

export function Typography() {
  return (
    <Page>
      <PageHead
        eyebrow="Foundations"
        title="Typography"
        lede="Three DM families cover every surface: Sans for product UI, Mono for code and data, Serif Display for editorial moments. Font roles are deliberate — if a size isn't here, it's probably wrong."
      />

      <Section title="Type roles" />
      {TYPE_ROLES.map((t) => (
        <div
          key={t.meta}
          style={{ padding: "24px 0", borderBottom: "1px solid rgb(var(--border-secondary))" }}
        >
          <div
            style={{
              font: "500 12px/1 var(--font-secondary)",
              color: "rgb(var(--fg-tertiary))",
              marginBottom: 12,
              letterSpacing: "1.5px",
              textTransform: "uppercase",
            }}
          >
            {t.meta}
          </div>
          <div style={{ color: "rgb(var(--fg-primary))", ...t.style }}>{t.sample}</div>
        </div>
      ))}
    </Page>
  );
}
