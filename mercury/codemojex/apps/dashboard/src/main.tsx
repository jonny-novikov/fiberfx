import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import { initTheme, setTheme } from "@mercury/effector";
import { App } from "./App";
import "./dashboard.css";

// The operator console is a dark-first dashboard — default to dark unless the
// visitor has already chosen a theme (persisted by @mercury/effector).
if (typeof localStorage !== "undefined" && !localStorage.getItem("mercury-theme")) setTheme("dark");
initTheme();

createRoot(document.getElementById("root")!).render(
  <StrictMode>
    <App />
  </StrictMode>,
);
