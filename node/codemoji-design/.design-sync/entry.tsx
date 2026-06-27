// Synthesized bundle barrel for /design-sync.
//
// This repo's React components are co-located with their stories under
// stories/<group>/<Name>.tsx (each story imports its sibling component
// relatively, e.g. `import { Button } from './Button'`). There is no published
// component entry — package.json only exposes ./theme.css and ./tokens — so
// this file is the entry the converter bundles into window.<GLOBAL>. Every
// component is re-exported under a name equal to its filename, which is exactly
// what the story-imports policy matches on (lib/story-imports.mjs rule 2) to
// redirect each story's component import to the shipped bundle.
//
// Committed: the next sync re-reads it. Add a line here when a new component
// file lands under stories/.
import * as React from 'react';
import { I18nextProvider } from 'react-i18next';
import i18n from '../stories/i18n/i18n';

// --- components (group: components) ---
export * from '../stories/components/Button';
export * from '../stories/components/Badge';

// --- board ---
export * from '../stories/board/BalancePill';
export * from '../stories/board/BoardScreen';
export * from '../stories/board/BoardTabs';
export * from '../stories/board/EmojiKeyboard';
export * from '../stories/board/EmojiSlots';
export * from '../stories/board/GameRules';
export * from '../stories/board/GuessActions';
export * from '../stories/board/GuessHistory';
export * from '../stories/board/InfoDashboard';
export * from '../stories/board/KeysBalance';
export * from '../stories/board/Leaderboard';
export * from '../stories/board/PreviousAttempt';
export * from '../stories/board/RoundInfo';
export * from '../stories/board/ShareKeys';
export * from '../stories/board/StatCards';
export * from '../stories/board/StatusBar';

// --- board/lib ---
export * from '../stories/board/lib/BoardCard';
export * from '../stories/board/lib/EmojiTile';
export * from '../stories/board/lib/SpriteEmoji';

// --- golden-game ---
export * from '../stories/golden-game/GoldenAnswerReveal';
export * from '../stories/golden-game/GoldenHero';
export * from '../stories/golden-game/GoldenLeaderboard';
export * from '../stories/golden-game/GoldenScreen';

// --- lobby ---
export * from '../stories/lobby/ArchiveList';
export * from '../stories/lobby/ArchiveRoomItem';
export * from '../stories/lobby/BuyKeysBanner';
export * from '../stories/lobby/CharacterFooter';
export * from '../stories/lobby/LobbyScreen';
export * from '../stories/lobby/NavPhonePanel';
export * from '../stories/lobby/PromoBanner';
export * from '../stories/lobby/RoomCard';
export * from '../stories/lobby/RoomList';
export * from '../stories/lobby/SubscriptionBanner';

// --- screens (composite frames used by the Screens/* stories) ---
export * from '../stories/screens/ScreenView';

// Preview/runtime provider — mirrors .storybook/preview.tsx's decorators
// (withTheme + withI18n) so a compiled preview renders with the same accent
// theme, the app's gradient surface, and the i18n context the Storybook
// reference uses. Wired via cfg.provider (the decorator bundle can't be reused:
// .storybook/preview.tsx imports preview.css → @import 'tailwindcss' and an
// absolute url('/assets/gold.png'), neither esbuild-resolvable). Default
// theme 'orange' + default locale 'ru' (i18n fallbackLng) match the reference.
export function PreviewProvider({ children }: { children?: React.ReactNode }) {
  return (
    <I18nextProvider i18n={i18n}>
      <div
        data-theme="orange"
        className="font-sans bg-gradient-to-b from-bg-from to-bg-to text-muted"
        style={{ minHeight: '100vh', padding: '1.5rem' }}
      >
        {children}
      </div>
    </I18nextProvider>
  );
}
