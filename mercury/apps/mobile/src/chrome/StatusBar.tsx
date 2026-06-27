import { BatteryIcon, SignalIcon, WifiIcon } from "../icons";

export function StatusBar() {
  return (
    <div className="em-statusbar">
      <span>9:41</span>
      <span className="em-statusbar-r">
        <SignalIcon />
        <WifiIcon />
        <BatteryIcon />
      </span>
    </div>
  );
}
