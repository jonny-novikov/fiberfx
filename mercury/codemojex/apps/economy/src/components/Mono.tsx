import type { ReactNode } from "react";

/** Tabular-numeric (DM Mono) inline wrapper for table/figure cells. */
export const Mono = ({ children }: { children: ReactNode }) => <span className="ecn-mono">{children}</span>;
