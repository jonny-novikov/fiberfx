import type { Meta, StoryObj } from '@storybook/react-vite';
import * as React from 'react';
// Reused straight from the board — the design-system payoff: these three are the
// SAME components the gameplay board uses, composed here into a different screen.
import { StatusBar } from '../board/StatusBar';
import { GameRules } from '../board/GameRules';
import { ShareKeys } from '../board/ShareKeys';
// Lobby-specific components.
import { SubscriptionBanner } from './SubscriptionBanner';
import { PromoBanner } from './PromoBanner';
import { RoomList } from './RoomList';
import { ArchiveList } from './ArchiveList';
import { BuyKeysBanner } from './BuyKeysBanner';
import { CharacterFooter } from './CharacterFooter';

// CAPSTONE — the whole Rooms→Lobby screen (121:2056) assembled from the design
// system, top to bottom as rooms.page.tsx composes it. StatusBar / GameRules /
// ShareKeys are REUSED from the board (no rebuild); the rest are the lobby
// components. Static sample data; the live theming (accent CTAs, the golden room,
// score bars) still recolors with the ▸ Theme toolbar.

const ROOMS = [
  { name: 'Warmup box', prize: 52, emojiCount: 12, bestPercent: 20 },
  { name: 'Steel box', prize: 1352, bestPercent: 60 },
  { name: 'Golden room', prize: 2352, bestPercent: 80, golden: true },
  { name: 'Hardcore level', prize: 2352, bestPercent: 100, disabled: true },
];

const ARCHIVE = [
  { name: 'Training', prize: 23, code: ['😀', '🐱', '🔥', '🎮', '💎', '🚀'], timeAgo: '2h ago', winner: '@mara', gameId: 'GAM-1042' },
  { name: 'Hardcore', prize: 23, code: ['🍀', '🎲', '🪙', '🔑', '⭐', '🧩'], timeAgo: '5h ago', winner: '@kenji', gameId: 'GAM-1039' },
  { name: 'Training', prize: 23, code: ['🌟', '🍎', '🐙', '🎯', '💫', '🥇'], timeAgo: '1d ago', winner: '@ana', gameId: 'GAM-1031' },
];

function LobbyOverview() {
  return (
    <div className="font-sans mx-auto flex max-w-sm flex-col gap-3">
      <StatusBar username="@player" diamonds={52352} clips={4} keys={147} />
      <SubscriptionBanner />
      <PromoBanner totalEarned={25693} />
      <RoomList rooms={ROOMS} />
      <ArchiveList items={ARCHIVE} />
      <GameRules />
      <ShareKeys />
      <BuyKeysBanner players={525693} />
      <CharacterFooter caption="See you on the leaderboard" />
    </div>
  );
}

const meta: Meta<typeof LobbyOverview> = {
  title: 'Lobby/Overview',
  component: LobbyOverview,
};
export default meta;

type Story = StoryObj<typeof LobbyOverview>;
export const FullLobby: Story = { name: 'Full lobby' };
