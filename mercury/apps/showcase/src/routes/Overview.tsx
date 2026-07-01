import { Card, Heading, Icon, type IconName, Text } from "@mercury/ui";

// Overview — what Mercury is, the @mercury/* package split, and theming. Pure
// composition of @mercury/ui primitives (Heading · Text · Card · Icon); the
// grid + eyebrow are app-local chrome (sc-*), never a reusable component.

const PACKAGES: { icon: IconName; name: string; role: string }[] = [
  {
    icon: "bolt",
    name: "@mercury/core",
    role: "UI-free foundation — headless hooks, the cx classlist helper, locale-aware date formatters, shared types. Zero JSX.",
  },
  {
    icon: "star",
    name: "@mercury/ui",
    role: "The component library — token-driven, presentational React components grouped by role (actions · inputs · overlay · …). Tokens live here.",
  },
  {
    icon: "flow",
    name: "@mercury/effector",
    role: "Effector state adapters — theme, toast, form, and the overlay disclosure bridge. Components stay presentational; the adapter wires state from the outside.",
  },
];

export function Overview() {
  return (
    <>
      <Text className="sc-eyebrow">Mercury design system</Text>
      <Heading size={9} className="sc-title">
        A token-driven React design system
      </Heading>
      <Text variant="lead" className="sc-lede">
        Mercury is a presentational component library where every surface — colour, type, radius,
        elevation, motion — flows from CSS custom properties. Swap a theme or rebrand one variable
        deep. This showcase composes the packages from source; it houses no reusable component.
      </Text>

      <div className="sc-section-head">
        <Heading size={5} as="h2">
          The packages
        </Heading>
      </div>
      <div className="sc-cards">
        {PACKAGES.map((p) => (
          <Card key={p.name} variant="raised" className="sc-pkg-card">
            <div className="sc-pkg-icon" aria-hidden>
              <Icon name={p.icon} size={20} />
            </div>
            <Heading size={3} as="h3">
              {p.name}
            </Heading>
            <Text variant="small">{p.role}</Text>
          </Card>
        ))}
      </div>

      <div className="sc-section-head">
        <Heading size={5} as="h2">
          Theming
        </Heading>
      </div>
      <Card variant="flat" className="sc-note">
        <Text>
          The <code>@mercury/effector</code> theme adapter flips a <code>.light-theme</code> /
          <code> .dark-theme</code> class on <code>&lt;html&gt;</code>; every token re-resolves and the
          whole surface follows. Use the toggle in the topbar — nothing here reads a colour from
          JavaScript.
        </Text>
      </Card>
    </>
  );
}
