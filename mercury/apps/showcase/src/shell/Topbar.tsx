type TopbarProps = {
  crumb: string;
  theme: "light" | "dark";
  onToggleTheme: () => void;
};

export function Topbar({ crumb, theme, onToggleTheme }: TopbarProps) {
  return (
    <header className="showcase-topbar">
      <span className="showcase-crumb">{crumb}</span>
      <button type="button" className="showcase-tb-btn" onClick={onToggleTheme}>
        {theme === "dark" ? "Light theme" : "Dark theme"}
      </button>
    </header>
  );
}
