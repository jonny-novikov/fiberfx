import { useEffect, useRef, useState } from 'react'

import { TelegramUtils } from '../utils/telegram'

/**
 * Хук для работы с Telegram WebApp
 */
export function useTelegramWebApp() {
  const [isReady, setIsReady] = useState(false)
  const [user, setUser] = useState(TelegramUtils.getUser())
  const [isTelegram, setIsTelegram] = useState(TelegramUtils.isTelegramEnvironment())

  const tgInitialized = useRef(false)

  useEffect(() => {
    if (!tgInitialized.current) {
      TelegramUtils.configureWebApp()
      TelegramUtils.ready()
      tgInitialized.current = true
    }

    setIsReady(true)
    setUser(TelegramUtils.getUser())
    setIsTelegram(TelegramUtils.isTelegramEnvironment())
  }, [])

  return {
    isReady,
    user,
    isTelegram,
    initData: TelegramUtils.getInitData(),
    version: TelegramUtils.getVersion(),
    deviceType: TelegramUtils.getDeviceType(),
    isMobile: TelegramUtils.isMobileDevice(),
    showAlert: TelegramUtils.showAlert,
    showConfirm: TelegramUtils.showConfirm,
    sendData: TelegramUtils.sendData,
    close: TelegramUtils.close,
    openExternal: TelegramUtils.openExternal,
    share: TelegramUtils.share,
    buildShareUrl: TelegramUtils.buildShareUrl,
  }
}

export default useTelegramWebApp
