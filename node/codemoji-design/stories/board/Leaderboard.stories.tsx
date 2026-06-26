import type { Meta, StoryObj } from '@storybook/react-vite';
import * as React from 'react';
import { BoardCard } from './lib/BoardCard';
import { Leaderboard } from './Leaderboard';

// The ranked player list under the Leaderboard tab — a sample of ~5 players,
// one of them the current player (tinted + a "(you)" tag).
const meta: Meta<typeof Leaderboard> = {
  title: 'Board/Leaderboard',
  component: Leaderboard,
  decorators: [
    (Story) => (
      <BoardCard className="font-sans max-w-sm">
        <Story />
      </BoardCard>
    ),
  ],
};
export default meta;

type Story = StoryObj<typeof Leaderboard>;

export const Default: Story = {
  args: {
    items: [
      { displayName: 'Mona', finalPoints: 540 },
      { displayName: 'Yuki', finalPoints: 500, isCurrentPlayer: true },
      { displayName: 'Diego', finalPoints: 420 },
      { displayName: 'Amara', finalPoints: 360 },
      { displayName: 'Lukas', finalPoints: 240 },
    ],
  },
};
