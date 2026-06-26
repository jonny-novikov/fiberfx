import type { Meta, StoryObj } from '@storybook/react-vite';
import * as React from 'react';
import { KeysBalance } from './KeysBalance';

// KeysBalance renders its own BoardCard, so the decorator only supplies the
// board's type + width context. Switch the Theme toolbar to watch the Buy button
// (bg-accent) recolor.
const meta: Meta<typeof KeysBalance> = {
  title: 'Board/Keys Balance',
  component: KeysBalance,
  decorators: [
    (Story) => (
      <div className="font-sans max-w-sm">
        <Story />
      </div>
    ),
  ],
};
export default meta;

type Story = StoryObj<typeof KeysBalance>;

export const Default: Story = { args: { keys: 147 } };
export const LowBalance: Story = { name: 'Low balance', args: { keys: 2 } };
