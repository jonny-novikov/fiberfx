import * as React from 'react';
import { useTranslation } from 'react-i18next';
// Reused straight from the board — the Golden Game IS the board with a gold
// treatment, so the composer / keyboard / tabs / rules / share are all imported.
import { StatusBar } from '../board/StatusBar';
import { EmojiSlots } from '../board/EmojiSlots';
import { GuessActions } from '../board/GuessActions';
import { EmojiKeyboard } from '../board/EmojiKeyboard';
import { BoardTabs } from '../board/BoardTabs';
import { GameRules } from '../board/GameRules';
import { ShareKeys } from '../board/ShareKeys';
import { BoardCard } from '../board/lib/BoardCard';
import { Button } from '../components/Button';
// Golden-specific surfaces.
import { GoldenHero } from './GoldenHero';
import { GoldenAnswerReveal } from './GoldenAnswerReveal';
import { GoldenLeaderboard, type GoldenStanding } from './GoldenLeaderboard';

// The two Golden Room screens assembled from the design system. The Golden Game is
// the gameplay board with a gold treatment: StatusBar / EmojiSlots / GuessActions /
// EmojiKeyboard / BoardTabs / GameRules / ShareKeys are REUSED from the board;
// GoldenHero / GoldenAnswerReveal / GoldenLeaderboard are the golden-specific
// surfaces. Static sample data; live theming still applies.
//
// Exported as plain components (not stories) so they back BOTH the
// Golden Game/Overview story AND the Screens/Golden Game drift view.

export const GOLDEN_STANDINGS: GoldenStanding[] = [
  { rank: 1, displayName: 'vited', code: ['😀', '🐱', '🔥', '🎮', '💎', '🚀'], prize: '$23.43' },
  { rank: 2, displayName: 'alice', code: ['🍀', '🎲', '🪙', '🔑', '⭐', '🧩'], prize: '$15.20' },
  { rank: 3, displayName: 'boris', code: ['🌟', '🍎', '🐙', '🎯', '💫', '🥇'], prize: '🔑 100', isCurrentPlayer: true },
  { rank: 4, displayName: 'chloe', code: ['🎈', '🍉', '🐢', '🏆', '✨', '🥈'], prize: '🔑 75' },
];

export const GOLDEN_ANSWER = ['😀', '🐱', '🔥', '🎮', '💎', '🚀'];

function Frame({ children }: { children: React.ReactNode }) {
  return <div className="font-sans mx-auto flex max-w-sm flex-col gap-3">{children}</div>;
}

function StandingsCard() {
  return (
    <BoardCard>
      {/* single-panel (the Golden standings) until the Golden tabs get their own
          reconcile pass — open on the leaderboard tab via the shared strip */}
      <BoardTabs defaultActive="leaderboard">
        <GoldenLeaderboard items={GOLDEN_STANDINGS} />
      </BoardTabs>
    </BoardCard>
  );
}

// 1089:19410 — an active boosted game.
export function GoldenInProgressScreen() {
  const { t } = useTranslation();
  return (
    <Frame>
      <StatusBar username="@player" diamonds={52352} clips={4} keys={147} />
      <GoldenHero timeLeft="48:00:00" prizePool={2352} boost={3} />
      <BoardCard className="px-3 pt-5 pb-4">
        <h2 className="mb-3 text-center text-xl font-bold leading-none">{t('game.guessTheCode')}</h2>
        <div className="flex flex-col gap-3">
          <EmojiSlots emojis={['0104', '0300', '0500']} />
          <GuessActions keyCost={5} />
        </div>
      </BoardCard>
      <Button variant="golden">{t('golden.viewWinners')}</Button>
      <BoardCard>
        <EmojiKeyboard />
      </BoardCard>
      <StandingsCard />
      <GameRules />
      <ShareKeys />
    </Frame>
  );
}

// 1108:27589 — post-settlement, winner-take-all of the boosted pool.
export function GoldenFinishedScreen() {
  const { t } = useTranslation();
  return (
    <Frame>
      <StatusBar username="@player" diamonds={52352} clips={4} keys={147} />
      <GoldenHero timeLeft="00:00:00" prizePool={2352} boost={3} />
      <GoldenAnswerReveal code={GOLDEN_ANSWER} />
      <Button variant="golden">{t('gameOverDialog.playAgain')}</Button>
      <StandingsCard />
      <GameRules />
      <ShareKeys />
    </Frame>
  );
}
