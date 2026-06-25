import { collectInitMeta, type InitMeta } from '@codemoji/types'
import WebApp from '@twa-dev/sdk'

import { getWebApp, isBrowserMode, mockInitData, mockTelegramUser } from './telegram-mock'

/**
 * Параметры виджет-ссылки для сторис
 */
export interface StoryWidgetLink {
  /** URL, который откроется при нажатии на виджет */
  url: string
  /** Текст кнопки виджета (по умолчанию "Открыть") */
  name?: string
}

/**
 * Параметры для создания сторис
 */
export interface ShareToStoryParams {
  /** URL медиа-файла (изображение или видео) */
  mediaUrl: string
  /** Текст для сторис */
  text?: string
  /** Виджет-ссылка, отображаемая в сторис */
  widgetLink?: StoryWidgetLink
}

/**
 * Результат проверки доступности сторис
 */
export interface StoryAvailabilityResult {
  available: boolean
  version?: string
  reason?: string
}

/**
 * Утилиты для работы с Telegram WebApp
 * Supports browser mode for development (VITE_BROWSER_MODE=true)
 */
export class TelegramUtils {
  /**
   * Check if running in browser development mode
   */
  static isBrowserMode(): boolean {
    return isBrowserMode()
  }

  /**
   * Get the WebApp instance (real or mock)
   */
  private static getWebApp() {
    return isBrowserMode() ? getWebApp() : WebApp
  }

  /**
   * Получить initData для авторизации
   *
   * IMPORTANT: Uses window.Telegram.WebApp.initData directly (NOT @twa-dev/sdk)
   * The SDK may process/modify initData, causing "Invalid init data" errors
   * from AppFather Partner API. Raw initData from window object is correct.
   */
  static getInitData(): string | null {
    try {
      if (isBrowserMode()) {
        return mockInitData
      }
      // Use raw window.Telegram.WebApp.initData (NOT SDK's WebApp.initData)
      // The @twa-dev/sdk may modify the initData, breaking signature verification
      if (typeof window !== 'undefined' && window.Telegram?.WebApp?.initData) {
        return window.Telegram.WebApp.initData
      }
      return null
    } catch (error) {
      console.warn('Ошибка при получении Telegram initData:', error)
      return isBrowserMode() ? mockInitData : null
    }
  }

  /**
   * Получить информацию о пользователе Telegram
   */
  static getUser() {
    try {
      if (isBrowserMode()) {
        return mockTelegramUser
      }
      return WebApp?.initDataUnsafe?.user || null
    } catch (error) {
      console.warn('Ошибка при получении данных пользователя Telegram:', error)
      return isBrowserMode() ? mockTelegramUser : null
    }
  }

  /**
   * Проверить, запущено ли приложение в Telegram
   * Returns true in browser mode to allow development
   */
  static isTelegramEnvironment(): boolean {
    try {
      // In browser mode, return true to allow app to function
      if (isBrowserMode()) {
        return true
      }
      return !!(WebApp && WebApp.initData)
    } catch (error) {
      console.warn('Ошибка при проверке Telegram Environment:', error)
      return isBrowserMode()
    }
  }

  /**
   * Получить версию Telegram WebApp
   */
  static getVersion(): string | null {
    try {
      const wa = this.getWebApp()
      return wa?.version || null
    } catch (error) {
      console.warn('Ошибка при получении версии Telegram WebApp:', error)
      return null
    }
  }

  /**
   * Определить тип устройства
   */
  static getDeviceType(): 'mobile' | 'desktop' | 'unknown' {
    try {
      const wa = this.getWebApp()
      if (!wa) return 'unknown'

      const platform = wa.platform
      if (platform === 'ios' || platform === 'android') {
        return 'mobile'
      } else if (platform === 'tdesktop' || platform === 'macos' || platform === 'weba') {
        return 'desktop'
      }

      return 'unknown'
    } catch (error) {
      console.warn('Ошибка при определении типа устройства:', error)
      return 'unknown'
    }
  }

  /**
   * Проверить, является ли устройство мобильным
   */
  static isMobileDevice(): boolean {
    return this.getDeviceType() === 'mobile'
  }

  /**
   * Collect device metadata for AppFather authentication
   * Uses smart fingerprinting and platform detection
   */
  static getInitMeta(): InitMeta {
    const wa = this.getWebApp()
    return collectInitMeta(wa?.platform)
  }

  /**
   * Настроить внешний вид WebApp
   */
  static configureWebApp() {
    try {
      const wa = this.getWebApp() as any
      if (!wa) return

      // Log browser mode
      if (isBrowserMode()) {
        console.log('[Browser Mode] Configuring WebApp mock')
      }

      // Расширить на весь экран в зависимости от типа устройства
      const deviceType = this.getDeviceType()

      if (deviceType === 'mobile') {
        if (wa.requestFullscreen) {
          wa.requestFullscreen()
        }
      }

      // Отключить вертикальные свайпы
      if (wa.disableVerticalSwipes) {
        wa.disableVerticalSwipes()
      }

      // Установить цвета темы
      if (wa.setHeaderColor) {
        wa.setHeaderColor('#E8F3F7')
      }

      if (wa.setBackgroundColor) {
        wa.setBackgroundColor('#AFC7D6')
      }

      // Показать основную кнопку если нужно
      if (wa.MainButton) {
        wa.MainButton.hide()
      }
    } catch (error) {
      console.warn('Ошибка при настройке Telegram WebApp:', error)
    }
  }

  /**
   * Уведомить Telegram о готовности приложения
   */
  static ready() {
    try {
      const wa = this.getWebApp() as any
      if (wa?.ready) {
        wa.ready()
      }
    } catch (error) {
      console.warn('Ошибка при вызове WebApp.ready():', error)
    }
  }

  /**
   * Отправить данные обратно в Telegram
   */
  static sendData(data: string) {
    try {
      const wa = this.getWebApp() as any
      if (wa?.sendData) {
        wa.sendData(data)
      }
    } catch (error) {
      console.warn('Ошибка при отправке данных в Telegram:', error)
    }
  }

  /**
   * Закрыть WebApp
   */
  static close() {
    try {
      const wa = this.getWebApp() as any
      if (wa?.close) {
        wa.close()
      }
    } catch (error) {
      console.warn('Ошибка при закрытии WebApp:', error)
    }
  }

  /**
   * Haptic feedback - тактильная отдача (вибрация)
   * @param style - стиль вибрации: 'light' | 'medium' | 'heavy' | 'rigid' | 'soft'
   */
  static impactOccurred(style: 'light' | 'medium' | 'heavy' | 'rigid' | 'soft' = 'light') {
    try {
      const wa = this.getWebApp() as any
      wa?.HapticFeedback?.impactOccurred?.(style)
    } catch (error) {
      console.warn('Ошибка при вызове HapticFeedback.impactOccurred:', error)
      // Игнорируем ошибки haptic feedback
    }
  }

  /**
   * Haptic feedback - уведомление
   * @param type - тип уведомления: 'success' | 'warning' | 'error'
   */
  static notificationOccurred(type: 'success' | 'warning' | 'error') {
    try {
      const wa = this.getWebApp() as any
      wa?.HapticFeedback?.notificationOccurred?.(type)
    } catch (error) {
      console.warn('Ошибка при вызове HapticFeedback.notificationOccurred:', error)
      // Игнорируем ошибки haptic feedback
    }
  }

  /**
   * Haptic feedback - изменение выбора (короткая лёгкая вибрация)
   */
  static selectionChanged() {
    try {
      const wa = this.getWebApp() as any
      wa?.HapticFeedback?.selectionChanged?.()
    } catch (error) {
      console.warn('Ошибка при вызове HapticFeedback.selectionChanged:', error)
      // Игнорируем ошибки haptic feedback
    }
  }

  /**
   * Показать всплывающее сообщение
   */
  static showAlert(message: string, callback?: () => void) {
    try {
      const wa = this.getWebApp() as any
      if (wa?.showAlert) {
        wa.showAlert(message, callback)
      } else {
        alert(message)
        if (callback) callback()
      }
    } catch (error) {
      console.warn('Ошибка при показе уведомления:', error)
      alert(message)
      if (callback) callback()
    }
  }

  /**
   * Показать подтверждение
   */
  static showConfirm(message: string, callback?: (confirmed: boolean) => void) {
    try {
      const wa = this.getWebApp() as any
      if (wa?.showConfirm) {
        wa.showConfirm(message, callback)
      } else {
        const result = confirm(message)
        if (callback) callback(result)
      }
    } catch (error) {
      console.warn('Ошибка при показе подтверждения:', error)
      const result = confirm(message)
      if (callback) callback(result)
    }
  }

  /**
   * Открыть внешнюю ссылку корректно в Telegram WebApp, не закрывая мини‑приложение
   *
   * Поведение:
   * - Внутри Telegram: используем WebApp.openLink (если доступно)
   * - Fallback: window.open с безопасными флагами
   */
  static openExternal(url: string, options?: { tryInstantView?: boolean }) {
    try {
      const safeUrl = url?.trim()
      if (!safeUrl) return

      // Нормализация t.me ссылок, чтобы Telegram корректно открыл канал/бота
      const normalizedUrl = safeUrl.startsWith('http')
        ? safeUrl
        : `https://${safeUrl.replace(/^\/\//, '')}`

      // Попытка использовать родной метод SDK
      // @twa-dev/sdk типы могут не включать второй аргумент во всех версиях, поэтому без строгой типизации

      const wa: any = WebApp
      if (wa && typeof wa.openLink === 'function') {
        wa.openLink(normalizedUrl, {
          try_instant_view: !!options?.tryInstantView,
        })
        return
      }

      // Фоллбек вне Telegram или если метод отсутствует
      window.open(normalizedUrl, '_blank', 'noopener,noreferrer')
    } catch (error) {
      console.warn('Ошибка при открытии внешней ссылки:', error)
      try {
        window.open(url, '_blank', 'noopener,noreferrer')
      } catch (_) {
        // ignore
      }
    }
  }

  /**
   * Сформировать корректный URL для Telegram Share: https://t.me/share/url
   */
  static buildShareUrl(params: { text?: string; url?: string }) {
    const parts: string[] = []
    if (params.text) parts.push(`text=${encodeURIComponent(params.text)}`)
    if (params.url) parts.push(`url=${encodeURIComponent(params.url)}`)
    return `https://t.me/share/url?${parts.join('&')}`
  }

  /**
   * Открыть Telegram‑ссылку (t.me, tg://, @username) внутри WebApp с фолбэком
   */
  static openTelegramLink(url: string) {
    try {
      const raw = url?.trim()
      if (!raw) return

      // Поддержка коротких форм: @username, t.me/..., tg://...
      let normalized = raw
      if (raw.startsWith('@')) {
        normalized = `https://t.me/${raw.slice(1)}`
      } else if (/^t\.me\//i.test(raw)) {
        normalized = `https://${raw.replace(/^\/\//, '')}`
      } else if (raw.startsWith('http://t.me/')) {
        normalized = raw.replace('http://', 'https://')
      }

      const wa: any = WebApp
      if (wa && typeof wa.openTelegramLink === 'function') {
        wa.openTelegramLink(normalized)
        return
      }

      // Фолбэк: открыть как внешнюю ссылку
      this.openExternal(normalized)
    } catch (error) {
      console.warn('Ошибка при открытии Telegram ссылки:', error)
      try {
        this.openExternal(url)
      } catch (_) {
        // ignore
      }
    }
  }

  /**
   * Открыть Telegram Share (внутри Telegram — через openTelegramLink)
   */
  static share(params: { text?: string; url?: string }) {
    try {
      const shareUrl = this.buildShareUrl(params)

      const wa: any = WebApp
      if (wa && typeof wa.openTelegramLink === 'function') {
        wa.openTelegramLink(shareUrl)
        return
      }
      window.open(shareUrl, '_blank', 'noopener,noreferrer')
    } catch (error) {
      console.warn('Ошибка при открытии Telegram Share:', error)
      try {
        const shareUrl = this.buildShareUrl(params)
        window.open(shareUrl, '_blank', 'noopener,noreferrer')
      } catch (_) {
        // ignore
      }
    }
  }

  /**
   * Проверить доступность функционала сторис
   * Требуется версия WebApp API >= 7.8
   */
  static isStoryAvailable(): boolean {
    try {
      if (!this.isTelegramEnvironment()) {
        return false
      }

      // Telegram Desktop имеет shareToStory API, но не может публиковать сторис.
      // Блокируем до вызова бэкенда, чтобы не создавать pending-записи.
      if (!this.isMobileDevice()) {
        return false
      }

      const wa = this.getWebApp() as any
      return !!(wa && typeof wa.shareToStory === 'function')
    } catch (error) {
      console.warn('Ошибка при проверке доступности сторис:', error)
      return false
    }
  }

  /**
   * Получить детальную информацию о доступности сторис
   */
  static getStoryAvailability(): StoryAvailabilityResult {
    try {
      if (!this.isTelegramEnvironment()) {
        return {
          available: false,
          reason: 'Not in Telegram environment',
        }
      }

      if (!this.isMobileDevice()) {
        return {
          available: false,
          reason: 'Stories are not available on desktop Telegram clients',
        }
      }

      const wa = this.getWebApp() as any
      const version = wa?.version || 'unknown'
      const hasApi = !!(wa && typeof wa.shareToStory === 'function')

      return {
        available: hasApi,
        version,
        reason: hasApi ? undefined : 'shareToStory method not available (requires WebApp >= 7.8)',
      }
    } catch (error) {
      return {
        available: false,
        reason: `Error: ${error instanceof Error ? error.message : String(error)}`,
      }
    }
  }

  /**
   * Нормализовать URL медиа-файла (сделать абсолютным)
   */
  private static normalizeMediaUrl(url: string): string {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url
    }
    const baseUrl = window.location.origin
    return `${baseUrl}${url.startsWith('/') ? '' : '/'}${url}`
  }

  /**
   * Поделиться в сторис Telegram
   *
   * @param params - параметры для создания сторис
   * @returns Promise<boolean> - true если вызов API успешен
   * @throws Error если сторис недоступны или произошла ошибка
   *
   * @example
   * ```ts
   * // Простое использование с изображением
   * await TelegramUtils.shareToStory({ mediaUrl: 'https://example.com/image.jpg' })
   *
   * // С текстом и виджет-ссылкой
   * await TelegramUtils.shareToStory({
   *   mediaUrl: 'https://example.com/video.mp4',
   *   text: 'Смотри что я нашёл!',
   *   widgetLink: {
   *     url: 'https://t.me/mybot/app',
   *     name: 'Открыть приложение'
   *   }
   * })
   * ```
   */
  static async shareToStory(params: ShareToStoryParams): Promise<boolean> {
    const { mediaUrl, text, widgetLink } = params

    if (!mediaUrl) {
      throw new Error('mediaUrl is required')
    }

    if (!this.isStoryAvailable()) {
      const availability = this.getStoryAvailability()
      throw new Error(`Story functionality is not available: ${availability.reason}`)
    }

    try {
      const wa = this.getWebApp() as any
      const normalizedUrl = this.normalizeMediaUrl(mediaUrl)

      // Формируем опции для API
      const storyOptions: Record<string, unknown> = {}

      if (text) {
        storyOptions.text = text
      }

      if (widgetLink) {
        storyOptions.widget_link = {
          url: widgetLink.url,
          name: widgetLink.name || 'Открыть',
        }
      }

      // Вызов API: shareToStory(media_url, params?)
      wa.shareToStory(
        normalizedUrl,
        Object.keys(storyOptions).length > 0 ? storyOptions : undefined
      )

      return true
    } catch (error) {
      console.error('Ошибка при создании сторис:', error)
      throw error
    }
  }

  /**
   * Упрощённый метод для быстрого шаринга в сторис
   *
   * @param mediaUrl - URL изображения или видео
   * @param text - опциональный текст
   */
  static async shareMediaToStory(mediaUrl: string, text?: string): Promise<boolean> {
    return this.shareToStory({ mediaUrl, text })
  }
}

export default TelegramUtils
