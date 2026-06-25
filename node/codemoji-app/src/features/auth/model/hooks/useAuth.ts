import type { InitMeta } from '@codemoji/types'
import { useMutation } from '@tanstack/react-query'
import { useAtom, useSetAtom } from 'jotai'
import { useState, useCallback } from 'react'

import { authTelegram } from '../../api/auth.api'
import { isAuthenticatedAtom, isAllowedAtom } from '../store/auth.store'
import { AuthResponse } from '../types/auth.types'

import { playerAtom, playerIdAtom, PlayerInfo } from '@/entities/player'
import { tokenStorage } from '@/shared/api/axios'
import { TelegramUtils } from '@/shared/libs/utils/telegram'

interface TelegramAuthInput {
  initData: string
  initMeta?: InitMeta
}

export const useAuth = () => {
  const [errorMessage, setErrorMessage] = useState<string | null>(null)
  const [isAuthenticated, setIsAuthenticated] = useAtom(isAuthenticatedAtom)
  const [isAllowed, setIsAllowed] = useAtom(isAllowedAtom)
  const setPlayerId = useSetAtom(playerIdAtom)
  const setPlayer = useSetAtom(playerAtom)
  // Мутация для Telegram аутентификации
  const telegramMutation = useMutation<AuthResponse, Error, TelegramAuthInput>({
    mutationFn: ({ initData, initMeta }) => authTelegram(initData, initMeta),
    retry: 30,
    retryDelay: (attemptIndex) => {
      // Прогрессивные задержки: 1, 2, 3, 5, 5, 5... секунд
      if (attemptIndex === 0) return 1000
      if (attemptIndex === 1) return 2000
      if (attemptIndex === 2) return 3000
      return 5000
    },
    onSuccess: (data) => {
      tokenStorage.setTokens(data.token)
      setPlayerId(data.player.id)
      const playerInfo: PlayerInfo = {
        id: data.player.id,
        telegramId: data.player.telegramId,
        firstName: data.player.firstName,
        isPremium: data.player.isPremium,
        createdAt: data.player.createdAt,
        lastActiveAt: data.player.lastActiveAt,
        username: data.player.username,
        lastName: data.player.lastName,
        photoUrl: data.player.photoUrl,
      }
      setPlayer(playerInfo)
      setIsAuthenticated(true)
      setIsAllowed(data.allow)
      setErrorMessage(null)
    },
    onError: (error) => {
      setIsAuthenticated(false)
      setErrorMessage(error.message || 'Ошибка аутентификации')
      console.error('[useAuth] Telegram auth error:', error)
    },
  })

  // Функция для входа через Telegram
  const login = useCallback(() => {
    setErrorMessage(null)

    if (TelegramUtils.isTelegramEnvironment()) {
      const initData = TelegramUtils.getInitData()

      if (!initData) {
        setErrorMessage('Telegram данные недоступны')
        return
      }

      // Collect device metadata for AppFather
      const initMeta = TelegramUtils.getInitMeta()

      telegramMutation.mutate({ initData, initMeta })
    } else {
      setErrorMessage('Приложение должно быть запущено в Telegram')
    }
  }, [telegramMutation])

  // Функция выхода
  const logout = useCallback(() => {
    tokenStorage.clearTokens()
    setIsAuthenticated(false)
    setErrorMessage(null)
  }, [])

  return {
    isAuthenticated,
    isAllowed,
    isPending: telegramMutation.isPending,
    errorMessage,

    // Методы
    login,
    logout,

    // Дополнительные данные мутации (если нужно)
    isError: telegramMutation.isError,
    isSuccess: telegramMutation.isSuccess,
  }
}
