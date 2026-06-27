import { MenuIcon, UserIcon } from "../icons";
import { setTab, useSending, useTab } from "../store";
import { SCREEN_TITLES } from "../data";

export function Header() {
  const tab = useTab();
  const sending = useSending();
  const title = SCREEN_TITLES[sending ? "send" : tab];
  return (
    <div className="em-header">
      <button className="em-iconbtn" aria-label="Menu">
        <MenuIcon />
      </button>
      <div className="em-header-title">{title}</div>
      <button className="em-iconbtn" aria-label="Profile" onClick={() => setTab("profile")}>
        <UserIcon />
      </button>
    </div>
  );
}
