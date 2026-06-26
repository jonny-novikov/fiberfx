import type { Meta, StoryObj } from '@storybook/react-vite';
import * as React from 'react';
import { GameRules } from './GameRules';

// GameRules is itself a BoardCard, so it just needs the board-column width.
// One story for the single state.
const meta: Meta<typeof GameRules> = {
  title: 'Board/Game Rules',
  component: GameRules,
  decorators: [
    (Story) => (
      <div className="max-w-sm">
        <Story />
      </div>
    ),
  ],
};
export default meta;

type Story = StoryObj<typeof GameRules>;

export const Default: Story = {};
