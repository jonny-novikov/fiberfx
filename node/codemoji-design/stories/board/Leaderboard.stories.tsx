import type { Meta, StoryObj } from '@storybook/react-vite';
import * as React from 'react';
import { BoardCard } from './lib/BoardCard';
import { Leaderboard } from './Leaderboard';

// The ranked player list under the Leaderboard tab — a sample of ~5 players,
// one of them the current player (tinted). The top scorers show the time they hit
// the score (ties go to whoever got there first); the rest show a match percent.
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
      { handle: '@phantomblade', score: 540, metric: '21:49', avatar: '🔥' },
      { handle: '@prokiller88', score: 540, metric: '21:54', avatar: '🧑', isCurrentPlayer: true },
      { handle: '@lolkekcheburek420', score: 240, metric: '11.2%', avatar: '🤖' },
      { handle: '@swagyolo360noscope', score: 120, metric: '9.4%', avatar: '🧑‍🦰' },
      { handle: '@getrektm8', score: 60, metric: '9.4%', avatar: '🇩🇪' },
    ],
  },
};
