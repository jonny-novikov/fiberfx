import type { Meta, StoryObj } from '@storybook/react-vite';
import * as React from 'react';
import { RoundInfo } from './RoundInfo';

// The round-status row is a TWO-card pair (a white countdown + the green prize
// card), each its own surface, so unlike the other board stories it gets NO
// BoardCard decorator — just font-sans + a width.
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

export const Default: Story = { args: { timeLeft: '34:59:38', prizeUsd: 2352, diamonds: 468 } };
export const EndingSoon: Story = {
  name: 'Ending soon',
  args: { timeLeft: '00:04:12', prizeUsd: 2352, diamonds: 468 },
};
