import type { ReactNode } from "react";

/* Page scaffolding shared by every showcase page. */

export function Page({ children }: { children: ReactNode }) {
  return <div className="page">{children}</div>;
}

export function PageHead({ eyebrow, title, lede }: { eyebrow: string; title: string; lede: ReactNode }) {
  return (
    <>
      <div className="eyebrow">{eyebrow}</div>
      <h1 className="ptitle">{title}</h1>
      <p className="lede">{lede}</p>
    </>
  );
}

export function Section({ title, hint }: { title: string; hint?: string }) {
  return (
    <div className="sec">
      <h2>{title}</h2>
      {hint && <span className="hint">{hint}</span>}
    </div>
  );
}
