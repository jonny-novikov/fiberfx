import "./showcase.css";

import { createRoot } from "react-dom/client";
import { App } from "./App";

// Boot-apply the persisted theme before mount, so first paint carries the class (no flash).
const bootTheme = localStorage.getItem("mx-showcase.theme.v1") === "dark" ? "dark-theme" : "light-theme";
document.documentElement.classList.remove("light-theme", "dark-theme");
document.documentElement.classList.add(bootTheme);

createRoot(document.getElementById("root")!).render(<App />);
