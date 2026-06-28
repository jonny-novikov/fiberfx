import type { HTMLAttributes, MouseEventHandler, ReactNode } from "react";
import { cx } from "@mercury/core";

export interface ListRowProps extends Omit<HTMLAttributes<HTMLElement>, "onClick"> {
  /** The primary text (required). */
  label: ReactNode;
  /** A leading glyph/avatar slot — drive with a real <Icon /> / <Avatar />. */
  leading?: ReactNode;
  /** Secondary text below `label` (the "meta"/subtitle). */
  description?: ReactNode;
  /** Trailing value text, right-aligned — e.g. a settings value or an amount. */
  value?: ReactNode;
  /** A trailing affordance after `value` (a chevron / action). */
  trailing?: ReactNode;
  /** When present, the row is interactive (rendered as a <button>); else a non-interactive <div>. */
  onClick?: MouseEventHandler<HTMLElement>;
}

export function ListRow({ label, leading, description, value, trailing, onClick, className, ...rest }: ListRowProps) {
  const interactive = onClick != null;
  const cls = cx("mx-listrow", interactive && "mx-listrow--interactive", className);
  const content = (
    <>
      {leading != null && <span className="mx-listrow__lead">{leading}</span>}
      <span className="mx-listrow__body">
        <span className="mx-listrow__label">{label}</span>
        {description != null && <span className="mx-listrow__desc">{description}</span>}
      </span>
      {value != null && <span className="mx-listrow__value">{value}</span>}
      {trailing != null && <span className="mx-listrow__trail">{trailing}</span>}
    </>
  );

  if (interactive) {
    return (
      <button type="button" className={cls} onClick={onClick} {...rest}>
        {content}
      </button>
    );
  }
  return (
    <div className={cls} {...rest}>
      {content}
    </div>
  );
}
