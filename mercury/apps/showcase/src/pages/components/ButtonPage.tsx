import { Button, Icon } from "@mercury/ui";
import { Page, PageHead, Section } from "../../chrome/Page";
import { Demo } from "../../chrome/Demo";
import { PropsTable } from "../../chrome/PropsTable";

export function ButtonPage() {
  return (
    <Page>
      <PageHead
        eyebrow="Components"
        title="Button"
        lede="The primary call to action in every product surface. Variants express intent, sizes express density."
      />

      <Section title="Variants" />
      <Demo
        code={`<Button variant="primary">Continue</Button>
<Button variant="secondary">Cancel</Button>
<Button variant="outline">Outline</Button>
<Button variant="ghost">Ghost</Button>
<Button variant="destructive">Delete</Button>
<Button variant="inverse">Inverse</Button>`}
      >
        <Button>Continue</Button>
        <Button variant="secondary">Cancel</Button>
        <Button variant="outline">Outline</Button>
        <Button variant="ghost">Ghost</Button>
        <Button variant="destructive">Delete</Button>
        <Button variant="inverse">Inverse</Button>
      </Demo>

      <Section title="Sizes" />
      <Demo>
        <Button size="sm">Small</Button>
        <Button size="md">Medium</Button>
        <Button size="lg">Large</Button>
      </Demo>

      <Section title="With icons" />
      <Demo>
        <Button leading={<Icon name="download" size={14} />}>Download</Button>
        <Button variant="secondary" trailing={<Icon name="arrow" size={14} />}>
          Continue
        </Button>
        <Button variant="ghost" leading={<Icon name="plus" size={14} />}>
          New project
        </Button>
      </Demo>

      <Section title="Disabled & loading" />
      <Demo>
        <Button disabled>Primary</Button>
        <Button variant="secondary" disabled>
          Secondary
        </Button>
        <Button loading>Saving…</Button>
      </Demo>

      <Section title="API" />
      <PropsTable
        rows={[
          { prop: "variant", type: "primary | secondary | outline | ghost | destructive | inverse", default: "primary", desc: "Visual weight and semantic intent." },
          { prop: "size", type: "sm | md | lg", default: "md", desc: "Control height and padding." },
          { prop: "leading", type: "ReactNode", desc: "Icon or element before the label." },
          { prop: "trailing", type: "ReactNode", desc: "Icon or element after the label." },
          { prop: "loading", type: "boolean", default: "false", desc: "Swap the label for a spinner and disable interaction." },
          { prop: "fullWidth", type: "boolean", default: "false", desc: "Stretch to container width." },
          { prop: "disabled", type: "boolean", default: "false", desc: "Disables all interaction." },
        ]}
      />
    </Page>
  );
}
