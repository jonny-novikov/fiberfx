// Screen-catalog data — reads the gameplay manifest (the source of truth for the
// game-screen reference set) and resolves each screen's reference PNG to the URL
// Storybook serves it at. The manifest's `asset` is "assets/<file>.png"; the
// .storybook staticDirs maps gameplay/assets -> /gameplay, so the served URL is
// "/gameplay/<file>.png".
import manifest from '../../gameplay/manifest.json';

// The two Golden Room screens (boost-class), flagged in the catalog.
export const GOLDEN_SCREEN_IDS = ['1089:19410', '1108:27589'];

const assetUrl = (asset) => '/gameplay/' + String(asset).replace(/^assets\//, '');

export const categories = manifest.categories;

export const screens = manifest.screens.map((s) => ({
  ...s,
  url: assetUrl(s.asset),
  isGolden: GOLDEN_SCREEN_IDS.includes(s.figma_id),
}));

// screens grouped by category id, in the manifest's category order.
export const screensByCategory = categories.map((c) => ({
  ...c,
  screens: screens.filter((s) => s.category === c.id),
}));

export const counts = {
  screens: screens.length,
  categories: categories.length,
  manifestScreens: manifest.screens.length,
  golden: screens.filter((s) => s.isGolden).length,
};

// ── Curated single-screen groups for the dedicated per-screen stories ──
// (Screens/Rooms (Lobby), Screens/Game (Free), Screens/Golden Game.) Derived
// from the manifest — no ids hardcoded beyond GOLDEN_SCREEN_IDS above — so these
// track the export. "canonical" = the screen whose manifest role marks it the
// canonical master component, else the first in the group.
const canonicalOf = (group) => group.find((s) => /canonical/i.test(s.role)) ?? group[0];

// Rooms (Lobby): the rooms category minus the Golden Room screens.
export const roomsLobbyScreens = screens.filter((s) => s.category === 'rooms' && !s.isGolden);
export const roomsLobbyCanonical = canonicalOf(roomsLobbyScreens);

// Game (Free): the gameplay board set (the boost lives on the room, not the board).
export const boardScreens = screens.filter((s) => s.category === 'board');
export const boardCanonical = canonicalOf(boardScreens);

// Golden Game: the two boost-class Golden Room states (open in progress / settled).
export const goldenScreens = screens.filter((s) => s.isGolden);
export const goldenInProgress = goldenScreens.find((s) => s.game_state === 'open');
export const goldenFinished = goldenScreens.find((s) => s.game_state === 'settled');
