import { useState } from "react";
import { Switch, Checkbox, Radio, Segmented } from "@mercury/ui";
import { Page, PageHead, Section } from "../../chrome/Page";
import { Demo } from "../../chrome/Demo";

export function SelectionPage() {
  const [notifications, setNotifications] = useState(true);
  const [digest, setDigest] = useState(false);
  const [remember, setRemember] = useState(true);
  const [updates, setUpdates] = useState(false);
  const [billing, setBilling] = useState("monthly");
  const [period, setPeriod] = useState<string>("week");

  return (
    <Page>
      <PageHead
        eyebrow="Components"
        title="Selection"
        lede="Switches, checkboxes, radios and segmented controls — the controls that capture user intent."
      />

      <Section title="Switch" />
      <Demo
        layout="row"
        code={`<Switch label="Notifications" checked={on} onChange={setOn} />`}
      >
        <Switch label="Notifications" checked={notifications} onChange={setNotifications} />
        <Switch label="Email digest" checked={digest} onChange={setDigest} />
      </Demo>

      <Section title="Checkbox" />
      <Demo layout="col">
        <Checkbox
          label="Remember this device for 30 days"
          checked={remember}
          onChange={setRemember}
        />
        <Checkbox
          label="Send me product updates"
          checked={updates}
          onChange={setUpdates}
        />
        <Checkbox label="Can't change this" disabled />
      </Demo>

      <Section title="Radio group" />
      <Demo layout="col">
        <Radio
          name="billing"
          value="monthly"
          label="Monthly"
          checked={billing === "monthly"}
          onChange={setBilling}
        />
        <Radio
          name="billing"
          value="quarterly"
          label="Quarterly"
          checked={billing === "quarterly"}
          onChange={setBilling}
        />
        <Radio
          name="billing"
          value="yearly"
          label="Yearly — save 20%"
          checked={billing === "yearly"}
          onChange={setBilling}
        />
      </Demo>

      <Section title="Segmented control" />
      <Demo layout="row">
        <Segmented<string>
          segments={[
            { label: "Day", value: "day" },
            { label: "Week", value: "week" },
            { label: "Month", value: "month" },
            { label: "Year", value: "year" },
          ]}
          value={period}
          onChange={setPeriod}
        />
      </Demo>
    </Page>
  );
}
