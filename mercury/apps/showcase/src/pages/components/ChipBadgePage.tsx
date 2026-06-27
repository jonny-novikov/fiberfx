import { Chip, Badge } from "@mercury/ui";
import { toast } from "@mercury/effector";
import { Page, PageHead, Section } from "../../chrome/Page";
import { Demo } from "../../chrome/Demo";
import { PropsTable } from "../../chrome/PropsTable";

export function ChipBadgePage() {
  return (
    <Page>
      <PageHead
        eyebrow="Components"
        title="Chip & Badge"
        lede="Compact labels for status, filters, tags and counts."
      />

      <Section title="Chip variants" />
      <Demo
        code={`<Chip>Neutral</Chip>
<Chip variant="brand">Pro</Chip>
<Chip variant="positive">Live</Chip>`}
      >
        <Chip>Neutral</Chip>
        <Chip variant="brand">Pro</Chip>
        <Chip variant="positive">Live</Chip>
        <Chip variant="negative">Blocked</Chip>
        <Chip variant="caution">Pending</Chip>
        <Chip variant="info">Info</Chip>
        <Chip variant="discovery">Beta</Chip>
      </Demo>

      <Section title="Sizes" />
      <Demo>
        <Chip variant="brand" size="sm">
          Small
        </Chip>
        <Chip variant="brand" size="md">
          Medium
        </Chip>
        <Chip variant="brand" size="lg">
          Large
        </Chip>
      </Demo>

      <Section title="Removable & selectable" />
      <Demo>
        <Chip onRemove={() => toast.info("Removed")}>design</Chip>
        <Chip onRemove={() => toast.info("Removed")}>tokens</Chip>
        <Chip selected onClick={() => {}}>
          Active filter
        </Chip>
      </Demo>

      <Section title="Badge (count pills)" />
      <Demo>
        <Badge variant="negative">3</Badge>
        <Badge variant="caution">12</Badge>
        <Badge variant="positive">Done</Badge>
        <Badge variant="brand">New</Badge>
        <Badge variant="info">i</Badge>
      </Demo>

      <Section title="Chip API" />
      <PropsTable
        rows={[
          { prop: "variant", type: "neutral | brand | positive | negative | caution | info | discovery", default: "neutral", desc: "Semantic color of the chip." },
          { prop: "size", type: "sm | md | lg", default: "md", desc: "Control height and padding." },
          { prop: "selected", type: "boolean", default: "false", desc: "Render in the selected (filter-active) state." },
          { prop: "leading", type: "ReactNode", desc: "Icon or element before the label." },
          { prop: "onRemove", type: "() => void", desc: "Show a remove affordance and fire on click." },
          { prop: "onClick", type: "() => void", desc: "Make the chip interactive." },
        ]}
      />

      <Section title="Badge API" />
      <PropsTable
        rows={[
          { prop: "variant", type: "brand | negative | positive | caution | info", default: "negative", desc: "Semantic color of the badge." },
          { prop: "size", type: "sm | md | lg", default: "md", desc: "Control height and padding." },
        ]}
      />
    </Page>
  );
}
