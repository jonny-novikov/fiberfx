import { useEffect, useMemo, useState } from "react";

// Client-side page + search plumbing shared by the list desks (admin.5.1-R6):
// filter and slice the client-held rows in the browser — no server param, no
// route change (admin.5.1-INV5). App plumbing only, never a @mercury component
// (the package/app split, admin.5.1-INV3).
const PAGE_SIZE = 25;

export interface PagedList<T> {
  query: string;
  setQuery: (value: string) => void;
  page: number; // 1-based, clamped to pageCount
  setPage: (page: number) => void;
  pageCount: number; // total PAGES, not rows (the Pagination `count` prop)
  paged: T[]; // the current page's slice of the filtered rows
  filteredCount: number;
  caption: string; // Showing X–Y of Z
}

export function usePagedList<T>(
  rows: T[],
  match: (row: T, query: string) => boolean,
  resetKey?: unknown,
): PagedList<T> {
  const [query, setQuery] = useState("");
  const [page, setPage] = useState(1);

  // Reset to the first page whenever the query or the upstream filter changes.
  useEffect(() => {
    setPage(1);
  }, [query, resetKey]);

  const filtered = useMemo(() => {
    const q = query.trim().toLowerCase();
    return q === "" ? rows : rows.filter((r) => match(r, q));
  }, [rows, query, match]);

  const pageCount = Math.max(1, Math.ceil(filtered.length / PAGE_SIZE));
  const clamped = Math.min(page, pageCount);
  const paged = filtered.slice((clamped - 1) * PAGE_SIZE, clamped * PAGE_SIZE);
  const from = filtered.length === 0 ? 0 : (clamped - 1) * PAGE_SIZE + 1;
  const to = Math.min(clamped * PAGE_SIZE, filtered.length);

  return {
    query,
    setQuery,
    page: clamped,
    setPage,
    pageCount,
    paged,
    filteredCount: filtered.length,
    caption: `Showing ${from}–${to} of ${filtered.length}`,
  };
}
