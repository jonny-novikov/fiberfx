import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import { initTheme, setTheme } from "@mercury/effector";
import { App } from "./App";

// EchoMQ defaults to dark.
initTheme();
if (!localStorage.getItem("mercury-theme")) setTheme("dark");

createRoot(document.getElementById("root")!).render(
  <StrictMode>
    <App />
  </StrictMode>,
);
