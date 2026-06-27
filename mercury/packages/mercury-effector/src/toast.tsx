import { createEffect, createEvent, createStore, sample } from "effector";
import { useUnit } from "effector-react";
import { Alert } from "@mercury/ui";
import type { AlertTone } from "@mercury/ui";

export interface ToastOptions {
  tone?: AlertTone;
  title?: string;
  message?: string;
  /** Auto-dismiss after N ms. Default 4000. Pass 0 to keep open. */
  duration?: number;
}

export interface ToastItem {
  id: number;
  tone: AlertTone;
  title?: string;
  message?: string;
  duration: number;
}

let seq = 0;

export const showToast = createEvent<ToastOptions | string>();
export const dismissToast = createEvent<number>();
export const clearToasts = createEvent();

const added = showToast.map((input): ToastItem => {
  const o = typeof input === "string" ? { message: input } : input;
  return {
    id: ++seq,
    tone: o.tone ?? "info",
    title: o.title,
    message: o.message,
    duration: o.duration ?? 4000,
  };
});

export const $toasts = createStore<ToastItem[]>([])
  .on(added, (list, t) => [...list, t])
  .on(dismissToast, (list, id) => list.filter((t) => t.id !== id))
  .reset(clearToasts);

const autoDismissFx = createEffect(
  (t: ToastItem) => new Promise<number>((resolve) => setTimeout(() => resolve(t.id), t.duration)),
);

sample({ clock: added.filter({ fn: (t) => t.duration > 0 }), target: autoDismissFx });
sample({ clock: autoDismissFx.doneData, target: dismissToast });

/** Imperative helper: `toast.success("Saved")`, `toast.error({ title, message })`. */
export const toast = {
  show: (o: ToastOptions | string) => showToast(o),
  info: (message: string, o: Omit<ToastOptions, "tone" | "message"> = {}) => showToast({ ...o, tone: "info", message }),
  success: (message: string, o: Omit<ToastOptions, "tone" | "message"> = {}) => showToast({ ...o, tone: "success", message }),
  warning: (message: string, o: Omit<ToastOptions, "tone" | "message"> = {}) => showToast({ ...o, tone: "warning", message }),
  error: (message: string, o: Omit<ToastOptions, "tone" | "message"> = {}) => showToast({ ...o, tone: "danger", message }),
};

export const useToasts = (): ToastItem[] => useUnit($toasts);

export type ToasterPosition = "top-end" | "bottom-end" | "bottom-center";

const POS: Record<ToasterPosition, React.CSSProperties> = {
  "top-end": { top: 16, right: 16, alignItems: "flex-end" },
  "bottom-end": { bottom: 16, right: 16, alignItems: "flex-end" },
  "bottom-center": { bottom: 16, left: "50%", transform: "translateX(-50%)", alignItems: "center" },
};

/** Drop once near the app root. Renders live toasts as Mercury Alerts. */
export function Toaster({ position = "bottom-end" }: { position?: ToasterPosition }) {
  const toasts = useToasts();
  return (
    <div
      style={{
        position: "fixed",
        zIndex: 200,
        display: "flex",
        flexDirection: "column",
        gap: 10,
        pointerEvents: "none",
        ...POS[position],
      }}
    >
      {toasts.map((t) => (
        <div key={t.id} style={{ pointerEvents: "auto", width: 360, maxWidth: "calc(100vw - 32px)", boxShadow: "var(--shadow-300)", borderRadius: "var(--radius-12)" }}>
          <Alert tone={t.tone} title={t.title} dismissible onDismiss={() => dismissToast(t.id)}>
            {t.message}
          </Alert>
        </div>
      ))}
    </div>
  );
}
