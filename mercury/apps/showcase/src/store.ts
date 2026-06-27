/*
 * Showcase application state — modelled in Effector, the same way a real
 * Mercury consumer would. The @mercury/effector plug supplies the
 * design-system models (theme, toasts, forms); this file is the app's own
 * cross-cutting state: which page is shown, the live progress ticker, and
 * the two app-level modals. Ephemeral per-demo widget state stays in React.
 */
import { createEvent, createStore } from "effector";
import { useUnit } from "effector-react";

/* ───────── Routing ───────── */
export type Route =
  | "overview"
  | "foundations/colors"
  | "foundations/type"
  | "foundations/spacing"
  | "components/button"
  | "components/link"
  | "components/input"
  | "components/selection"
  | "components/chip"
  | "components/avatar"
  | "components/alert"
  | "components/progress"
  | "components/divider"
  | "components/tabs"
  | "components/modal"
  | "components/table"
  | "patterns/forms"
  | "patterns/auth"
  | "patterns/dashboard";

const ROUTE_KEY = "mercury-showcase-route";

function initialRoute(): Route {
  if (typeof localStorage !== "undefined") {
    const saved = localStorage.getItem(ROUTE_KEY);
    if (saved) return saved as Route;
  }
  return "overview";
}

export const navigate = createEvent<Route>();

export const $route = createStore<Route>(initialRoute()).on(navigate, (_, r) => r);

$route.watch((r) => {
  if (typeof localStorage !== "undefined") {
    try {
      localStorage.setItem(ROUTE_KEY, r);
    } catch {
      /* ignore */
    }
  }
});

export const useRoute = (): Route => useUnit($route);

/* ───────── Live progress ticker (drives the Progress page demo) ───────── */
export const tick = createEvent();
export const $progress = createStore(42).on(tick, (p) => (p + 7) % 100);
export const useProgress = (): number => useUnit($progress);

/* ───────── App-level modals ───────── */
export const openInvite = createEvent();
export const closeInvite = createEvent();
export const openDanger = createEvent();
export const closeDanger = createEvent();

export const $inviteOpen = createStore(false)
  .on(openInvite, () => true)
  .on(closeInvite, () => false);

export const $dangerOpen = createStore(false)
  .on(openDanger, () => true)
  .on(closeDanger, () => false);
