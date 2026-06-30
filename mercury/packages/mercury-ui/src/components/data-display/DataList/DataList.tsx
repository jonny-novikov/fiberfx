import type { HTMLAttributes, ReactNode } from "react";
import { cx } from "@mercury/core";

export type DataListOrientation = "horizontal" | "vertical";
export type DataListSize = "sm" | "md" | "lg";

export interface DataListEntry {
  /** The term — rendered in the `<dt>`. */
  label: ReactNode;
  /** The description — rendered in the `<dd>`. */
  value: ReactNode;
}

export interface DataListProps extends Omit<HTMLAttributes<HTMLDListElement>, "children"> {
  /** The term/description pairs. */
  items: DataListEntry[];
  /** Lay each pair side-by-side (`horizontal`) or stacked (`vertical`). Default `horizontal`. */
  orientation?: DataListOrientation;
  /** Type size + row gap. Default `md`. */
  size?: DataListSize;
  /** Label-column width in the horizontal layout (number → px). Default `140`. */
  labelWidth?: number;
}

/**
 * DataList — key/value pairs as a semantic `<dl>`: account fields, transaction
 * metadata, settings summaries. `horizontal` lays each term beside its value in a
 * fixed `labelWidth` column; `vertical` stacks them. Styled through `.mx-datalist`
 * token classes — no inline ink.
 */
export function DataList({
  items,
  orientation = "horizontal",
  size = "md",
  labelWidth = 140,
  className,
  ...rest
}: DataListProps) {
  const horizontal = orientation === "horizontal";
  return (
    <dl
      className={cx("mx-datalist", `mx-datalist--${orientation}`, `mx-datalist--${size}`, className)}
      {...rest}
    >
      {items.map((it, i) => (
        <div key={i} className="mx-datalist__row">
          {/* labelWidth is a non-color dynamic inline style (allowed by INV-2). */}
          <dt className="mx-datalist__label" style={horizontal ? { width: labelWidth } : undefined}>
            {it.label}
          </dt>
          <dd className="mx-datalist__value">{it.value}</dd>
        </div>
      ))}
    </dl>
  );
}

export default DataList;
