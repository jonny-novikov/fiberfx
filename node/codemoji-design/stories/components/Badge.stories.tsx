import type { Meta, StoryObj } from '@storybook/react-vite';
import * as React from 'react';
import { Badge } from './Badge';

// The Badge chip — accent (themeable), muted, success, and gold (tokenized gild).

const meta: Meta<typeof Badge> = {
  title: 'Components/Badge',
  component: Badge,
  argTypes: {
    variant: { control: 'select', options: ['accent', 'muted', 'success', 'gold'] },
    children: { control: 'text' },
  },
  args: { children: 'Badge' },
};
export default meta;

type Story = StoryObj<typeof Badge>;

export const Accent: Story = { args: { variant: 'accent', children: 'NEW' } };
export const Success: Story = { args: { variant: 'success', children: '+147' } };
export const Gold: Story = { args: { variant: 'gold', children: '3× BOOST' } };

export const AllVariants: Story = {
  render: () => (
    <div style={{ display: 'flex', gap: 10, alignItems: 'center', flexWrap: 'wrap' }}>
      <Badge variant="accent">NEW</Badge>
      <Badge variant="muted">closed</Badge>
      <Badge variant="success">+147</Badge>
      <Badge variant="gold">3× BOOST</Badge>
    </div>
  ),
};
