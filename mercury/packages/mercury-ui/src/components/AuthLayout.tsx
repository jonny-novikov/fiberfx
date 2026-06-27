import type { ReactNode } from "react";
import { cx } from "../cx";

/**
 * AuthLayout — the branded split-screen shell for authentication flows.
 * Left: a brand panel (hidden on narrow widths). Right: a centred form column
 * with an eyebrow / heading / subheading and a footer slot. Fills its parent
 * (height: 100%), so it works framed in a demo or as a full page.
 *
 * The brand panel is prop-driven with Mercury defaults; pass `brand` to
 * replace its body wholesale.
 */
export interface AuthLayoutProps {
  eyebrow?: string;
  heading?: ReactNode;
  subheading?: ReactNode;
  /** The form body. */
  children?: ReactNode;
  /** Footer row under the form (e.g. "New here? Create an account"). */
  footer?: ReactNode;
  /** Replace the brand-panel body entirely. */
  brand?: ReactNode;
  brandName?: string;
  brandBadge?: string;
  brandLogo?: ReactNode;
  brandTagline?: ReactNode;
  brandFeatures?: string[];
  brandStatus?: string;
  brandVersion?: string;
  className?: string;
}

const DEFAULT_FEATURES = [
  "Tokens, themes and dark mode out of the box",
  "Accessible components with sensible defaults",
  "An Effector state plug for forms and toasts",
];

const DEFAULT_LOGO = (
  <svg viewBox="0 0 24 24" width="22" height="22" fill="currentColor" aria-hidden="true">
    <path d="M13 2L4 14h6l-1 8 9-12h-6z" />
  </svg>
);

export function AuthLayout({
  eyebrow,
  heading,
  subheading,
  children,
  footer,
  brand,
  brandName = "Mercury",
  brandBadge = "UI",
  brandLogo = DEFAULT_LOGO,
  brandTagline = "The design system for your whole product.",
  brandFeatures = DEFAULT_FEATURES,
  brandStatus = "All systems operational",
  brandVersion = "v2.4.0",
  className,
}: AuthLayoutProps) {
  return (
    <div className={cx("mx-al", className)}>
      <aside className="mx-al__brand">
        <div className="mx-al__brandtop">
          <span className="mx-al__logo">{brandLogo}</span>
          <span className="mx-al__wordmark">{brandName}</span>
          {brandBadge && <span className="mx-al__badge">{brandBadge}</span>}
        </div>

        {brand ?? (
          <div className="mx-al__brandmid">
            <h2 className="mx-al__brandh">{brandTagline}</h2>
            <ul className="mx-al__feat">
              {brandFeatures.map((f) => (
                <li key={f}>
                  <span className="mx-al__check" aria-hidden="true">
                    ✓
                  </span>
                  {f}
                </li>
              ))}
            </ul>
          </div>
        )}

        <div className="mx-al__brandfoot">
          <span className="mx-al__statline">
            <span className="mx-al__dot" />
            {brandStatus}
          </span>
          {brandVersion && <span className="mx-al__ver">{brandVersion}</span>}
        </div>

        <span className="mx-al__glow mx-al__glow--1" aria-hidden="true" />
        <span className="mx-al__glow mx-al__glow--2" aria-hidden="true" />
      </aside>

      <main className="mx-al__main">
        <div className="mx-al__form">
          {eyebrow && <p className="mx-al__eyebrow">{eyebrow}</p>}
          {heading && <h1 className="mx-al__h">{heading}</h1>}
          {subheading && <p className="mx-al__sub">{subheading}</p>}
          <div className="mx-al__body">{children}</div>
          {footer && <div className="mx-al__foot">{footer}</div>}
        </div>
      </main>
    </div>
  );
}
