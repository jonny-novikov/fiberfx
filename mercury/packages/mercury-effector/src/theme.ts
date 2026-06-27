import { createEvent, createStore } from "effector";
import { useUnit } from "effector-react";

export type Theme = "light" | "dark";

const STORAGE_KEY = "mercury-theme";

function initial(): Theme {
  if (typeof localStorage !== "undefined") {
    const saved = localStorage.getItem(STORAGE_KEY);
    if (saved === "light" || saved === "dark") return saved;
  }
  return "light";
}

export const setTheme = createEvent<Theme>();
export const toggleTheme = createEvent();

export const $theme = createStore<Theme>(initial())
  .on(setTheme, (_, t) => t)
  .on(toggleTheme, (t) => (t === "dark" ? "light" : "dark"));

/** Apply the theme class to <html> and persist it, now and on every change. */
function apply(theme: Theme) {
  if (typeof document !== "undefined") {
    const el = document.documentElement;
    el.classList.remove("light-theme", "dark-theme");
    el.classList.add(theme === "dark" ? "dark-theme" : "light-theme");
  }
  if (typeof localStorage !== "undefined") {
    try {
      localStorage.setItem(STORAGE_KEY, theme);
    } catch {
      /* ignore */
    }
  }
}

let started = false;
/** Call once at app start to sync <html> with the store. Idempotent. */
export function initTheme(): void {
  if (started) return;
  started = true;
  apply($theme.getState());
  $theme.watch(apply);
}

/** Reactive theme value for components. */
export const useTheme = (): Theme => useUnit($theme);
