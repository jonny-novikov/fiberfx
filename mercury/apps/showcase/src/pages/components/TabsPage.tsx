import { useState } from "react";
import { Tabs } from "@mercury/ui";
import { Page, PageHead, Section } from "../../chrome/Page";
import { Demo } from "../../chrome/Demo";

type UnderlineTab = "overview" | "activity" | "settings" | "billing";
type PillTab = "daily" | "weekly" | "monthly";

export function TabsPage() {
  const [active, setActive] = useState<UnderlineTab>("overview");
  const [range, setRange] = useState<PillTab>("daily");

  return (
    <Page>
      <PageHead
        eyebrow="Components"
        title="Tabs"
        lede="Two variants: underline for page-level navigation, pills for compact view toggles."
      />

      <Section title="Underline" />
      <Demo layout="col">
        <Tabs<UnderlineTab>
          tabs={[
            { label: "Overview", value: "overview" },
            { label: "Activity", value: "activity" },
            { label: "Settings", value: "settings" },
            { label: "Billing", value: "billing" },
          ]}
          value={active}
          onChange={setActive}
        />
        <div style={{ padding: "20px 0 0", color: "rgb(var(--fg-secondary))" }}>
          Content for <strong style={{ color: "rgb(var(--fg-primary))" }}>{active}</strong>.
        </div>
      </Demo>

      <Section title="Pills" />
      <Demo>
        <Tabs<PillTab>
          variant="pills"
          tabs={[
            { label: "Daily", value: "daily" },
            { label: "Weekly", value: "weekly" },
            { label: "Monthly", value: "monthly" },
          ]}
          value={range}
          onChange={setRange}
        />
      </Demo>
    </Page>
  );
}
