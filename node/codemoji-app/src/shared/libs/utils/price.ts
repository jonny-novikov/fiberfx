/**
 * Утилиты для работы с ценами в приложении
 * Цены хранятся в центах (например, 5200 = 52.00$)
 */

/**
 * Преобразует цену из центов в доллары
 * @param priceInCents - Цена в центах (например, 5200)
 * @returns Цена в долларах (например, 52.00)
 * @example
 * formatPriceToDollars(5200) // returns 52.00
 * formatPriceToDollars(100) // returns 1.00
 * formatPriceToDollars(0) // returns 0.00
 */
export function formatPriceToDollars(priceInCents: number): number {
  return priceInCents / 100
}

/**
 * Преобразует цену из центов в отформатированную строку с символом валюты
 * @param priceInCents - Цена в центах (например, 5200)
 * @param currency - Символ валюты (по умолчанию '$')
 * @param locale - Локаль для форматирования (по умолчанию 'en-US')
 * @returns Отформатированная строка с ценой (например, "$52.00")
 * @example
 * formatPriceToString(5200) // returns "$52.00"
 * formatPriceToString(5200, '€') // returns "€52.00"
 * formatPriceToString(5200, '₽', 'ru-RU') // returns "52,00 ₽"
 */
export function formatPriceToString(
  priceInCents: number,
  currency: string = '$',
  locale: string = 'en-US'
): string {
  const dollars = formatPriceToDollars(priceInCents)

  if (locale === 'en-US') {
    return `${currency}${dollars.toFixed(2)}`
  }

  // Для других локалей используем Intl.NumberFormat
  const formatter = new Intl.NumberFormat(locale, {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  })

  return `${formatter.format(dollars)} ${currency}`
}

/**
 * Преобразует цену из долларов в центы
 * @param priceInDollars - Цена в долларах (например, 52.00)
 * @returns Цена в центах (например, 5200)
 * @example
 * formatPriceToCents(52.00) // returns 5200
 * formatPriceToCents(1.50) // returns 150
 * formatPriceToCents(0.99) // returns 99
 */
export function formatPriceToCents(priceInDollars: number): number {
  return Math.round(priceInDollars * 100)
}

/**
 * Проверяет, является ли значение валидной ценой в центах
 * @param value - Проверяемое значение
 * @returns true, если значение является валидной ценой (целое неотрицательное число)
 * @example
 * isValidPrice(5200) // returns true
 * isValidPrice(-100) // returns false
 * isValidPrice(52.5) // returns false
 * isValidPrice(NaN) // returns false
 */
export function isValidPrice(value: unknown): value is number {
  return (
    typeof value === 'number' &&
    !isNaN(value) &&
    isFinite(value) &&
    value >= 0 &&
    Number.isInteger(value)
  )
}

/**
 * Преобразует цену с безопасной проверкой типа
 * @param priceInCents - Цена в центах или неизвестное значение
 * @param defaultValue - Значение по умолчанию, если цена невалидна
 * @returns Цена в долларах или значение по умолчанию
 * @example
 * safePriceToDollars(5200) // returns 52.00
 * safePriceToDollars(null, 0) // returns 0
 * safePriceToDollars(undefined, 10) // returns 10
 */
export function safePriceToDollars(priceInCents: unknown, defaultValue: number = 0): number {
  if (isValidPrice(priceInCents)) {
    return formatPriceToDollars(priceInCents)
  }
  return defaultValue
}
