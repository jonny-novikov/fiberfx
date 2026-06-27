import { Link } from "@mercury/ui";
import { toast } from "@mercury/effector";
import { Page, PageHead, Section } from "../../chrome/Page";
import { Demo } from "../../chrome/Demo";
import { PropsTable } from "../../chrome/PropsTable";

export function LinkPage() {
  return (
    <Page>
      <PageHead
        eyebrow="Components"
        title="Link"
        lede="The inline text affordance for navigation and in-app actions. Renders an <a> when href is set, otherwise a <button>."
      />

      <Section title="Sizes" />
      <Demo
        code={`<Link href="#">Default link</Link>
<Link href="#" size="sm">Small link</Link>`}
      >
        <Link href="#">Default link</Link>
        <Link href="#" size="sm">
          Small link
        </Link>
      </Demo>

      <Section title="Muted" hint="Tertiary colour for secondary affordances." />
      <Demo
        code={`<Link href="#" muted>Privacy policy</Link>`}
      >
        <Link href="#" muted>
          Privacy policy
        </Link>
      </Demo>

      <Section title="With icons" hint="Leading / trailing slots for arrows and glyphs." />
      <Demo
        code={`<Link leading={<span aria-hidden>←</span>}>Back to sign in</Link>
<Link trailing={<span aria-hidden>→</span>}>Continue</Link>`}
      >
        <Link leading={<span aria-hidden="true">←</span>}>Back to sign in</Link>
        <Link trailing={<span aria-hidden="true">→</span>}>Continue</Link>
      </Demo>

      <Section title="As a button" hint="No href → a <button> for in-app actions." />
      <Demo
        code={`<Link onClick={() => toast.info("Resending code…")}>Resend code</Link>
<Link disabled>Resend in 28s</Link>`}
      >
        <Link onClick={() => toast.info("Resending code…")}>Resend code</Link>
        <Link disabled>Resend in 28s</Link>
      </Demo>

      <Section title="API" />
      <PropsTable
        rows={[
          { prop: "href", type: "string", desc: "When set, renders an <a>; otherwise a <button>." },
          { prop: "onClick", type: "(e) => void", desc: "Click handler (button mode or anchor)." },
          { prop: "size", type: '"sm" | "md"', default: '"md"', desc: "Text size." },
          { prop: "muted", type: "boolean", default: "false", desc: "Tertiary colour instead of brand." },
          { prop: "disabled", type: "boolean", default: "false", desc: "Non-interactive; forces button mode." },
          { prop: "leading / trailing", type: "ReactNode", desc: "Content before / after the label." },
          { prop: "type", type: '"button" | "submit" | "reset"', default: '"button"', desc: "Button type when in button mode." },
        ]}
      />
    </Page>
  );
}
