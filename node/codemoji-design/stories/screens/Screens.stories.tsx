import type { Meta, StoryObj } from '@storybook/react-vite';
import * as React from 'react';
// @ts-expect-error — .mjs data module has no .d.ts; shape is known here.
import { screensByCategory, counts } from './screens.data.mjs';

// The game-screen catalog. Each screen = its reference PNG (served from the
// gameplay/assets staticDir at /gameplay/<file>) + a metadata panel. The PNGs
// are STATIC reference — this catalog documents the game; live theming is on
// Foundations/Components. The two Golden Room screens are tagged.

type Screen = {
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

type Category = { id: string; label: string; screens: Screen[] };

function Meta({ label, value }: { label: string; value: React.ReactNode }) {
  return (
    <div style={{ display: 'flex', gap: 6, fontSize: 11, lineHeight: 1.5 }}>
      <span style={{ opacity: 0.55, minWidth: 78 }}>{label}</span>
      <span style={{ fontWeight: 600 }}>{value}</span>
    </div>
  );
}

function ScreenCard({ s }: { s: Screen }) {
  return (
    <div
      style={{
        border: s.isGolden ? '2px solid var(--color-gold-border)' : '1px solid rgba(0,0,0,0.15)',
        borderRadius: 12,
        overflow: 'hidden',
        background: 'var(--color-card)',
        width: 280,
        display: 'flex',
        flexDirection: 'column',
      }}
    >
      <div style={{ position: 'relative', background: '#eef3f5' }}>
        {s.isGolden && (
          <span
            style={{
              position: 'absolute',
              top: 8,
              right: 8,
              backgroundImage: 'var(--gold-texture)',
              backgroundSize: 'cover',
              backgroundPosition: 'center',
              color: 'var(--color-gold-foreground)',
              fontSize: 10,
              fontWeight: 700,
              padding: '2px 8px',
              borderRadius: 999,
              zIndex: 1,
            }}
          >
            GOLDEN ROOM
          </span>
        )}
        <img
          src={s.url}
          alt={s.figma_label}
          loading="lazy"
          style={{ display: 'block', width: '100%', height: 'auto' }}
        />
      </div>
      <div style={{ padding: 12, color: 'var(--color-dark-muted)' }}>
        <div style={{ fontWeight: 700, marginBottom: 2 }}>{s.figma_label}</div>
        <code style={{ fontSize: 10, opacity: 0.6 }}>
          {s.figma_id} · {s.figma_type}
        </code>
        <p style={{ fontSize: 11, margin: '8px 0', opacity: 0.85 }}>{s.role}</p>
        <Meta label="game_state" value={s.game_state} />
        <Meta label="mode" value={s.mode} />
        <Meta label="entities" value={s.entities.join(' · ')} />
        <Meta label="doc" value={<code style={{ fontSize: 10 }}>{s.doc}</code>} />
      </div>
    </div>
  );
}

function Catalog() {
  return (
    <div className="font-sans" style={{ color: 'var(--color-dark-muted)' }}>
      <h2 style={{ marginBottom: 4 }}>Game-screen catalog</h2>
      <p style={{ marginBottom: 20, opacity: 0.7 }}>
        {counts.screens} reference screens across {counts.categories} categories (from{' '}
        <code>gameplay/manifest.json</code>). PNGs are static reference; theming is live on
        Foundations / Components.
      </p>
      {(screensByCategory as Category[]).map((c) => (
        <section key={c.id} style={{ marginBottom: 32 }}>
          <h3 style={{ marginBottom: 12 }}>{c.label}</h3>
          <div style={{ display: 'flex', flexWrap: 'wrap', gap: 16 }}>
            {c.screens.map((s) => (
              <ScreenCard key={s.figma_id} s={s} />
            ))}
          </div>
        </section>
      ))}
    </div>
  );
}

const meta: Meta<typeof Catalog> = {
  title: 'Screens/Catalog',
  component: Catalog,
};
export default meta;

type Story = StoryObj<typeof Catalog>;
export const AllScreens: Story = {};
