import * as React from 'react';
// Reused straight from the board — the design-system payoff: these two are the SAME
// components the gameplay board uses, composed here into a different screen.
import { GameRules } from '../board/GameRules';
import { ShareKeys } from '../board/ShareKeys';
// Lobby-specific components.
import { NavPhonePanel } from './NavPhonePanel';
import { StatusBar } from '../board/StatusBar';
import { SubscriptionBanner } from './SubscriptionBanner';
import { PromoBanner } from './PromoBanner';
import { RoomList } from './RoomList';
import { ArchiveList } from './ArchiveList';
import { BuyKeysBanner } from './BuyKeysBanner';
import { CharacterFooter } from './CharacterFooter';

// The whole Rooms→Lobby screen (121:2056) assembled from the design system, in the
// Figma master's vertical order: phone chrome → resources bar → earnings promo →
// "Тысяча" hero → [the rounded sheet:] the room list → your golden rooms → the room
// archive → rules → share → mascot → a repeated promo. Text + sizes track Figma
// (375-wide frame, real Russian copy).
//
// LAYOUT (Figma 121:2056): two bands. The UPPER band (chrome + resources + earnings
// promo + the dark "Тысяча" hero) floats on the board's "All Screen Fill" gradient
// (--color-bg-app-from → --color-bg-app-to) — the Operator's ruling is the lobby
// takes the Game (Free)/Board background, NOT the designer's black backdrop. The
// LOWER band is a full-bleed ROUNDED SHEET (Figma "Frame 139", fill #D8E4EB =
// --color-background, top corners r≈26) that the room list and everything below sit
// on; the sheet slides up over the gradient band.
//
// COLOR is the design system's role layer (blue room-entry / orange purchase where
// Figma is black — the deliberate drift the Screens/Rooms (Lobby) view surfaces).
// GameRules / ShareKeys / StatusBar are REUSED from the board. Static sample data.
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

// The board's "All Screen Fill" gradient (Figma 94:2974 fill) — top-light to
// bottom-blue, on the design system's bg tokens. Verified against Figma: the gradient
// stops are #E8F3F7 → #AFC7D6, exactly --color-bg-app-from → --color-bg-app-to.
const SCREEN_FILL = 'linear-gradient(180deg, var(--color-bg-app-from), var(--color-bg-app-to))';

export function LobbyScreen() {
  return (
    <div className="font-sans" style={{ background: SCREEN_FILL }}>
      {/* phone chrome — full-bleed (status bar to the corners), near the top */}
      <NavPhonePanel />
      <div className="mx-auto max-w-sm">
        {/* UPPER band — floats on the board gradient, inset ≈8px like the master */}
        <div className="flex flex-col gap-2 px-2 pt-2">
          <StatusBar username="@vitalysacred" diamonds={3584} clips={58} keys={34} />
          <PromoBanner totalEarned={25693} />
          <SubscriptionBanner />
        </div>
        {/* LOWER band — the rounded "rooms" sheet (Figma Frame 139): a full-bleed
            #D8E4EB (--color-background) panel with rounded top corners (r≈26) that
            the room list + everything below sit on. The cards keep the master's
            ≈8px side inset; the sheet itself runs edge-to-edge. ELEVATION: Figma's
            sheet reads because it sits on a black backdrop; under the board-gradient
            override the sheet fill (#D8E4EB) equals the gradient at this height, so
            an upward drop-shadow + a 1px top highlight is what makes the rounded box
            read against the gradient (the rounding is otherwise zero-contrast). */}
        <div
          className="relative z-10 mt-2 flex flex-col gap-2 rounded-t-[26px] bg-background px-2 pb-10 pt-6"
          style={{
            boxShadow:
              '0 -1px 0 rgba(255,255,255,0.7), 0 -5px 22px rgba(31,45,61,0.20), 0 -16px 40px rgba(31,45,61,0.10)',
          }}
        >
          <RoomList rooms={LOBBY_ROOMS} />
          <ArchiveList title="Ваши золотые комнаты" items={LOBBY_GOLDEN_ARCHIVE} />
          <ArchiveList title="Архив комнат" items={LOBBY_ARCHIVE} onShowMore={() => {}} />
          <GameRules />
          <ShareKeys />
          <CharacterFooter />
          <BuyKeysBanner totalEarned={25693} />
        </div>
      </div>
    </div>
  );
}
