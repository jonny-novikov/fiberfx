import type { Meta, StoryObj } from '@storybook/react-vite';
import * as React from 'react';
import { ArchiveRoomItem } from './ArchiveRoomItem';

// ArchiveRoomItem is itself a card, so — like the RoomCard exemplar — the
// decorator is just a plain max-w-sm width box (not a BoardCard wrapper).
const meta: Meta<typeof ArchiveRoomItem> = {
  title: 'Lobby/Archive Room Item',
  component: ArchiveRoomItem,
  decorators: [
    (Story) => (
      <div className="font-sans max-w-sm">
        <Story />
      </div>
    ),
  ],
};
export default meta;

type Story = StoryObj<typeof ArchiveRoomItem>;

export const Default: Story = {
  args: {
    name: 'Steel box',
    prize: 1352,
    code: ['🦊', '🚀', '💎', '🔥', '🎯', '⚡'],
    timeAgo: '2h ago',
    winner: '@ivan',
    gameId: 'GAM-7f3a9c',
  },
};
