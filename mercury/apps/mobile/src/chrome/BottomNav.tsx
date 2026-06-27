import type { ComponentType } from "react";
import { HomeIcon, ListIcon, SendIcon, UserIcon, WalletIcon } from "../icons";
import { setTab, startSend, useSending, useTab } from "../store";
import type { Screen, Tab } from "../store";

type NavItem = { id: Screen; label: string; Icon: ComponentType<{ size?: number }>; onSelect: () => void };

const ITEMS: NavItem[] = [
  { id: "home", label: "Home", Icon: HomeIcon, onSelect: () => setTab("home") },
  { id: "activity", label: "Activity", Icon: ListIcon, onSelect: () => setTab("activity") },
  { id: "send", label: "Send", Icon: SendIcon, onSelect: () => startSend() },
  { id: "wallet", label: "Wallet", Icon: WalletIcon, onSelect: () => setTab("wallet") },
  { id: "profile", label: "Profile", Icon: UserIcon, onSelect: () => setTab("profile") },
];

export function BottomNav() {
  const tab = useTab();
  const sending = useSending();
  const active: Screen = sending ? "send" : (tab as Tab);
  return (
    <nav className="em-bottomnav">
      {ITEMS.map(({ id, label, Icon, onSelect }) => (
        <button key={id} className={`em-tab${active === id ? " is-active" : ""}`} onClick={onSelect}>
          <Icon size={20} />
          <span>{label}</span>
        </button>
      ))}
    </nav>
  );
}
