import type { ComponentType } from "react";
import { Balance } from "../chrome/Balance";
import { ActivityList } from "../chrome/ActivityList";
import { ConvertIcon, PlusIcon, ReceiveIcon, SendIcon } from "../icons";
import { setTab, startSend } from "../store";
import { HOME_ACTIVITY } from "../data";

type Quick = { label: string; Icon: ComponentType<{ size?: number }>; onClick?: () => void };

const QUICK: Quick[] = [
  { label: "Send", Icon: SendIcon, onClick: () => startSend() },
  { label: "Receive", Icon: ReceiveIcon },
  { label: "Top up", Icon: PlusIcon },
  { label: "Convert", Icon: ConvertIcon },
];

export function Home() {
  return (
    <div className="em-screen">
      <Balance />
      <div className="em-quick-row">
        {QUICK.map(({ label, Icon, onClick }) => (
          <button className="em-quick" key={label} onClick={onClick}>
            <span className="em-quick-ic">
              <Icon size={22} />
            </span>
            <span className="em-quick-lbl">{label}</span>
          </button>
        ))}
      </div>
      <div className="em-section-h">
        <span>Recent activity</span>
        <a onClick={() => setTab("activity")}>See all</a>
      </div>
      <ActivityList rows={HOME_ACTIVITY} />
    </div>
  );
}
