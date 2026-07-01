import { createEvent, createStore } from "effector";
import { useUnit } from "effector-react";

/**
 * @mercury/effector — the overlay disclosure bridge (mx.7.4 §E).
 *
 * The optional driver for the presentational overlays (`Dialog`/`AlertDialog`/
 * `Popover`). It PRODUCES their controlled state and manages the cross-overlay
 * concern a single component cannot — a global body-scroll-lock — exactly as
 * `theme`/`toast` drive their components from the outside. `@mercury/ui` gains
 * NO dependency on this: the arrow is effector -> ui only (INV-EFFECTOR).
 */

// --- E.1 · createDisclosure() — the per-overlay controlled-state FACTORY ---

/**
 * createDisclosure — a controlled open/close model for one overlay instance, as
 * Effector state (the `createCooldown` factory idiom). Each call returns an
 * INDEPENDENT model; a consumer wires `useOpen()` into an overlay's `open` prop
 * and `close`/`open`/`toggle` into its `onClose`/`onOpenChange`. The overlay
 * stays the source of truth for its DOM; the model is the source of truth for
 * whether it is open.
 */
export function createDisclosure(opts?: { defaultOpen?: boolean }) {
  const open = createEvent();
  const close = createEvent();
  const toggle = createEvent();

  const $open = createStore<boolean>(opts?.defaultOpen ?? false)
    .on(open, () => true)
    .on(close, () => false)
    .on(toggle, (o) => !o);

  /** Reactive open state for components (the `useTheme`/`useCooldown` idiom). */
  const useOpen = (): boolean => useUnit($open);

  return { $open, open, close, toggle, useOpen };
}

// --- E.2 · the global overlay-stack + body-scroll-lock SINGLETON ---

/** The id of one open overlay in the global stack. */
export type OverlayId = string;

/** Register an overlay's id when it opens (modal consumers only). */
export const pushOverlay = createEvent<OverlayId>();
/** Unregister an overlay's id when it closes. */
export const popOverlay = createEvent<OverlayId>();

/**
 * $openOverlays — the LIFO stack of open overlay ids. Push appends (the last
 * opened is topmost, for `Escape`-topmost + z-ordering); pop removes the most
 * recent occurrence of the id (defensive against a doubled push).
 */
export const $openOverlays = createStore<OverlayId[]>([])
  .on(pushOverlay, (stack, id) => [...stack, id])
  .on(popOverlay, (stack, id) => {
    const i = stack.lastIndexOf(id);
    return i === -1 ? stack : [...stack.slice(0, i), ...stack.slice(i + 1)];
  });

/** True while any overlay is open. */
export const $anyOverlayOpen = $openOverlays.map((s) => s.length > 0);
/** The topmost (most-recently opened) overlay id, or null when none is open. */
export const $topOverlay = $openOverlays.map((s) => s.at(-1) ?? null);

/** Reactive "is any overlay open" for components. */
export const useAnyOverlayOpen = (): boolean => useUnit($anyOverlayOpen);

// The lock is idempotent + reversible: capture the body's prior inline overflow/
// padding on the FIRST lock and restore them on the LAST release, so nested
// modals share one lock and the layout never shifts.
let lockStarted = false;
let locked = false;
let prevOverflow = "";
let prevPaddingRight = "";

function applyLock(anyOpen: boolean): void {
  if (typeof document === "undefined") return;
  const body = document.body;
  if (anyOpen && !locked) {
    locked = true;
    prevOverflow = body.style.overflow;
    prevPaddingRight = body.style.paddingRight;
    // Compensate the removed scrollbar width so hiding overflow does not shift
    // the layout under the overlay.
    const scrollbar = window.innerWidth - document.documentElement.clientWidth;
    body.style.overflow = "hidden";
    if (scrollbar > 0) {
      const current = parseFloat(getComputedStyle(body).paddingRight) || 0;
      body.style.paddingRight = `${current + scrollbar}px`;
    }
  } else if (!anyOpen && locked) {
    locked = false;
    body.style.overflow = prevOverflow;
    body.style.paddingRight = prevPaddingRight;
  }
}

/**
 * Call once at app start to lock body scroll while any overlay is open, padding-
 * compensated so the layout does not shift. Idempotent (the `initTheme` idiom);
 * SSR-guarded. Opt-in: the singleton does NOT auto-fire from `createDisclosure` —
 * a MODAL consumer calls `pushOverlay`/`popOverlay`; a non-modal `Popover` does
 * not, so modals lock scroll and popovers do not.
 */
export function initOverlayLock(): void {
  if (lockStarted) return;
  lockStarted = true;
  if (typeof document === "undefined") return;
  applyLock($anyOverlayOpen.getState());
  $anyOverlayOpen.watch(applyLock);
}
