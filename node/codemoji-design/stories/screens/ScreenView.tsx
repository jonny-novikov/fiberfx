import * as React from 'react';

// Shared presentational views for the dedicated per-screen stories (Rooms / Game /
// Golden Game). The hero is a DRIFT VIEW: the screen rebuilt LIVE from the design
// system on the LEFT (real components — theme-aware, role-colored CTAs) beside the
// Figma reference export on the RIGHT (a static PNG served from the gameplay
// staticDir at /gameplay/<file>). Putting the live build next to the reference is
// what lets the screen reflect a component change (e.g. the blue room-entry button)
// and makes drift against Figma visible side by side.

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

// The gold "BOOST CLASS" pill — painted with the gold texture; shared by the
// drift-view header for a boost-class screen.
function BoostBadge() {
  return (
    <span
      style={{
        backgroundImage: 'var(--gold-texture)',
        backgroundSize: 'cover',
        backgroundPosition: 'center',
        color: 'var(--color-gold-foreground)',
        fontSize: 10,
        fontWeight: 700,
        padding: '2px 8px',
        borderRadius: 999,
      }}
    >
      BOOST CLASS
    </span>
  );
}

// The device bezel, shared by both panes. `golden` gilds the frame itself with the
// gold texture. The inner viewport is supplied by the caller.
function Bezel({
  width,
  golden,
  children,
}: {
  width: number;
  golden: boolean;
  children: React.ReactNode;
}) {
  return (
    <figure style={{ margin: 0, flexShrink: 0 }}>
      <div
        style={{
          width: width + 14,
          padding: 7,
          borderRadius: width * 0.12,
          background: golden ? undefined : '#0d0f12',
          backgroundImage: golden ? 'var(--gold-texture)' : undefined,
          backgroundSize: 'cover',
          backgroundPosition: 'center',
          boxShadow: '0 16px 38px rgba(0,0,0,0.26)',
        }}
      >
        <div style={{ borderRadius: width * 0.09, overflow: 'hidden', background: '#000' }}>
          {children}
        </div>
      </div>
    </figure>
  );
}

// A device-framed STATIC render — the Figma reference PNG (the right pane / the grids).
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
    <Bezel width={width} golden={golden}>
      <img
        src={screen.url}
        alt={screen.figma_label}
        loading="lazy"
        style={{ display: 'block', width, height: 'auto' }}
      />
    </Bezel>
  );
}

// A device-framed LIVE render — the same bezel as PhoneFrame, but wrapping live
// design-system DOM at the device width, on the app background gradient. The left
// pane of the drift view; height grows to the content so it sits full-length beside
// the (full-height) reference PNG.
export function LiveFrame({
  width = 300,
  golden = false,
  flush = false,
  children,
}: {
  width?: number;
  golden?: boolean;
  /** when true, no inner padding — the screen renders edge-to-edge (full-bleed
   *  status bar / corners), and the screen component manages its own padding. */
  flush?: boolean;
  children: React.ReactNode;
}) {
  return (
    <Bezel width={width} golden={golden}>
      <div
        style={{
          width,
          background: 'linear-gradient(180deg, var(--color-bg-app-from), var(--color-bg-app-to))',
          padding: flush ? 0 : '12px 8px',
        }}
      >
        {children}
      </div>
    </Bezel>
  );
}

// One labeled column of the drift view (a heading + a state tag, then the frame).
function PaneCol({
  label,
  tag,
  tagColor,
  children,
}: {
  label: string;
  tag: string;
  tagColor: string;
  children: React.ReactNode;
}) {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
        <span style={{ fontSize: 13, fontWeight: 700 }}>{label}</span>
        <span
          style={{
            fontSize: 9,
            fontWeight: 700,
            letterSpacing: 0.5,
            color: '#fff',
            background: tagColor,
            padding: '2px 6px',
            borderRadius: 4,
          }}
        >
          {tag}
        </span>
      </div>
      {children}
    </div>
  );
}

// The drift view: the live design-system build (left) beside the Figma reference
// (right), with the screen's metadata below. `children` is the live composition
// (a *Screen component); `note` is an optional caption under the header.
export function DriftView({
  screen,
  golden = false,
  width = 300,
  flush = false,
  note,
  children,
}: {
  screen: Screen;
  golden?: boolean;
  width?: number;
  /** pass through to the live frame — render the build edge-to-edge (no inner pad). */
  flush?: boolean;
  note?: React.ReactNode;
  children: React.ReactNode;
}) {
  const railWidth = 2 * (width + 14) + 28;
  return (
    <div className="font-sans" style={{ color: 'var(--color-dark-muted)' }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 4 }}>
        <h2 style={{ margin: 0, fontSize: 20 }}>{screen.figma_label}</h2>
        {golden && <BoostBadge />}
      </div>
      <code style={{ fontSize: 11, opacity: 0.6 }}>
        {screen.figma_id} · {screen.figma_type}
      </code>
      <p style={{ fontSize: 13, margin: '10px 0 0', opacity: 0.9, maxWidth: railWidth }}>
        {screen.role}
      </p>
      {note && <div style={{ marginTop: 10, maxWidth: railWidth }}>{note}</div>}
      <p style={{ fontSize: 12, opacity: 0.7, margin: '14px 0 18px', maxWidth: railWidth }}>
        <strong>Left</strong> — the screen rebuilt from the design system: live components,
        theme-aware (▸&nbsp;Theme toolbar), role-colored CTAs (blue <code>enter</code>, orange{' '}
        <code>purchase</code>). <strong>Right</strong> — the Figma reference export. Scan the pair for
        drift.
      </p>
      <div style={{ display: 'flex', gap: 28, flexWrap: 'wrap', alignItems: 'flex-start' }}>
        <PaneCol label="Design system" tag="LIVE" tagColor="var(--color-success)">
          <LiveFrame width={width} golden={golden} flush={flush}>
            {children}
          </LiveFrame>
        </PaneCol>
        <PaneCol label="Figma" tag="REFERENCE" tagColor="var(--color-muted)">
          <PhoneFrame screen={screen} width={width} golden={golden} />
        </PaneCol>
      </div>
      <div style={{ marginTop: 22 }}>
        <MetaRow label="game_state" value={screen.game_state} />
        <MetaRow label="mode" value={screen.mode} />
        <MetaRow label="entities" value={screen.entities.join(' · ')} />
        <MetaRow label="doc" value={<code style={{ fontSize: 11 }}>{screen.doc}</code>} />
      </div>
    </div>
  );
}
