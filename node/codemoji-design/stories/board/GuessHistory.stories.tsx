import type { Meta, StoryObj } from '@storybook/react-vite';
import * as React from 'react';
import { BoardCard } from './lib/BoardCard';
import { GuessHistory } from './GuessHistory';
import { BOARD_HISTORY } from './BoardScreen';

// The player's own attempt list under the History tab — the board's FIRST/default
// tab. Each row: the attempt number (🔖 N), the guessed emoji row (with the per-peg
// green/yellow/red annotation the player taps to set), and points over a Main-Blue
// bar. The right column matches the Leaderboard row so the bars align on switch.
const meta: Meta<typeof GuessHistory> = {
  title: 'Board/Guess History',
  component: GuessHistory,
  decorators: [
    (Story) => (
      <BoardCard className="font-sans max-w-sm">
        <Story />
      </BoardCard>
    ),
  ],
};
export default meta;

type Story = StoryObj<typeof GuessHistory>;

export const Default: Story = { args: { items: BOARD_HISTORY } };

// No attempts yet — the app's empty prompt.
export const Empty: Story = { args: { items: [] } };
