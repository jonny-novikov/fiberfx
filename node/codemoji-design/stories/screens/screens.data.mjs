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
