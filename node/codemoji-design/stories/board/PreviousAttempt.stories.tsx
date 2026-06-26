import type { Meta, StoryObj } from '@storybook/react-vite';
import * as React from 'react';
import { BoardCard } from './lib/BoardCard';
import { PreviousAttempt } from './PreviousAttempt';

// The previous-attempt row as it sits on the board card, above the guess slots.
const meta: Meta<typeof PreviousAttempt> = {
  title: 'Board/Previous Attempt',
  component: PreviousAttempt,
  decorators: [
    (Story) => (
      <BoardCard className="font-sans max-w-sm">
        <Story />
      </BoardCard>
    ),
  ],
};
export default meta;

type Story = StoryObj<typeof PreviousAttempt>;

export const Default: Story = {
  args: { emojis: ['😀', '🐱', '🔥', '🎮', '💎', '🚀'], points: 80 },
};
export const HighScore: Story = {
  args: { emojis: ['😎', '🦊', '⭐', '🚀', '🔑', '🌈'], points: 520 },
};
