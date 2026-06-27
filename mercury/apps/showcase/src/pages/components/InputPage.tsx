import { Input, Icon } from "@mercury/ui";
import { Page, PageHead, Section } from "../../chrome/Page";
import { Demo } from "../../chrome/Demo";
import { PropsTable } from "../../chrome/PropsTable";

export function InputPage() {
  return (
    <Page>
      <PageHead
        eyebrow="Components"
        title="Input"
        lede="Single-line text entry with label, hint, validation state and optional adornments."
      />

      <Section title="Basic" />
      <Demo layout="col" code={`<Input label="Email" placeholder="you@company.com" />`}>
        <div style={{ maxWidth: 340, width: "100%" }}>
          <Input label="Email" type="email" placeholder="you@company.com" />
        </div>
      </Demo>

      <Section title="With adornment" />
      <Demo layout="col">
        <div style={{ maxWidth: 340, width: "100%" }}>
          <Input
            type="search"
            placeholder="Search documentation"
            leading={<Icon name="search" size={14} />}
          />
        </div>
      </Demo>

      <Section title="States" />
      <Demo layout="col">
        <div style={{ maxWidth: 340, width: "100%" }}>
          <Input label="Workspace" placeholder="acme" hint="3–32 characters" />
        </div>
        <div style={{ maxWidth: 340, width: "100%" }}>
          <Input
            label="Subdomain"
            defaultValue="mercury"
            error="That subdomain is already taken"
          />
        </div>
        <div style={{ maxWidth: 340, width: "100%" }}>
          <Input label="Locked" defaultValue="read-only value" disabled />
        </div>
      </Demo>

      <Section title="API" />
      <PropsTable
        rows={[
          { prop: "label", type: "string", desc: "Text label above the field." },
          { prop: "hint", type: "string", desc: "Helper copy below; colors red when invalid." },
          { prop: "error", type: "string", desc: "Error state; red border + ring on focus." },
          { prop: "leading", type: "ReactNode", desc: "Prefix, usually an icon." },
          { prop: "trailing", type: "ReactNode", desc: "Suffix element." },
          { prop: "disabled", type: "boolean", default: "false", desc: "Read-only, faded." },
        ]}
      />
    </Page>
  );
}
