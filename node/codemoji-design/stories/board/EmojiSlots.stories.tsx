import type { Meta, StoryObj } from '@storybook/react-vite';
import * as React from 'react';
import { BoardCard } from './lib/BoardCard';
import { EmojiSlots } from './EmojiSlots';

// EXEMPLAR board story — the template the other board components mirror:
// title 'Board/<Name>', a BoardCard decorator for the on-card context, one story
// per meaningful state.
const meta: Meta<typeof EmojiSlots> = {
  title: 'Board/Emoji Slots',
  component: EmojiSlots,
  decorators: [
    (Story) => (
      <BoardCard className="font-sans max-w-sm">
        <Story />
      </BoardCard>
    ),
  ],
};
export default meta;

type Story = StoryObj<typeof EmojiSlots>;

export const Empty: Story = { args: { emojis: [] } };
export const InProgress: Story = { args: { emojis: ['😀', '🐱', '🔥'] } };
export const Full: Story = { args: { emojis: ['😀', '🐱', '🔥', '🎮', '💎', '🚀'] } };
export const WithPinned: Story = {
  name: 'With pinned slot',
  args: { emojis: ['😀', undefined, '🔥'], locked: [0] },
};
