import { Toaster } from "@mercury/effector";
import { StatusBar } from "./chrome/StatusBar";
import { Header } from "./chrome/Header";
import { BottomNav } from "./chrome/BottomNav";
import { Login } from "./screens/Login";
import { Home } from "./screens/Home";
import { Activity } from "./screens/Activity";
import { Wallet } from "./screens/Wallet";
import { Profile } from "./screens/Profile";
import { Send } from "./screens/Send";
import { useAuthed, useSending, useTab } from "./store";
import type { Tab } from "./store";

function Screen({ tab }: { tab: Tab }) {
  switch (tab) {
    case "activity":
      return <Activity />;
    case "wallet":
      return <Wallet />;
    case "profile":
      return <Profile />;
    case "home":
    default:
      return <Home />;
  }
}

export function App() {
  const authed = useAuthed();
  const sending = useSending();
  const tab = useTab();
  return (
    <div className="em-frame-wrap">
      <div className="em-phone">
        <StatusBar />
        {authed ? (
          <>
            <Header />
            <div className="em-body">{sending ? <Send /> : <Screen tab={tab} />}</div>
            <BottomNav />
          </>
        ) : (
          <Login />
        )}
      </div>
      <div className="em-caption">Mercury App · interactive click-through · tap the bottom tabs</div>
      <Toaster position="bottom-center" />
    </div>
  );
}
