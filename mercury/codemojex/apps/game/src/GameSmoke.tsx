// The dev-flagged foundation probe (cmt.4.1-D7). Rendered by index.tsx ONLY under
// VITE_GAME_SMOKE=1 (off by default) — it is not a game screen; it exercises every
// foundation layer at once: Tailwind utilities resolve, the ported tokens ride,
// cn() merges, and t() returns a bundled locale string.
import { useTranslation } from "react-i18next";
import { cn } from "@/lib/cn";
import "@/i18n/i18n";

// The board's "All Screen Fill" — the exact root paint of the Classic BoardScreen
// (node/codemoji-design/stories/board/BoardScreen.tsx, SCREEN_FILL).
const SCREEN_FILL =
  "linear-gradient(180deg, var(--color-bg-app-from), var(--color-bg-app-to))";

export function GameSmoke() {
  const { t } = useTranslation();
  return (
    <div
      className={cn("cmjx-game font-sans overflow-hidden rounded-2xl")}
      style={{ background: SCREEN_FILL }}
    >
      <div className="bg-card p-4 text-primary">
        <span className="text-2xs font-bold">{t("smoke.ping")}</span>
      </div>
    </div>
  );
}
