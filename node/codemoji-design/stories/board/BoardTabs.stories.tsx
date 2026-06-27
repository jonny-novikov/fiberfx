import type { Meta, StoryObj } from '@storybook/react-vite';
import * as React from 'react';
import { BoardCard } from './lib/BoardCard';
import { BoardTabs } from './BoardTabs';
import { GuessHistory } from './GuessHistory';
import { Leaderboard } from './Leaderboard';
import { BOARD_HISTORY, BOARD_LEADERS } from './BoardScreen';

// The two-tab strip that SWITCHES the board between History and Leaderboard.
// Both panels are wired (the same sample data the board screen uses), so clicking a
// tab swaps the content — the strip is genuinely switchable, not a colour change.
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
  args: {
    panels: {
      history: <GuessHistory items={BOARD_HISTORY} />,
      leaderboard: <Leaderboard items={BOARD_LEADERS} />,
    },
  },
};
export default meta;

type Story = StoryObj<typeof BoardTabs>;

// Opens on History (the board default, matching the app's defaultValue="history").
// Click the tabs to switch panels.
export const Default: Story = {};

// The same strip, opened on the Leaderboard tab.
export const LeaderboardActive: Story = {
  name: 'Leaderboard active',
  args: { defaultActive: 'leaderboard' },
};
