import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import { initOverlayLock, initTheme } from "@mercury/effector";
import { App } from "./App";
import "./showcase.css";

// Sync <html> with the theme store once, and start the global overlay-stack
// body-scroll-lock singleton the overlay demo drives (both idempotent — the
// initTheme idiom from apps/mobile). The @mercury/ui barrel side-effect-imports
// styles/index.css via App's component imports, so tokens + .mx-* are already
// loaded; showcase.css layers the app chrome on top.
initTheme();
initOverlayLock();

createRoot(document.getElementById("root")!).render(
  <StrictMode>
    <App />
  </StrictMode>,
);
