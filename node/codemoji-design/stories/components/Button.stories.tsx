import type { Meta, StoryObj } from '@storybook/react-vite';
import * as React from 'react';
import { Button } from './Button';

// The Button carries two kinds of CTA color:
//   - THEME-driven: `buy` rides bg-accent (the single themeable --accent), so it
//     recolors orange/blue/green with the global Theme toolbar.
//   - ROLE-driven (fixed, by intent): `purchase` is the orange buy gradient
//     ("Приобрести ключи"), `enter` is blue (Open safe / Enter room), `golden`
//     is the gold gild. These signal spend / play / boosted and never change
//     with the theme — they are the color overrides for the plain black button.

const meta: Meta<typeof Button> = {
  title: 'Components/Button',
  component: Button,
  argTypes: {
    variant: {
      control: 'select',
      options: ['default', 'purchase', 'enter', 'golden', 'buy', 'outline'],
    },
    size: { control: 'select', options: ['sm', 'default', 'lg'] },
    children: { control: 'text' },
  },
  args: { children: 'Button' },
};
export default meta;

type Story = StoryObj<typeof Button>;

export const Default: Story = { args: { variant: 'default', children: 'Check' } };
export const Purchase: Story = { args: { variant: 'purchase', children: 'Buy keys ⭐' } };
export const Enter: Story = { args: { variant: 'enter', children: '💸 Open safe' } };
export const Golden: Story = { args: { variant: 'golden', children: 'Enter Golden Room' } };
export const Buy: Story = { args: { variant: 'buy', children: 'Buy (themeable)' } };
export const Outline: Story = { args: { variant: 'outline', children: 'Cancel' } };

// The color overrides for the plain black (default) button, by role: a black
// CTA recolored to purchase (orange) / enter (blue) / golden — the fixed,
// intent-signalling colors. (`buy` is shown too: the theme-driven accent.)
function Swatch({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 6, minWidth: 150 }}>
      <span style={{ fontSize: 11, opacity: 0.6 }}>{label}</span>
      {children}
    </div>
  );
}

export const ColorOverrides: Story = {
  name: 'Color overrides (black → role)',
  render: () => (
    <div
      className="font-sans"
      style={{ display: 'flex', flexWrap: 'wrap', gap: 20, alignItems: 'flex-start' }}
    >
      <Swatch label="default (black)">
        <Button variant="default">Check</Button>
      </Swatch>
      <Swatch label="purchase → orange gradient">
        <Button variant="purchase">Buy keys ⭐</Button>
      </Swatch>
      <Swatch label="enter → blue">
        <Button variant="enter">💸 Open safe</Button>
      </Swatch>
      <Swatch label="golden → gild">
        <Button variant="golden">Golden Room</Button>
      </Swatch>
      <Swatch label="buy → accent (themeable)">
        <Button variant="buy">Share</Button>
      </Swatch>
    </div>
  ),
};
