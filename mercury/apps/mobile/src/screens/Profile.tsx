import { Button, Card } from "@mercury/ui";
import { Row } from "../chrome/Row";
import { BellIcon, CardIcon, GlobeIcon, HelpIcon, ShieldIcon } from "../icons";
import { logout } from "../store";

export function Profile() {
  return (
    <div className="em-screen">
      <div className="em-profile-h">
        <div className="em-avatar em-avatar-xl">SR</div>
        <div>
          <div style={{ font: "700 18px/24px var(--font-primary)" }}>Sam Reyes</div>
          <div style={{ font: "400 13px/18px var(--font-primary)", color: "rgb(var(--fg-secondary))" }}>Verified · Member since 2023</div>
        </div>
      </div>
      <Card padding={0} style={{ overflow: "hidden" }}>
        <Row icon={<ShieldIcon size={20} />} label="Security" />
        <Row icon={<CardIcon size={20} />} label="Payment methods" value="3" />
        <Row icon={<BellIcon size={20} />} label="Notifications" />
        <Row icon={<GlobeIcon size={20} />} label="Language" value="English" />
        <Row icon={<HelpIcon size={20} />} label="Help" />
      </Card>
      <div style={{ marginTop: 20, display: "flex" }}>
        <Button variant="ghost" size="lg" style={{ color: "rgb(var(--fg-negative))" }} onClick={() => logout()}>
          Sign out
        </Button>
      </div>
    </div>
  );
}
