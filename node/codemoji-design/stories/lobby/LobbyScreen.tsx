import * as React from 'react';
// Reused straight from the board — the design-system payoff: these two are the SAME
// components the gameplay board uses, composed here into a different screen.
import { GameRules } from '../board/GameRules';
import { ShareKeys } from '../board/ShareKeys';
// Lobby-specific components.
import { StatusBar } from '../board/StatusBar';
import { SubscriptionBanner } from './SubscriptionBanner';
import { PromoBanner } from './PromoBanner';
import { RoomList } from './RoomList';
import { ArchiveList } from './ArchiveList';
import { BuyKeysBanner } from './BuyKeysBanner';
import { CharacterFooter } from './CharacterFooter';

// The whole Rooms→Lobby screen (121:2056) assembled from the design system, in the
// Figma master's vertical order: status bar → earnings promo → "Тысяча" hero → the
// room list → your golden rooms → the room archive → rules → share → mascot → a
// repeated promo. Text + sizes track Figma (375-wide frame, real Russian copy);
// COLOR is the design system's role layer (blue room-entry where Figma is black —
// the deliberate drift the Screens/Rooms (Lobby) view surfaces). GameRules /
// ShareKeys / StatusBar are REUSED from the board. Static sample data.
//
// Exported as a plain component (not a story) so it backs BOTH the Lobby/Overview
// story AND the Screens/Rooms (Lobby) drift view (live build vs the Figma export).

// The room list — names/prizes/meta/CTAs verbatim from the Figma master.
export const LOBBY_ROOMS = [
  { name: 'Простой сейф', prize: 52, stars: 1, emojiCount: 80, cells: 6, ctaLabel: 'Открыть 🔑 бесплатно' },
  { name: 'Золотая комната', prize: 10, stars: 1, emojiCount: 80, cells: 6, ctaLabel: 'Открыть сейф 🔑 1', golden: true },
  { name: 'Стальной ящик', prize: 1352, stars: 2, emojiCount: 140, cells: 6, bestPercent: 24.32, ctaLabel: 'Открыть 🔑 сейф' },
];

// One settled golden room ("Ваши золотые комнаты").
export const LOBBY_GOLDEN_ARCHIVE = [
  { name: 'Хардкор', prize: 23, code: ['😀', '🐱', '🔥', '🎮', '💎', '🚀'], gameId: '271597758257029120', timeAgo: '1ч 34м назад', winner: '@jonnynovikov' },
];

// The room archive ("Архив комнат"). Footers are verbatim from Figma; the revealed
// codes are representative sample reveals.
export const LOBBY_ARCHIVE = [
  { name: 'Хардкор', prize: 23, code: ['😀', '🐱', '🔥', '🎮', '💎', '🚀'], gameId: '271597758257029120', timeAgo: '1ч 34м назад', winner: '@jonnynovikov' },
  { name: 'Хардкор', prize: 23, code: ['🍀', '🎲', '🪙', '🔑', '⭐', '🧩'], gameId: '410812780257029121', timeAgo: '2ч 10м назад', winner: 'tgid 410812780' },
  { name: 'Простой сейф', prize: 52, code: ['🌟', '🍎', '🐙', '🎯', '💫', '🥇'], gameId: '271597758257020999', timeAgo: '5ч назад', winner: '@mara' },
];

export function LobbyScreen() {
  return (
    <div className="font-sans mx-auto flex max-w-sm flex-col gap-3">
      <StatusBar username="@vitalysacred" diamonds={3584} clips={58} keys={34} />
      <PromoBanner totalEarned={25693} />
      <SubscriptionBanner />
      <RoomList rooms={LOBBY_ROOMS} />
      <ArchiveList title="Ваши золотые комнаты" items={LOBBY_GOLDEN_ARCHIVE} />
      <ArchiveList title="Архив комнат" items={LOBBY_ARCHIVE} onShowMore={() => {}} />
      <GameRules />
      <ShareKeys />
      <CharacterFooter />
      <BuyKeysBanner totalEarned={25693} />
    </div>
  );
}
