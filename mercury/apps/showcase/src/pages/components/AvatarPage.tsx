import { Avatar } from "@mercury/ui";
import { Page, PageHead, Section } from "../../chrome/Page";
import { Demo } from "../../chrome/Demo";
import { PropsTable } from "../../chrome/PropsTable";

const NAMES = [
  "Grace Hopper",
  "Margaret Hamilton",
  "Katherine Johnson",
  "Alan Turing",
  "Linus Torvalds",
  "Radia Perlman",
  "Donald Knuth",
];

export function AvatarPage() {
  return (
    <Page>
      <PageHead
        eyebrow="Components"
        title="Avatar"
        lede="Identify people. Falls back to colored initials when no image is supplied."
      />

      <Section title="Sizes" />
      <Demo
        code={`<Avatar name="Ada Lovelace" size={24} />
<Avatar name="Ada Lovelace" size={40} />
<Avatar name="Ada Lovelace" size={80} />`}
      >
        {[24, 32, 40, 56, 80].map((size) => (
          <Avatar key={size} name="Ada Lovelace" size={size} />
        ))}
      </Demo>

      <Section title="Color by name" />
      <Demo>
        {NAMES.map((name) => (
          <div
            key={name}
            style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 6 }}
          >
            <Avatar name={name} size={48} />
            <span style={{ font: "500 11px/1 var(--font-primary)", color: "rgb(var(--fg-secondary))" }}>
              {name.split(" ")[0]}
            </span>
          </div>
        ))}
      </Demo>

      <Section title="With presence" />
      <Demo>
        <Avatar name="Grace Hopper" size={48} status="positive" />
        <Avatar name="Alan Turing" size={48} status="caution" />
        <Avatar name="Ada Lovelace" size={48} status="negative" />
        <Avatar name="Radia Perlman" size={48} status="info" />
      </Demo>

      <Section title="API" />
      <PropsTable
        rows={[
          { prop: "name", type: "string", desc: "Derives the initials and a hashed background hue." },
          { prop: "src", type: "string", desc: "Image URL; replaces the initials fallback." },
          { prop: "size", type: "number", default: "40", desc: "Width and height in pixels." },
          { prop: "status", type: "positive | caution | negative | info", desc: "Presence dot in the corner." },
        ]}
      />
    </Page>
  );
}
