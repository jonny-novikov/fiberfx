import type { Meta, StoryObj } from '@storybook/react-vite';
import * as React from 'react';
import { BoardCard } from './lib/BoardCard';
import { EmojiKeyboard } from './EmojiKeyboard';

// The emoji grid on the board card — the input source that fills the guess slots.
const meta: Meta<typeof EmojiKeyboard> = {
  title: 'Board/Emoji Keyboard',
  component: EmojiKeyboard,
  decorators: [
    (Story) => (
      <BoardCard className="font-sans max-w-sm">
        <Story />
      </BoardCard>
    ),
  ],
};
export default meta;

type Story = StoryObj<typeof EmojiKeyboard>;

export const Default: Story = {};
