import * as React from 'react';

// Shared presentational view for the dedicated per-screen stories (Rooms / Game /
// Golden Game). A phone-framed reference render beside a metadata panel. The PNG
// is STATIC reference (served from the gameplay staticDir at /gameplay/<file>);
// the chrome around it — the tokens, the golden badge, any live CTA a story adds
// as children — is live and recolors with the Theme toolbar.

export type Screen = {
  figma_id: string;
  figma_label: string;
  figma_type: string;
  url: string;
  role: string;
  game_state: string;
  mode: string;
  entities: string[];
  doc: string;
  isGolden: boolean;
};

function MetaRow({ label, value }: { label: string; value: React.ReactNode }) {
  return (
    <div style={{ display: 'flex', gap: 8, fontSize: 12, lineHeight: 1.6 }}>
      <span style={{ opacity: 0.55, minWidth: 84 }}>{label}</span>
      <span style={{ fontWeight: 600 }}>{value}</span>
    </div>
  );
}

// A device-framed screen render. The bezel goes gold for a boost-class screen so
// the frame itself carries the --gradient-gold token.
export function PhoneFrame({
  screen,
  width = 300,
  golden = false,
}: {
  screen: Screen;
  width?: number;
  golden?: boolean;
}) {
  return (
    <figure style={{ margin: 0, flexShrink: 0 }}>
      <div
        style={{
          width: width + 14,
          padding: 7,
          borderRadius: width * 0.12,
          background: golden ? 'var(--gradient-gold)' : '#0d0f12',
          boxShadow: '0 16px 38px rgba(0,0,0,0.26)',
        }}
      >
        <div style={{ borderRadius: width * 0.09, overflow: 'hidden', background: '#000' }}>
          <img
            src={screen.url}
            alt={screen.figma_label}
            loading="lazy"
            style={{ display: 'block', width, height: 'auto' }}
          />
        </div>
      </div>
    </figure>
  );
}

// The hero layout: a framed render + a metadata panel. `children` is the slot for
// per-screen extras (a live themed CTA, a boost note).
export function ScreenView({
  screen,
  golden = false,
  width = 300,
  children,
}: {
  screen: Screen;
  golden?: boolean;
  width?: number;
  children?: React.ReactNode;
}) {
  return (
    <div
      className="font-sans"
      style={{ display: 'flex', gap: 28, flexWrap: 'wrap', alignItems: 'flex-start' }}
    >
      <PhoneFrame screen={screen} golden={golden} width={width} />
      <div style={{ maxWidth: 400, color: 'var(--color-dark-muted)' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 4 }}>
          <h2 style={{ margin: 0, fontSize: 20 }}>{screen.figma_label}</h2>
          {golden && (
            <span
              style={{
                background: 'var(--gradient-gold)',
                color: 'var(--color-gold-foreground)',
                fontSize: 10,
                fontWeight: 700,
                padding: '2px 8px',
                borderRadius: 999,
              }}
            >
              BOOST CLASS
            </span>
          )}
        </div>
        <code style={{ fontSize: 11, opacity: 0.6 }}>
          {screen.figma_id} · {screen.figma_type}
        </code>
        <p style={{ fontSize: 13, margin: '10px 0 14px', opacity: 0.9 }}>{screen.role}</p>
        <MetaRow label="game_state" value={screen.game_state} />
        <MetaRow label="mode" value={screen.mode} />
        <MetaRow label="entities" value={screen.entities.join(' · ')} />
        <MetaRow label="doc" value={<code style={{ fontSize: 11 }}>{screen.doc}</code>} />
        {children && <div style={{ marginTop: 16 }}>{children}</div>}
      </div>
    </div>
  );
}

// A small note that a nearby live element recolors with the toolbar — the bridge
// between the static screen render and the live themeable accent.
export function ThemeNote({ children }: { children: React.ReactNode }) {
  return <div style={{ fontSize: 11, opacity: 0.6, marginTop: 6 }}>{children}</div>;
}
