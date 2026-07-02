import { Button } from "@mercury/ui";

type TopbarProps = {
  theme: "light" | "dark";
  onToggleTheme: () => void;
};

export function Topbar({ theme, onToggleTheme }: TopbarProps) {
  return (
    <header className="showcase-topbar">
      <h1 className="showcase-title">Mercury Showcase</h1>
      <Button variant="outline" size="sm" onClick={onToggleTheme}>
        {theme === "dark" ? "Light theme" : "Dark theme"}
      </Button>
    </header>
  );
}
