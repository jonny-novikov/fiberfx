import { createPortal } from "react-dom";
import type { ReactNode } from "react";

export interface PortalProps {
  children: ReactNode;
}

/**
 * Portal — the overlay-floor's thin `createPortal` wrapper. Mounts `children`
 * at `document.body` so a floating surface escapes any `overflow`/stacking
 * context of its origin subtree. The behavior floor (focus-trap · dismiss ·
 * anchored-position) lives in `@mercury/core`; `createPortal` lives here
 * because `@mercury/core` has no `react-dom` peer (mx.7.4 §4).
 *
 * SSR-guarded: with no `document` it renders nothing.
 */
export function Portal({ children }: PortalProps): ReactNode {
  if (typeof document === "undefined") return null;
  return createPortal(children, document.body);
}
