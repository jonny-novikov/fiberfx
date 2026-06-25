import i18n from 'i18next'
import LanguageDetector from 'i18next-browser-languagedetector'
import HttpBackend from 'i18next-http-backend'
import { initReactI18next } from 'react-i18next'

/**
 * i18next configuration with:
 * - HTTP backend for loading translations from /lang folder
 * - Browser language detection (localStorage, navigator, etc.)
 * - Support for ru/en languages
 * - Namespaces: translation (default), withdraw
 */
i18n
  // Load translations using HTTP backend
  .use(HttpBackend)
  // Detect user language
  .use(LanguageDetector)
  // Pass the i18n instance to react-i18next
  .use(initReactI18next)
  // Initialize i18next
  .init({
    // Supported languages
    supportedLngs: ['ru', 'en'],
    // Fallback language
    fallbackLng: 'ru',
    // Default namespace
    defaultNS: 'translation',
    // Available namespaces
    ns: ['translation', 'withdraw', 'onboarding', 'subscription'],

    // Debug mode (enable in development)
    debug: import.meta.env.DEV,

    // Interpolation settings
    interpolation: {
      // React already escapes values
      escapeValue: false,
    },

    // HTTP backend options
    backend: {
      // Path to load translations from
      loadPath: '/lang/{{lng}}/{{ns}}.json',
    },

    // Language detection options
    detection: {
      // Order of detection methods
      order: ['localStorage', 'navigator', 'htmlTag'],
      // Cache user language in localStorage
      caches: ['localStorage'],
      // localStorage key
      lookupLocalStorage: 'i18nextLng',
    },

    // React options
    react: {
      // Wait for translations to load before rendering
      useSuspense: true,
    },
  })

export default i18n
