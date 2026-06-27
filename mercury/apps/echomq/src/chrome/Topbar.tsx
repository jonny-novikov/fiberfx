import { Button, Icon, Segmented } from "@mercury/ui";
import { toggleTheme, useTheme } from "@mercury/effector";
import { setRun, useRun, useSelected } from "../store";
import type { Run } from "../store";

/* The half-fill swatch that marks the theme toggle. */
function ThemeSwatch() {
  return (
    <span
      style={{
        width: 13,
        height: 13,
        borderRadius: "50%",
        border: "1.5px solid currentColor",
        background: "linear-gradient(90deg, currentColor 0 50%, transparent 50% 100%)",
      }}
    />
  );
}

export function Topbar() {
  const selected = useSelected();
  const run = useRun();
  const theme = useTheme();

  return (
    <header className="eqd-top">
      <div className="eqd-title">
        <h2>{selected}</h2>
        <p>
          EchoMQ Bus v8.4.0 · connected as <span>admin</span>
        </p>
      </div>
      <div style={{ flex: 1 }} />

      <Segmented<Run>
        segments={[
          { label: "Paused", value: "paused" },
          { label: "Running", value: "running" },
        ]}
        value={run}
        onChange={setRun}
        size="sm"
      />
      <Button variant="ghost" className="eqd-iconbtn" aria-label="Refresh" title="Refresh" leading={<Icon name="refresh" size={17} />} />
      <Button variant="ghost" className="eqd-iconbtn" aria-label="Duplicate queue" title="Duplicate queue" leading={<Icon name="copy" size={17} />} />
      <Button variant="ghost" className="eqd-iconbtn" aria-label="Delete queue" title="Delete queue" leading={<Icon name="trash" size={17} />} />
      <Button variant="secondary" onClick={() => toggleTheme()} leading={<ThemeSwatch />}>
        {theme === "dark" ? "Dark" : "Light"}
      </Button>
    </header>
  );
}
