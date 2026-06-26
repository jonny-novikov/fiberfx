import * as React from 'react';
// Phone chrome — shared with the lobby (the master's "Header old (iOS)").
import { NavPhonePanel } from '../lobby/NavPhonePanel';
// Board-specific components, top to bottom.
import { InfoDashboard } from './InfoDashboard';
import { PreviousAttempt } from './PreviousAttempt';
import { EmojiSlots } from './EmojiSlots';
import { GuessActions } from './GuessActions';
import { EmojiKeyboard } from './EmojiKeyboard';
import { BoardTabs } from './BoardTabs';
import { Leaderboard, type LeaderboardEntry } from './Leaderboard';
import { GameRules } from './GameRules';
import { ShareKeys } from './ShareKeys';
import { BoardCard } from './lib/BoardCard';

// The whole Game (Free) board (94:2974) assembled from the design system, in the
// Figma master's vertical order: phone chrome → the Info dashboard → the guess card
// (heading · previous attempt · slots · actions) → the emoji keyboard → the
// tabs + leaderboard → rules → share → the free-key footer. Text + sizes track the
// Figma master (375-wide frame, real Russian copy).
//
// LAYOUT: like the lobby, the screen is SELF-CONTAINED — the root paints the board
// "All Screen Fill" gradient (--color-bg-app-from → --color-bg-app-to), the standing
// override (every screen takes the board background). The cards float on it; the Info
// dashboard carries a soft blue lift so it reads against the gradient.
//
// COLOR is the design system's role layer: the submit is the master's blue `enter`,
// the leaderboard metric/bar + the active tab use the app's fixed Main Blue (#54C0EC).
// GuessActions / BoardTabs / EmojiKeyboard / EmojiSlots / GameRules / ShareKeys are
// SHARED with the Golden Game.
// Static sample data.
//
// Exported as a plain component (not a story) so it backs BOTH the Board/Overview
// story AND the Screens/Game (Free) drift view (live build vs the Figma export).

// The leaderboard standings — handles/scores/metrics verbatim from the Figma master
// (top three tied at 540 show the time they got there; the rest show a match %).
export const BOARD_LEADERS: LeaderboardEntry[] = [
  { handle: '@phantomblade', score: 540, metric: '21:49', avatar: '🔥' },
  { handle: '@SuperUltraMegaHyper', score: 540, metric: '21:54', avatar: '😎' },
  { handle: '@prokiller88', score: 540, metric: '21:23', avatar: '🧑' },
  { handle: '@lolkekcheburek420', score: 240, metric: '11.2%', avatar: '🤖', isCurrentPlayer: true },
  { handle: '@swagyolo360noscope', score: 120, metric: '9.4%', avatar: '🧑‍🦰' },
  { handle: '@getrektm8', score: 60, metric: '9.4%', avatar: '🇩🇪' },
];

// The board's "All Screen Fill" gradient (Figma 94:2974 fill) — top-light to
// bottom-blue, on the design system's bg tokens (#E8F3F7 → #AFC7D6).
const SCREEN_FILL = 'linear-gradient(180deg, var(--color-bg-app-from), var(--color-bg-app-to))';

export function BoardScreen() {
  return (
    <div className="font-sans" style={{ background: SCREEN_FILL }}>
      {/* phone chrome — full-bleed (status bar to the corners), near the top */}
      <NavPhonePanel />
      <div className="mx-auto flex max-w-sm flex-col gap-3 px-2 pt-2 pb-10">
        {/* the top Info dashboard (balance pill · timer + prize · stat cards) */}
        <InfoDashboard
          keys={34}
          timeLeft="34:59:38"
          prizeUsd={2352}
          diamonds={468}
          totalPlayers={147}
          totalAttempts={0}
          bestAttempt={0}
        />

        {/* the guess card */}
        <BoardCard className="px-3 pt-5 pb-4">
          <h2 className="mb-3 text-center text-xl font-bold leading-none">Отгадай код из 6 эмодзи</h2>
          <div className="flex flex-col gap-3">
            <PreviousAttempt emojis={['🐝', '🪑', '🌳', '🔌', '💎', '🚀']} points={280} />
            <EmojiSlots emojis={['🐝', '🪑', '🌳']} />
            <GuessActions keyCost={5} />
          </div>
        </BoardCard>

        {/* the emoji keyboard */}
        <BoardCard>
          <EmojiKeyboard />
        </BoardCard>

        {/* tabs + the leaderboard */}
        <BoardCard>
          <BoardTabs>
            <Leaderboard items={BOARD_LEADERS} />
          </BoardTabs>
        </BoardCard>

        {/* rules → share (the master order), then the free-key footer */}
        <GameRules />
        <ShareKeys />
        <p className="pt-1 text-center text-h5 text-muted">
          Бесплатный ключ будет доступен через 15 часов
        </p>
      </div>
    </div>
  );
}
