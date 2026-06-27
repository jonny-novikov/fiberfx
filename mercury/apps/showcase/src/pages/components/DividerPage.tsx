import { Divider } from "@mercury/ui";
import { Page, PageHead, Section } from "../../chrome/Page";
import { Demo } from "../../chrome/Demo";
import { PropsTable } from "../../chrome/PropsTable";

export function DividerPage() {
  return (
    <Page>
      <PageHead
        eyebrow="Components"
        title="Divider"
        lede="A separator rule. With a label it becomes the “— or —” splitter between a primary and an alternate action."
      />

      <Section title="Plain" />
      <Demo layout="col" code={`<Divider />`}>
        <div style={{ width: "100%" }}>
          <Divider />
        </div>
      </Demo>

      <Section title="Labelled" />
      <Demo layout="col" code={`<Divider label="or" />`}>
        <div style={{ width: "100%" }}>
          <Divider label="or" />
        </div>
        <div style={{ width: "100%" }}>
          <Divider label="or continue with email" />
        </div>
      </Demo>

      <Section title="Vertical" hint="Inline, fills the height of its row." />
      <Demo
        code={`<span>Drafts</span>
<Divider orientation="vertical" />
<span>Sent</span>`}
      >
        <div style={{ display: "flex", alignItems: "center", gap: 12, height: 20 }}>
          <span style={{ font: "500 13px/1 var(--font-primary)", color: "rgb(var(--fg-secondary))" }}>Drafts</span>
          <Divider orientation="vertical" />
          <span style={{ font: "500 13px/1 var(--font-primary)", color: "rgb(var(--fg-secondary))" }}>Sent</span>
          <Divider orientation="vertical" />
          <span style={{ font: "500 13px/1 var(--font-primary)", color: "rgb(var(--fg-secondary))" }}>Archived</span>
        </div>
      </Demo>

      <Section title="API" />
      <PropsTable
        rows={[
          { prop: "label", type: "ReactNode", desc: "Centred label; turns the rule into a splitter." },
          { prop: "orientation", type: '"horizontal" | "vertical"', default: '"horizontal"', desc: "Rule direction." },
          { prop: "className", type: "string", desc: "Extra classes on the root." },
        ]}
      />
    </Page>
  );
}
