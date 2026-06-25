/**
 * Telegram WebApp global type declarations
 *
 * Extends the Window interface with Telegram WebApp API.
 * Used for direct window.Telegram access when @twa-dev/sdk isn't suitable.
 */

declare global {
  interface Window {
    Telegram?: {
      WebApp: {
        /** Raw init data string for auth validation */
        initData: string

        /** Parsed init data */
        initDataUnsafe: {
          user?: {
            id: number
            first_name: string
            last_name?: string
            username?: string
            language_code?: string
            is_premium?: boolean
          }
          query_id?: string
          auth_date: number
          hash: string
        }

        /** WebApp version */
        version: string

        /** Platform: ios, android, tdesktop, macos, weba */
        platform: string

        /** Color scheme: light or dark */
        colorScheme: 'light' | 'dark'

        /** Notify that app is ready */
        ready: () => void

        /** Close the WebApp */
        close: () => void

        /** Expand to full height */
        expand: () => void

        /**
         * Open Telegram Stars payment invoice
         * @param url Invoice URL from backend (tg://invoice/... or https://t.me/$pay/invoice/...)
         * @param callback Called with payment status: 'paid', 'cancelled', 'failed', 'pending'
         */
        openInvoice: (url: string, callback: (status: string) => void) => void

        /**
         * Show popup dialog
         */
        showPopup?: (params: {
          title?: string
          message: string
          buttons?: Array<{
            id?: string
            type?: 'default' | 'ok' | 'close' | 'cancel' | 'destructive'
            text?: string
          }>
        }, callback?: (buttonId: string) => void) => void

        /** Show simple alert */
        showAlert?: (message: string, callback?: () => void) => void

        /** Show confirm dialog */
        showConfirm?: (message: string, callback?: (confirmed: boolean) => void) => void

        /** Haptic feedback */
        HapticFeedback?: {
          /** Trigger notification feedback */
          notificationOccurred: (type: 'success' | 'warning' | 'error') => void
          /** Trigger impact feedback */
          impactOccurred: (style: 'light' | 'medium' | 'heavy' | 'rigid' | 'soft') => void
          /** Trigger selection feedback */
          selectionChanged: () => void
        }

        /** Main button at bottom of screen */
        MainButton?: {
          text: string
          color: string
          textColor: string
          isVisible: boolean
          isActive: boolean
          isProgressVisible: boolean
          setText: (text: string) => void
          onClick: (callback: () => void) => void
          offClick: (callback: () => void) => void
          show: () => void
          hide: () => void
          enable: () => void
          disable: () => void
          showProgress: (leaveActive?: boolean) => void
          hideProgress: () => void
        }

        /** Back button in header */
        BackButton?: {
          isVisible: boolean
          onClick: (callback: () => void) => void
          offClick: (callback: () => void) => void
          show: () => void
          hide: () => void
        }

        /** Open external link */
        openLink?: (url: string, options?: { try_instant_view?: boolean }) => void

        /** Open Telegram link (t.me) */
        openTelegramLink?: (url: string) => void

        /** Send data to bot */
        sendData?: (data: string) => void

        /** Set header color */
        setHeaderColor?: (color: string) => void

        /** Set background color */
        setBackgroundColor?: (color: string) => void

        /** Disable vertical swipes */
        disableVerticalSwipes?: () => void

        /** Request fullscreen mode */
        requestFullscreen?: () => void
      }
    }
  }
}

export {}
