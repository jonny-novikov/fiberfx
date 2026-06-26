import type { Meta, StoryObj } from '@storybook/react-vite';
import * as React from 'react';
import { RoomList } from './RoomList';

// Lobby story — mirrors the RoomCard exemplar: title 'Lobby/<Name>', a plain
// max-w-sm width decorator (the list owns no surface of its own; each RoomCard
// is the card), one story per meaningful state. Shows the section composing the
// shared RoomCard across varied prizes + a golden boost-class room.
const meta: Meta<typeof RoomList> = {
  title: 'Lobby/Room List',
  component: RoomList,
  decorators: [
    (Story) => (
      <div className="font-sans max-w-sm">
        <Story />
      </div>
    ),
  ],
};
export default meta;

type Story = StoryObj<typeof RoomList>;

export const Default: Story = {
  args: {
    rooms: [
      { name: 'Warmup box', prize: 52, emojiCount: 12, cells: 4, bestPercent: 20 },
      { name: 'Steel box', prize: 1352, bestPercent: 60 },
      { name: 'Golden room', prize: 2352, bestPercent: 80, golden: true },
      { name: 'Hardcore level', prize: 4200, emojiCount: 30, cells: 8, bestPercent: 100 },
    ],
  },
};
