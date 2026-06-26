import type { Meta, StoryObj } from '@storybook/react-vite';
import * as React from 'react';
// @ts-expect-error — .mjs token source has no .d.ts; shape is known here.
import { base, literalColors, accentThemes } from '../../tokens/tokens.mjs';

// Live swatches of the base palette + the literal semantic colors + the accent
// themes. The accent row recolors with the global `theme` toolbar (it reads the
// live --accent via a CSS var), proving the single themeable channel.

function Swatch({ name, value }: { name: string; value: string }) {
  return (
    <div
      style={{
        display: 'flex',
        flexDirection: 'column',
        gap: 4,
        width: 150,
      }}
    >
      <div
        style={{
          height: 56,
          borderRadius: 8,
          background: value,
          border: '1px solid rgba(0,0,0,0.15)',
        }}
      />
      <code style={{ fontSize: 11 }}>{name}</code>
      <code style={{ fontSize: 10, opacity: 0.7 }}>{value}</code>
    </div>
  );
}

function Grid({ children }: { children: React.ReactNode }) {
  return (
    <div style={{ display: 'flex', flexWrap: 'wrap', gap: 16, padding: 8 }}>{children}</div>
  );
}

function Section({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <section style={{ marginBottom: 28 }}>
      <h2 style={{ marginBottom: 8 }}>{title}</h2>
      {children}
    </section>
  );
}

function Palette() {
  return (
    <div className="font-sans" style={{ color: 'var(--color-dark-muted)' }}>
      <Section title="Base palette (:root, oklch — verbatim from the app)">
        <Grid>
          {Object.entries(base as Record<string, string>).map(([name, value]) => (
            <Swatch key={name} name={`--${name}`} value={value} />
          ))}
        </Grid>
      </Section>

      <Section title="Literal semantic colors (@theme inline)">
        <Grid>
          {Object.entries(literalColors as Record<string, string>).map(([name, value]) => (
            <Swatch key={name} name={`--color-${name}`} value={value} />
          ))}
        </Grid>
      </Section>

      <Section title="Accent — the LIVE themeable channel (recolor with the Theme toolbar)">
        <Grid>
          <Swatch name="--accent (live)" value="var(--accent)" />
          <Swatch name="bg-accent (utility)" value="var(--color-accent)" />
        </Grid>
        <p style={{ marginTop: 8, maxWidth: 640 }}>
          The two swatches above read the live <code>--accent</code> — switch the Theme toolbar and
          they recolor. Below are the three fixed accent treatments the{' '}
          <code>[data-theme]</code> blocks set.
        </p>
        <Grid>
          {Object.entries(accentThemes as Record<string, string>).map(([name, value]) => (
            <Swatch key={name} name={`accent: ${name}`} value={value} />
          ))}
        </Grid>
      </Section>
    </div>
  );
}

const meta: Meta<typeof Palette> = {
  title: 'Foundations/Colors',
  component: Palette,
};
export default meta;

type Story = StoryObj<typeof Palette>;
export const AllColors: Story = {};
