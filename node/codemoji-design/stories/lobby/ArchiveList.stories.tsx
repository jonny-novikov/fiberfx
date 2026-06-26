import type { Meta, StoryObj } from '@storybook/react-vite';
import * as React from 'react';
import { ArchiveList } from './ArchiveList';

// The whole "Room archive" section. Like the lobby exemplar, the decorator is a
// plain max-w-sm width box — the section already lays out its own cards + pager.
const meta: Meta<typeof ArchiveList> = {
  title: 'Lobby/Archive List',
  component: ArchiveList,
  decorators: [
    (Story) => (
      <div className="font-sans max-w-sm">
        <Story />
      </div>
    ),
  ],
};
export default meta;

type Story = StoryObj<typeof ArchiveList>;

export const Default: Story = {
  args: {
    items: [
      {
        name: 'Steel box',
        prize: 1352,
        code: ['🦊', '🚀', '💎', '🔥', '🎯', '⚡'],
        timeAgo: '2h ago',
        winner: '@ivan',
        gameId: 'GAM-7f3a9c',
      },
      {
        name: 'Warmup box',
        prize: 52,
        code: ['🐙', '🎲', '🌙', '🍀', '🎵', '🦄'],
        timeAgo: '5h ago',
        winner: '@mira',
        gameId: 'GAM-2b81de',
      },
      {
        name: 'Golden room',
        prize: 2352,
        code: ['👑', '💰', '🗝️', '🎰', '💫', '🏆'],
        timeAgo: '1d ago',
        winner: '@apollo',
        gameId: 'GAM-9c04ab',
      },
    ],
  },
};
