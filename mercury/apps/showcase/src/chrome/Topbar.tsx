import { Button, Icon, Segmented } from "@mercury/ui";
import { setTheme, toast, useTheme } from "@mercury/effector";
import type { Theme } from "@mercury/effector";
import { crumb } from "../nav";
import { useRoute } from "../store";

export function Topbar() {
  const route = useRoute();
  const theme = useTheme();
  return (
    <header className="topbar">
      <div className="crumb">{crumb(route)}</div>
      <div style={{ flex: 1 }} />
      <Button variant="ghost" size="sm" leading={<Icon name="star" size={14} />} onClick={() => toast.success("Thanks for the star!")}>
        Star
      </Button>
      <Segmented<Theme>
        segments={[
          { label: "Light", value: "light" },
          { label: "Dark", value: "dark" },
        ]}
        value={theme}
        onChange={setTheme}
        size="sm"
      />
    </header>
  );
}
