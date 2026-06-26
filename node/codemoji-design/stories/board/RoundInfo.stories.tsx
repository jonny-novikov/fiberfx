import type { Meta, StoryObj } from '@storybook/react-vite';
import * as React from 'react';
import { RoundInfo } from './RoundInfo';

// The green round-status card is its OWN surface (bg-success), so unlike the
// other board stories it gets NO BoardCard decorator — just font-sans + a width.
const meta: Meta<typeof RoundInfo> = {
  title: 'Board/Round Info',
  component: RoundInfo,
  decorators: [
    (Story) => (
      <div className="font-sans max-w-sm">
        <Story />
      </div>
    ),
  ],
};
export default meta;

type Story = StoryObj<typeof RoundInfo>;

export const Default: Story = { args: { timeLeft: '34:55:38', prizePool: 52352 } };
export const EndingSoon: Story = {
  name: 'Ending soon',
  args: { timeLeft: '00:04:12', prizePool: 52352 },
};
