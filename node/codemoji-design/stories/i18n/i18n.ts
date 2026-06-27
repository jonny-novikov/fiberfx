import i18n from 'i18next';
import { initReactI18next } from 'react-i18next';
import en from './locales/en/translation.json';
import ru from './locales/ru/translation.json';

// react-i18next for the Storybook catalog — the SAME engine the app runs
// (codemoji-app/src/i18n/i18n.ts), trimmed to what a component gallery needs:
//   - resources are BUNDLED (imported JSON), not fetched via HttpBackend, so init
//     is synchronous and no <Suspense> boundary is required (useSuspense: false);
//   - language is driven by the Storybook "Language" toolbar (see .storybook/
//     preview.tsx), so there is no LanguageDetector — the toolbar IS the detector.
// The translation resources are the app's translation.json copied verbatim, plus a
// `board.*` namespace for board-screen copy the app does not key (preserves the
// current Russian; adds English). Default/fallback is Russian, matching the app and
// the screens' authored copy.
export const SUPPORTED_LANGUAGES = ['ru', 'en'] as const;
export type Language = (typeof SUPPORTED_LANGUAGES)[number];

// Guard against re-init across Vite HMR (the module can re-evaluate on edit).
if (!i18n.isInitialized) {
  void i18n.use(initReactI18next).init({
    resources: {
      ru: { translation: ru },
      en: { translation: en },
    },
    supportedLngs: [...SUPPORTED_LANGUAGES],
    fallbackLng: 'ru',
    defaultNS: 'translation',
    interpolation: {
      // React already escapes interpolated values.
      escapeValue: false,
    },
    react: {
      // Resources are bundled, so init resolves synchronously — no Suspense needed.
      useSuspense: false,
    },
  });
}

export default i18n;
