import type { Meta, StoryObj } from '@storybook/react-vite';
import * as React from 'react';
// @ts-expect-error — .mjs token source has no .d.ts; shape is known here.
import { accentThemes } from '../../tokens/tokens.mjs';
import { Button } from '../components/Button';

// The accent themes explained: three fixed swatches + a live demo. The single
// themeable --accent channel is what the three [data-theme] blocks override;
// the Buy button below reads it live (recolor with the Theme toolbar).

function Card({ name, value }: { name: string; value: string }) {
  return (
    <div
      data-theme={name}
      style={{
        border: '1px solid rgba(0,0,0,0.15)',
        borderRadius: 12,
        padding: 16,
        width: 240,
        background: 'var(--color-card)',
        display: 'flex',
        flexDirection: 'column',
        gap: 12,
      }}
    >
      <div style={{ height: 48, borderRadius: 8, background: 'var(--accent)' }} />
      <div>
        <code style={{ fontSize: 12 }}>data-theme=&quot;{name}&quot;</code>
        <br />
        <code style={{ fontSize: 11, opacity: 0.7 }}>--accent: {value}</code>
      </div>
      <Button variant="buy" size="sm">
        Buy
      </Button>
    </div>
  );
}

function Themes() {
  return (
    <div className="font-sans" style={{ color: 'var(--color-dark-muted)' }}>
      <h2 style={{ marginBottom: 8 }}>Accent themes</h2>
      <p style={{ marginBottom: 16, maxWidth: 680 }}>
        The design system exposes a single themeable channel, <code>--accent</code>. Three{' '}
        <code>[data-theme]</code> blocks override it — <strong>orange</strong> (the current accent),{' '}
        <strong>blue</strong> (the app&apos;s <code>--link</code>), and <strong>green</strong> (the
        app&apos;s <code>--color-success</code>). Each card below pins its own theme; the global
        Theme toolbar drives the rest of the stories.
      </p>
      <div style={{ display: 'flex', flexWrap: 'wrap', gap: 16 }}>
        {Object.entries(accentThemes as Record<string, string>).map(([name, value]) => (
          <Card key={name} name={name} value={value} />
        ))}
      </div>
    </div>
  );
}

const meta: Meta<typeof Themes> = {
  title: 'Foundations/Themes',
  component: Themes,
};
export default meta;

type Story = StoryObj<typeof Themes>;
export const AccentThemes: Story = {};
