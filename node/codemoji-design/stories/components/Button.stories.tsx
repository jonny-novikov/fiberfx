import type { Meta, StoryObj } from '@storybook/react-vite';
import * as React from 'react';
import { Button } from './Button';

// The themeable Button. The `buy` variant is the "Buy highlights orange/blue/
// green" demo — it rides bg-accent (the single themeable --accent), so it
// recolors with the global Theme toolbar. The `golden` variant rides
// --gradient-gold (the token form of the app's raster gild).

const meta: Meta<typeof Button> = {
  title: 'Components/Button',
  component: Button,
  argTypes: {
    variant: { control: 'select', options: ['buy', 'default', 'outline', 'golden'] },
    size: { control: 'select', options: ['sm', 'default', 'lg'] },
    children: { control: 'text' },
  },
  args: { children: 'Button' },
};
export default meta;

type Story = StoryObj<typeof Button>;

export const Buy: Story = {
  args: { variant: 'buy', children: 'Buy 100 keys' },
};

export const Default: Story = {
  args: { variant: 'default', children: 'Play' },
};

export const Outline: Story = {
  args: { variant: 'outline', children: 'Cancel' },
};

export const Golden: Story = {
  args: { variant: 'golden', children: 'Enter Golden Room' },
};

export const AllVariants: Story = {
  render: () => (
    <div style={{ display: 'flex', flexWrap: 'wrap', gap: 12, alignItems: 'center' }}>
      <Button variant="buy">Buy</Button>
      <Button variant="default">Play</Button>
      <Button variant="outline">Cancel</Button>
      <Button variant="golden">Golden</Button>
    </div>
  ),
};
