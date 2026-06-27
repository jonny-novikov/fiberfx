import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import { initTheme } from "@mercury/effector";
import { App } from "./App";
import "./showcase.css";

initTheme();

createRoot(document.getElementById("root")!).render(
  <StrictMode>
    <App />
  </StrictMode>,
);
