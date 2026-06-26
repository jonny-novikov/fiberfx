import type { Meta, StoryObj } from '@storybook/react-vite';
import * as React from 'react';
import { BoardCard } from './lib/BoardCard';
import { StatusBar } from './StatusBar';
import { RoundInfo } from './RoundInfo';
import { KeysBalance } from './KeysBalance';
import { PreviousAttempt } from './PreviousAttempt';
import { EmojiSlots } from './EmojiSlots';
import { GuessActions } from './GuessActions';
import { EmojiKeyboard } from './EmojiKeyboard';
import { BoardTabs } from './BoardTabs';
import { Leaderboard } from './Leaderboard';
import { ShareKeys } from './ShareKeys';
import { GameRules } from './GameRules';

// CAPSTONE — the whole gameplay board (94:2974) assembled from the design
// system's board components, top to bottom as the screen reads. Every block here
// IS one of the Board/* components; this story is the proof they compose into the
// real screen. Static sample data; the live theming (the accent CTAs, the active
// tab + the score bars) still recolors with the ▸ Theme toolbar.

const LEADERS = [
  { displayName: 'Mara', finalPoints: 540 },
  { displayName: 'You', finalPoints: 480, isCurrentPlayer: true },
  { displayName: 'Kenji', finalPoints: 420 },
  { displayName: 'Ana', finalPoints: 360 },
  { displayName: 'Lev', finalPoints: 300 },
];

function BoardOverview() {
  return (
    <div className="font-sans mx-auto flex max-w-sm flex-col gap-3">
      <StatusBar username="@player" diamonds={52352} clips={4} keys={147} />
      <RoundInfo timeLeft="34:55:38" prizePool={52352} />
      <KeysBalance keys={147} />

      {/* the composer: title + previous attempt + slots + check/clear */}
      <BoardCard className="px-3 pt-5 pb-4">
        <h2 className="mb-3 text-center text-xl font-bold leading-none">Guess the code</h2>
        <div className="flex flex-col gap-3">
          <PreviousAttempt emojis={['😀', '🐱', '🔥', '🎮', '💎', '🚀']} points={80} />
          <EmojiSlots emojis={['😀', '🐱', '🔥']} />
          <GuessActions keyCost={5} />
        </div>
      </BoardCard>

      <BoardCard>
        <EmojiKeyboard />
      </BoardCard>

      <BoardCard>
        <BoardTabs>
          <Leaderboard items={LEADERS} />
        </BoardTabs>
      </BoardCard>

      <ShareKeys />
      <GameRules />
    </div>
  );
}

const meta: Meta<typeof BoardOverview> = {
  title: 'Board/Overview',
  component: BoardOverview,
};
export default meta;

type Story = StoryObj<typeof BoardOverview>;
export const FullBoard: Story = { name: 'Full board' };
