/**
 * Конфигурация курсов валют
 *
 * Централизованный конфиг для всех конверсий валют в Codemoji.
 * Единый источник истины для курсов обмена между diamonds, keys, USD и Telegram Stars.
 *
 * Система валют:
 * - DIAMOND (💎) - Призовая валюта (выдается победителям, конвертируется в ключи)
 * - KEY (🔑) - Игровая валюта для попыток угадать
 * - STAR (⭐) - Премиум валюта (Telegram Stars / XTR)
 * - USD ($) - Фиатная валюта для расчетов
 *
 * Курсы обмена:
 * - 1 diamond = $0.012 = 1.2 cents
 * - 1 key = 10 diamonds = $0.12 = 12 cents
 * - 0.1 key = 1 diamond
 *
 * @module shared/libs/consts/currency
 */

/**
 * Интерфейс конфигурации валют
 */
export interface CurrencyConfig {
  /** Стоимость 1 diamond в центах (1 diamond = $0.012 = 1.2 cents) */
  readonly diamondValueCents: number

  /** Стоимость 1 key в центах (1 key = $0.12 = 12 cents) */
  readonly keyValueCents: number

  /** Сколько diamonds равно 1 key (10 diamonds = 1 key) */
  readonly diamondsPerKey: number

  /** Сколько keys равно 1 diamond (0.1 key = 1 diamond) */
  readonly keysPerDiamond: number

  /** Стоимость 1 Telegram Star в центах (~1.3 cents за star) */
  readonly starValueCents: number
}

/**
 * Конфигурация валют - Единый источник истины для курсов обмена
 *
 * @example
 * ```typescript
 * // Получить стоимость diamond в центах
 * const diamondValue = CURRENCY_CONFIG.diamondValueCents; // 1.2
 *
 * // Получить курс обмена
 * const rate = CURRENCY_CONFIG.diamondsPerKey; // 10
 * ```
 */
export const CURRENCY_CONFIG: CurrencyConfig = {
  // Базовые стоимости валют в центах USD
  diamondValueCents: 1.2, // 1 diamond = $0.012 = 1.2 cents
  keyValueCents: 12, // 1 key = $0.12 = 12 cents

  // Курсы обмена
  diamondsPerKey: 10, // 10 diamonds = 1 key
  keysPerDiamond: 0.1, // 0.1 key = 1 diamond

  // Telegram Stars
  starValueCents: 1.3, // 1 star ≈ $0.013 = 1.3 cents (примерно)
} as const

/**
 * Утилиты конвертации валют
 *
 * Предоставляет функции конвертации между всеми поддерживаемыми валютами.
 * Все конвертации используют Math.floor() для получения целых результатов где необходимо.
 *
 * @example
 * ```typescript
 * // Конвертировать diamonds в центы
 * const cents = currencyConverter.diamondsToCents(100); // 120 центов
 *
 * // Конвертировать keys в diamonds
 * const diamonds = currencyConverter.keysToDiamonds(5); // 50 diamonds
 *
 * // Конвертировать центы в keys
 * const keys = currencyConverter.centsToKeys(120); // 10 keys
 * ```
 */
export const currencyConverter = {
  // ─────────────────────────────────────────────────────────────────────────
  // Конвертация Diamond
  // ─────────────────────────────────────────────────────────────────────────

  /**
   * Конвертировать diamonds в центы
   * @param diamonds - Количество diamonds
   * @returns Стоимость в центах (1 diamond = 1.2 cents)
   */
  diamondsToCents: (diamonds: number): number => {
    return diamonds * CURRENCY_CONFIG.diamondValueCents
  },

  /**
   * Конвертировать центы в diamonds (округление вниз до ближайшего diamond)
   * @param cents - Стоимость в центах
   * @returns Количество diamonds (1.2 cents = 1 diamond)
   */
  centsToDiamonds: (cents: number): number => {
    return Math.floor(cents / CURRENCY_CONFIG.diamondValueCents)
  },

  // ─────────────────────────────────────────────────────────────────────────
  // Конвертация Key
  // ─────────────────────────────────────────────────────────────────────────

  /**
   * Конвертировать keys в центы
   * @param keys - Количество keys
   * @returns Стоимость в центах (1 key = 12 cents)
   */
  keysToCents: (keys: number): number => {
    return keys * CURRENCY_CONFIG.keyValueCents
  },

  /**
   * Конвертировать центы в keys (округление вниз до ближайшего key)
   * @param cents - Стоимость в центах
   * @returns Количество keys (12 cents = 1 key)
   */
  centsToKeys: (cents: number): number => {
    return Math.floor(cents / CURRENCY_CONFIG.keyValueCents)
  },

  // ─────────────────────────────────────────────────────────────────────────
  // Конвертация Diamond <-> Key
  // ─────────────────────────────────────────────────────────────────────────

  /**
   * Конвертировать diamonds в keys (округление вниз до ближайшего key)
   * @param diamonds - Количество diamonds
   * @returns Количество keys (10 diamonds = 1 key)
   */
  diamondsToKeys: (diamonds: number): number => {
    return Math.floor(diamonds / CURRENCY_CONFIG.diamondsPerKey)
  },

  /**
   * Конвертировать keys в diamonds
   * @param keys - Количество keys
   * @returns Количество diamonds (1 key = 10 diamonds)
   */
  keysToDiamonds: (keys: number): number => {
    return keys * CURRENCY_CONFIG.diamondsPerKey
  },

  // ─────────────────────────────────────────────────────────────────────────
  // Конвертация Star (Telegram Stars / XTR)
  // ─────────────────────────────────────────────────────────────────────────

  /**
   * Конвертировать Telegram Stars в центы
   * @param stars - Количество Telegram Stars
   * @returns Стоимость в центах (1 star ≈ 1.3 cents)
   */
  starsToCents: (stars: number): number => {
    return stars * CURRENCY_CONFIG.starValueCents
  },

  /**
   * Конвертировать центы в Telegram Stars (округление вниз до ближайшей звезды)
   * @param cents - Стоимость в центах
   * @returns Количество Telegram Stars (1.3 cents ≈ 1 star)
   */
  centsToStars: (cents: number): number => {
    return Math.floor(cents / CURRENCY_CONFIG.starValueCents)
  },

  // ─────────────────────────────────────────────────────────────────────────
  // Конвертация USD (утилиты)
  // ─────────────────────────────────────────────────────────────────────────

  /**
   * Конвертировать центы в доллары USD
   * @param cents - Стоимость в центах
   * @returns Стоимость в долларах USD
   */
  centsToUsd: (cents: number): number => {
    return cents / 100
  },

  /**
   * Конвертировать доллары USD в центы
   * @param usd - Стоимость в долларах USD
   * @returns Стоимость в центах
   */
  usdToCents: (usd: number): number => {
    return Math.floor(usd * 100)
  },

  // ─────────────────────────────────────────────────────────────────────────
  // Форматирование для отображения
  // ─────────────────────────────────────────────────────────────────────────

  /**
   * Форматировать центы в строку USD
   * @param cents - Стоимость в центах
   * @returns Отформатированная строка (например, "$1.20")
   */
  formatCentsAsUsd: (cents: number): string => {
    const dollars = cents / 100
    return `$${dollars.toFixed(2)}`
  },

  /**
   * Форматировать количество diamonds с иконкой
   * @param diamonds - Количество diamonds
   * @returns Отформатированная строка (например, "100")
   */
  formatDiamonds: (diamonds: number): string => {
    return `${diamonds}`
  },

  /**
   * Форматировать количество keys с иконкой
   * @param keys - Количество keys
   * @returns Отформатированная строка (например, "10")
   */
  formatKeys: (keys: number): string => {
    return `${keys}`
  },

  /**
   * Форматировать количество stars с иконкой
   * @param stars - Количество stars
   * @returns Отформатированная строка (например, "50")
   */
  formatStars: (stars: number): string => {
    return `${stars}`
  },
} as const

/**
 * Экспорт типов
 */
export type CurrencyConverter = typeof currencyConverter
