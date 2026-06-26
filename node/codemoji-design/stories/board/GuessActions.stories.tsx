import type { Meta, StoryObj } from '@storybook/react-vite';
import * as React from 'react';
import { BoardCard } from './lib/BoardCard';
import { GuessActions } from './GuessActions';

// The submit row as it sits on the board card, under the guess slots.
const meta: Meta<typeof GuessActions> = {
  title: 'Board/Guess Actions',
  component: GuessActions,
  decorators: [
    (Story) => (
      <BoardCard className="font-sans max-w-sm">
        <Story />
      </BoardCard>
    ),
  ],
};
export default meta;

type Story = StoryObj<typeof GuessActions>;

export const Default: Story = { args: { keyCost: 5 } };
export const Disabled: Story = {
  name: 'Incomplete guess',
  args: { keyCost: 5, disabled: true },
};
