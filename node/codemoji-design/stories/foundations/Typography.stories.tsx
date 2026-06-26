import type { Meta, StoryObj } from '@storybook/react-vite';
import * as React from 'react';
// @ts-expect-error — .mjs token source has no .d.ts; shape is known here.
import { textScale, fontSans } from '../../tokens/tokens.mjs';

// The --text-* scale rendered in Noto Sans Mono (--font-sans). Each row uses the
// matching Tailwind utility class so the scale is exercised through the tokens.

const utilityFor: Record<string, string> = {
  large: 'text-large',
  h1: 'text-h1',
  h2: 'text-h2',
  h3: 'text-h3',
  h4: 'text-h4',
  h5: 'text-h5',
  h6: 'text-h6',
  '2xs': 'text-2xs',
};

function Type() {
  return (
    <div className="font-sans" style={{ color: 'var(--color-dark-muted)' }}>
      <h2 style={{ marginBottom: 4 }}>Type scale</h2>
      <p style={{ marginBottom: 16, opacity: 0.7 }}>
        Font: <code>{fontSans}</code>
      </p>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
        {Object.entries(textScale as Record<string, string>).map(([name, value]) => (
          <div
            key={name}
            style={{ display: 'flex', alignItems: 'baseline', gap: 16, borderBottom: '1px solid rgba(0,0,0,0.08)', paddingBottom: 8 }}
          >
            <code style={{ width: 120, flexShrink: 0, fontSize: 11, opacity: 0.7 }}>
              --text-{name} ({value})
            </code>
            <span className={utilityFor[name]}>The quick brown fox — Codemoji 0123456789</span>
          </div>
        ))}
      </div>
    </div>
  );
}

const meta: Meta<typeof Type> = {
  title: 'Foundations/Typography',
  component: Type,
};
export default meta;

type Story = StoryObj<typeof Type>;
export const Scale: Story = {};
