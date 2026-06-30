import type { HTMLAttributes, ReactNode } from "react";
import { cx } from "@mercury/core";
import { Icon } from "../../foundations/Icon";
import type { IconName } from "../../foundations/Icon";

export type CalloutIntent = "info" | "brand" | "positive" | "caution" | "negative" | "discovery";
export type CalloutVariant = "soft" | "surface" | "outline";
export type CalloutSize = "sm" | "md" | "lg";

// Default glyph per intent — every name is a real entry in the live Icon set
// (`foundations/Icon`). No "warning"/"circleHelp" (bundle names absent here).
const INTENT_ICON: Record<CalloutIntent, IconName> = {
  info: "info",
  brand: "info",
  positive: "check",
  caution: "alert",
  negative: "alert",
  discovery: "help-circle",
};

const ICON_PX: Record<CalloutSize, number> = { sm: 16, md: 18, lg: 20 };

export interface CalloutProps extends Omit<HTMLAttributes<HTMLDivElement>, "title"> {
  /** Optional bold lead line above the body. */
  title?: ReactNode;
  /** Tone family — resolves to the semantic token families (canon §6). Default `info`. */
  intent?: CalloutIntent;
  /** Fill/border treatment. Default `soft`. */
  variant?: CalloutVariant;
  size?: CalloutSize;
  /** Override the default intent glyph; pass `null` to hide the icon. */
  icon?: IconName | null;
  children?: ReactNode;
}

/**
 * Callout — an inline emphasis block: a note set into the reading flow on a tinted,
 * surface, or outlined card. Distinct from Alert (a status message, the result of an
 * action) — Callout is editorial emphasis. `intent` selects the semantic token family;
 * `variant` selects the fill/border treatment. Styled through `.mx-callout` token
 * classes — no inline ink.
 */
export function Callout({
  title,
  intent = "info",
  variant = "soft",
  size = "md",
  icon,
  className,
  children,
  ...rest
}: CalloutProps) {
  const showIcon = icon !== null;
  const glyph = icon ?? INTENT_ICON[intent];
  return (
    <div
      role="note"
      className={cx(
        "mx-callout",
        `mx-callout--${intent}`,
        `mx-callout--${variant}`,
        `mx-callout--${size}`,
        className,
      )}
      {...rest}
    >
      {showIcon && (
        <span className="mx-callout__icon" aria-hidden="true">
          <Icon name={glyph} size={ICON_PX[size]} />
        </span>
      )}
      <div className="mx-callout__body">
        {title && <div className="mx-callout__title">{title}</div>}
        <div className="mx-callout__msg">{children}</div>
      </div>
    </div>
  );
}

export default Callout;
