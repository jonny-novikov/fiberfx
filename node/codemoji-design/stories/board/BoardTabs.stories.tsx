import type { Meta, StoryObj } from '@storybook/react-vite';
import * as React from 'react';
import { BoardCard } from './lib/BoardCard';
import { BoardTabs } from './BoardTabs';

// The two-tab strip that switches the board between History and Leaderboard.
// One story per meaningful state: which tab is active.
const meta: Meta<typeof BoardTabs> = {
  title: 'Board/Board Tabs',
  component: BoardTabs,
  decorators: [
    (Story) => (
      <BoardCard className="font-sans max-w-sm">
        <Story />
      </BoardCard>
    ),
  ],
};
export default meta;

type Story = StoryObj<typeof BoardTabs>;

export const Default: Story = { args: { active: 'leaderboard' } };
export const HistoryActive: Story = {
  name: 'History active',
  args: { active: 'history' },
};
