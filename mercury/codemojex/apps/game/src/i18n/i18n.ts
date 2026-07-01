// react-i18next init (cmt.4.1-D4), ported from the reference shape
// (node/codemoji-design/stories/i18n/i18n.ts): bundled ru/en resources — no fetch,
// no Suspense boundary — behind an isInitialized guard so a second import (tests,
// HMR) never re-inits. The seed is the ruled minimal `smoke.*` set (F-cmt41-3 Arm A);
// the full board.*/game.* namespaces land with the cmt.4.2 components.
import i18n from "i18next";
import { initReactI18next } from "react-i18next";
import en from "./locales/en/translation.json";
import ru from "./locales/ru/translation.json";

export const SUPPORTED_LANGUAGES = ["ru", "en"] as const;
export type Language = (typeof SUPPORTED_LANGUAGES)[number];

if (!i18n.isInitialized) {
  void i18n.use(initReactI18next).init({
    resources: { ru: { translation: ru }, en: { translation: en } },
    supportedLngs: [...SUPPORTED_LANGUAGES],
    fallbackLng: "ru",
    defaultNS: "translation",
    interpolation: { escapeValue: false },
    react: { useSuspense: false },
  });
}

export default i18n;
