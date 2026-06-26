import type { Meta, StoryObj } from '@storybook/react-vite';
import * as React from 'react';
import { RoomCard } from './RoomCard';

// EXEMPLAR lobby story — the template the other lobby components mirror:
// title 'Lobby/<Name>', a plain max-w-sm width decorator (RoomCard is itself a
// card), one story per meaningful state. RoomCard reuses the board's BoardCard +
// the gold Button variant, so the design system composes across screens.
const meta: Meta<typeof RoomCard> = {
  title: 'Lobby/Room Card',
  component: RoomCard,
  decorators: [
    (Story) => (
      <div className="font-sans max-w-sm">
        <Story />
      </div>
    ),
  ],
};
export default meta;

type Story = StoryObj<typeof RoomCard>;

export const Standard: Story = { args: { name: 'Steel box', prize: 1352, bestPercent: 60 } };
export const Free: Story = { args: { name: 'Warmup box', prize: 52, emojiCount: 12, bestPercent: 20 } };
export const Golden: Story = {
  name: 'Golden room',
  args: { name: 'Golden room', prize: 2352, bestPercent: 80, golden: true },
};
export const Closed: Story = {
  args: { name: 'Hardcore level', prize: 2352, bestPercent: 100, disabled: true },
};
