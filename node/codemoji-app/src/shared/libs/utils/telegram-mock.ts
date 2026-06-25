/**
 * Browser Mock for Telegram WebApp SDK
 *
 * Provides a mock implementation of the Telegram WebApp SDK
 * for development in regular browsers (non-Telegram environment).
 *
 * Enabled via VITE_BROWSER_MODE=true (default in development)
 */

/** Check if browser mode is enabled */
export const isBrowserMode = (): boolean => {
  // In development, default to true unless explicitly set to false
  const envValue = import.meta.env.VITE_BROWSER_MODE
  if (envValue === 'false') return false
  if (envValue === 'true') return true
  // Default: true in development, false in production
  return import.meta.env.DEV
}

/** Mock Telegram user for browser development */
export const mockTelegramUser = {
  id: 123456789,
  first_name: 'Dev',
  last_name: 'User',
  username: 'devuser',
  language_code: 'en',
  is_premium: false,
  photo_url: 'https://api.dicebear.com/7.x/avataaars/svg?seed=devuser',
}

/** Mock initData for browser development */
export const mockInitData = 'mock_init_data_for_browser_development'

/**
 * Mock WebApp object for browser development
 * Implements the same interface as @twa-dev/sdk WebApp
 */
export const mockWebApp = {
  // Init data
  initData: mockInitData,
  initDataUnsafe: {
    user: mockTelegramUser,
    auth_date: Math.floor(Date.now() / 1000),
    hash: 'mock_hash_for_development',
  },

  // Version and platform
  version: '7.0',
  platform: 'weba' as const,
  colorScheme: 'light' as const,
  themeParams: {
    bg_color: '#E8F3F7',
    text_color: '#000000',
    hint_color: '#999999',
    link_color: '#2481cc',
    button_color: '#5288c1',
    button_text_color: '#ffffff',
    secondary_bg_color: '#AFC7D6',
  },

  // Viewport
  viewportHeight: window.innerHeight,
  viewportStableHeight: window.innerHeight,
  isExpanded: true,

  // Header and background colors
  headerColor: '#E8F3F7',
  backgroundColor: '#E8F3F7',

  // Methods
  ready: () => {
    console.log('[Browser Mode] WebApp.ready() called')
  },

  expand: () => {
    console.log('[Browser Mode] WebApp.expand() called')
  },

  close: () => {
    console.log('[Browser Mode] WebApp.close() called - would close app')
  },

  setHeaderColor: (color: string) => {
    console.log(`[Browser Mode] WebApp.setHeaderColor('${color}')`)
    document.documentElement.style.setProperty('--tg-theme-header-color', color)
  },

  setBackgroundColor: (color: string) => {
    console.log(`[Browser Mode] WebApp.setBackgroundColor('${color}')`)
    document.documentElement.style.setProperty('--tg-theme-bg-color', color)
    document.body.style.backgroundColor = color
  },

  enableClosingConfirmation: () => {
    console.log('[Browser Mode] WebApp.enableClosingConfirmation() called')
  },

  disableClosingConfirmation: () => {
    console.log('[Browser Mode] WebApp.disableClosingConfirmation() called')
  },

  disableVerticalSwipes: () => {
    console.log('[Browser Mode] WebApp.disableVerticalSwipes() called')
  },

  enableVerticalSwipes: () => {
    console.log('[Browser Mode] WebApp.enableVerticalSwipes() called')
  },

  requestFullscreen: () => {
    console.log('[Browser Mode] WebApp.requestFullscreen() called')
  },

  exitFullscreen: () => {
    console.log('[Browser Mode] WebApp.exitFullscreen() called')
  },

  showAlert: (message: string, callback?: () => void) => {
    alert(message)
    callback?.()
  },

  showConfirm: (message: string, callback?: (confirmed: boolean) => void) => {
    const result = confirm(message)
    callback?.(result)
  },

  showPopup: (
    params: { title?: string; message: string; buttons?: Array<{ type: string; text: string }> },
    callback?: (buttonId: string) => void
  ) => {
    alert(`${params.title ? params.title + '\n' : ''}${params.message}`)
    callback?.('ok')
  },

  sendData: (data: string) => {
    console.log('[Browser Mode] WebApp.sendData() called with:', data)
  },

  openLink: (url: string, options?: { try_instant_view?: boolean }) => {
    console.log(`[Browser Mode] WebApp.openLink('${url}')`, options)
    window.open(url, '_blank', 'noopener,noreferrer')
  },

  openTelegramLink: (url: string) => {
    console.log(`[Browser Mode] WebApp.openTelegramLink('${url}')`)
    window.open(url, '_blank', 'noopener,noreferrer')
  },

  // Back button (mock)
  BackButton: {
    isVisible: false,
    show: () => {
      console.log('[Browser Mode] BackButton.show()')
    },
    hide: () => {
      console.log('[Browser Mode] BackButton.hide()')
    },
    onClick: (callback: () => void) => {
      console.log('[Browser Mode] BackButton.onClick() registered')
      // Could add keyboard listener for Escape key
      document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape') callback()
      })
    },
    offClick: (_callback: () => void) => {
      console.log('[Browser Mode] BackButton.offClick()')
    },
  },

  // Main button (mock)
  MainButton: {
    text: '',
    color: '#5288c1',
    textColor: '#ffffff',
    isVisible: false,
    isActive: true,
    isProgressVisible: false,
    setText: (text: string) => {
      console.log(`[Browser Mode] MainButton.setText('${text}')`)
    },
    show: () => {
      console.log('[Browser Mode] MainButton.show()')
    },
    hide: () => {
      console.log('[Browser Mode] MainButton.hide()')
    },
    enable: () => {
      console.log('[Browser Mode] MainButton.enable()')
    },
    disable: () => {
      console.log('[Browser Mode] MainButton.disable()')
    },
    showProgress: () => {
      console.log('[Browser Mode] MainButton.showProgress()')
    },
    hideProgress: () => {
      console.log('[Browser Mode] MainButton.hideProgress()')
    },
    onClick: (_callback: () => void) => {
      console.log('[Browser Mode] MainButton.onClick() registered')
    },
    offClick: (_callback: () => void) => {
      console.log('[Browser Mode] MainButton.offClick()')
    },
  },

  // HapticFeedback (mock - no-op in browser)
  HapticFeedback: {
    impactOccurred: (_style: string) => {},
    notificationOccurred: (_type: string) => {},
    selectionChanged: () => {},
  },
}

/**
 * Get the WebApp instance - either real or mock
 */
export function getWebApp(): typeof mockWebApp {
  if (isBrowserMode()) {
    return mockWebApp
  }

  // Try to get real WebApp from SDK
  try {
    // Dynamic import would be better but causes issues with SSR

    const realWebApp = (window as any).Telegram?.WebApp
    if (realWebApp) {
      return realWebApp
    }
  } catch {
    // Fall through to mock
  }

  return mockWebApp
}
