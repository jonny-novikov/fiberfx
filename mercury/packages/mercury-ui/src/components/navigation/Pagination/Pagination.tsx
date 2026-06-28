import { forwardRef } from "react";
import type { HTMLAttributes, ReactNode } from "react";
import { cx } from "@mercury/core";

export interface PaginationProps extends Omit<HTMLAttributes<HTMLElement>, "onChange"> {
  /** 1-based current page. */
  page: number;
  /** Total number of pages. */
  count: number;
  onPageChange: (page: number) => void;
  /** Pages shown on each side of the current page. Default 1. */
  siblingCount?: number;
  size?: "sm" | "md";
  /** Optional caption rendered under the controls (e.g. "Showing 1 – 10"). */
  caption?: ReactNode;
}

function range(start: number, end: number): number[] {
  const out: number[] = [];
  for (let i = start; i <= end; i++) out.push(i);
  return out;
}

function buildPages(page: number, count: number, sib: number): (number | "dots")[] {
  const slots = sib * 2 + 5; // first + last + current + 2 ellipses + siblings
  if (count <= slots) return range(1, count);
  const left = Math.max(page - sib, 1);
  const right = Math.min(page + sib, count);
  const showLeft = left > 2;
  const showRight = right < count - 1;
  if (!showLeft && showRight) return [...range(1, sib * 2 + 3), "dots", count];
  if (showLeft && !showRight) return [1, "dots", ...range(count - (sib * 2 + 2), count)];
  return [1, "dots", ...range(left, right), "dots", count];
}

function Caret({ dir }: { dir: "left" | "right" }) {
  return (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <path d={dir === "left" ? "M15 18l-6-6 6-6" : "M9 18l6-6-6-6"} />
    </svg>
  );
}

export const Pagination = forwardRef<HTMLElement, PaginationProps>(function Pagination(
  { page, count, onPageChange, siblingCount = 1, size = "md", caption, className, ...rest },
  ref,
) {
  const pages = buildPages(page, count, siblingCount);
  const go = (p: number) => {
    if (p >= 1 && p <= count && p !== page) onPageChange(p);
  };

  return (
    <nav ref={ref} className={cx("mx-pag", `mx-pag--${size}`, className)} aria-label="Pagination" {...rest}>
      <ul className="mx-pag__list">
        <li>
          <button type="button" className="mx-pag__btn mx-pag__btn--nav" disabled={page <= 1} aria-label="Previous page" onClick={() => go(page - 1)}>
            <Caret dir="left" />
          </button>
        </li>
        {pages.map((p, i) =>
          p === "dots" ? (
            <li key={`d${i}`}>
              <span className="mx-pag__gap" aria-hidden="true">…</span>
            </li>
          ) : (
            <li key={p}>
              <button
                type="button"
                className={cx("mx-pag__btn", p === page && "is-active")}
                aria-current={p === page ? "page" : undefined}
                onClick={() => go(p)}
              >
                {p}
              </button>
            </li>
          ),
        )}
        <li>
          <button type="button" className="mx-pag__btn mx-pag__btn--nav" disabled={page >= count} aria-label="Next page" onClick={() => go(page + 1)}>
            <Caret dir="right" />
          </button>
        </li>
      </ul>
      {caption != null && <div className="mx-pag__caption">{caption}</div>}
    </nav>
  );
});
