import { useState } from "react";
import type { HTMLAttributes, ReactNode } from "react";
import { cx } from "@mercury/core";
import { Icon } from "../../foundations/Icon";

export interface CollapsibleProps extends Omit<HTMLAttributes<HTMLDivElement>, "title"> {
  /** The always-visible header label. */
  title: ReactNode;
  children?: ReactNode;
  /** Uncontrolled initial open state. Default `false`. */
  defaultOpen?: boolean;
  /** Controlled open state — pair with `onOpenChange`. */
  open?: boolean;
  /** Called with the next open state on toggle. */
  onOpenChange?: (open: boolean) => void;
  /** Wrap in a bordered card. Default `true`. */
  bordered?: boolean;
  /** Accent ramp tinting the toggle when open (bg `--<ramp>-3`, ink `--<ramp>-11`). Default `iris`. */
  accent?: "iris" | "indigo" | "green" | "orange" | "plum" | "red";
  /** Container width — number (px) or any length string. Default `360`. */
  width?: number | string;
}

/**
 * Collapsible — a single disclosure: a header with a round toggle that reveals its
 * body on a grid-rows height animation. Controlled (`open` + `onOpenChange`) or
 * uncontrolled (`defaultOpen`). Distinct from Accordion (a managed set of disclosures);
 * compose Collapsibles freely for an unmanaged group. The chevron is the live `Icon`.
 */
export function Collapsible({
  title,
  children,
  defaultOpen = false,
  open: openProp,
  onOpenChange,
  bordered = true,
  accent = "iris",
  width = 360,
  className,
  style,
  ...rest
}: CollapsibleProps) {
  const isControlled = openProp != null;
  const [internalOpen, setInternalOpen] = useState(defaultOpen);
  const open = isControlled ? openProp : internalOpen;
  const toggle = () => {
    const next = !open;
    if (!isControlled) setInternalOpen(next);
    onOpenChange?.(next);
  };
  return (
    <div
      className={cx(
        "mx-collapsible",
        bordered && "mx-collapsible--bordered",
        `mx-collapsible--accent-${accent}`,
        open && "is-open",
        className,
      )}
      style={{ width, ...style }}
      {...rest}
    >
      <div className="mx-collapsible__header">
        <span className="mx-collapsible__title">{title}</span>
        <button type="button" className="mx-collapsible__toggle" aria-expanded={open} onClick={toggle}>
          <span className="mx-collapsible__chev" aria-hidden="true">
            <Icon name="chevron-down" size={15} />
          </span>
        </button>
      </div>
      <div className="mx-collapsible__panel">
        <div className="mx-collapsible__panel-inner">
          <div className="mx-collapsible__content">{children}</div>
        </div>
      </div>
    </div>
  );
}

export default Collapsible;
