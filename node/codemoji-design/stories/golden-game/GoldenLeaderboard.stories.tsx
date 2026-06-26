import type { Meta, StoryObj } from '@storybook/react-vite';
import * as React from 'react';
import { BoardCard } from '../board/lib/BoardCard';
import { GoldenLeaderboard } from './GoldenLeaderboard';

// The golden standings sit inside a card on the screen, so the story wraps them
// in the shared BoardCard for the on-card context.
const meta: Meta<typeof GoldenLeaderboard> = {
  title: 'Golden Game/Golden Leaderboard',
  component: GoldenLeaderboard,
  decorators: [
    (Story) => (
      <div className="font-sans max-w-sm">
        <BoardCard>
          <Story />
        </BoardCard>
      </div>
    ),
  ],
};
export default meta;

type Story = StoryObj<typeof GoldenLeaderboard>;

export const Default: Story = {
  args: {
    items: [
      { rank: 1, displayName: 'vited', code: ['😀', '🐱', '🔥', '🎮', '💎', '🚀'], prize: '$23.43' },
      { rank: 2, displayName: 'alice', code: ['🍀', '🎲', '🪙', '🔑', '⭐', '🧩'], prize: '$15.20' },
      { rank: 3, displayName: 'boris', code: ['🌟', '🍎', '🐙', '🎯', '💫', '🥇'], prize: '🔑 100', isCurrentPlayer: true },
      { rank: 4, displayName: 'chloe', code: ['🎈', '🍉', '🐢', '🏆', '✨', '🥈'], prize: '🔑 75' },
      { rank: 5, displayName: 'david', code: ['🌈', '🍇', '🦊', '🎰', '💠', '🥉'], prize: '🔑 50' },
    ],
  },
};
