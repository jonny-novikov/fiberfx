import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import { initTheme } from "@mercury/effector";
import { App } from "./App";
import "./mobile.css";

// The mobile mock is light-first; the plug defaults to light and honours any
// theme the visitor has already chosen.
initTheme();

createRoot(document.getElementById("root")!).render(
  <StrictMode>
    <App />
  </StrictMode>,
);
