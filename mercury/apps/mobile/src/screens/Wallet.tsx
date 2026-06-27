import { Card } from "@mercury/ui";
import { Balance } from "../chrome/Balance";
import { Row } from "../chrome/Row";
import { CardIcon, PlusIcon } from "../icons";

export function Wallet() {
  return (
    <div className="em-screen">
      <Balance />
      <div className="em-section-h">
        <span>Cards</span>
      </div>
      <Card padding={0} style={{ overflow: "hidden" }}>
        <Row icon={<CardIcon size={20} />} label="Visa ••4921" value="Primary" />
        <Row icon={<CardIcon size={20} />} label="Mastercard ••7788" />
        <Row icon={<PlusIcon size={20} />} label="Add payment method" />
      </Card>
    </div>
  );
}
