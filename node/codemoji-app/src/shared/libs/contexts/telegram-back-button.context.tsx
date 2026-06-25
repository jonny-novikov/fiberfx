import WebApp from '@twa-dev/sdk'
import { createContext, useContext, useCallback, useRef, useEffect, type ReactNode } from 'react'

interface BackButtonHandler {
  id: string
  onClick: () => void
  show: boolean
}

interface TelegramBackButtonContextValue {
  register: (id: string, onClick: () => void, show: boolean) => void
  unregister: (id: string) => void
  update: (id: string, onClick: () => void, show: boolean) => void
}

const TelegramBackButtonContext = createContext<TelegramBackButtonContextValue | null>(null)

interface TelegramBackButtonProviderProps {
  children: ReactNode
}

/**
 * Провайдер для централизованного управления кнопкой "Назад" в Telegram WebApp
 * Реализует систему стека обработчиков - активен последний зарегистрированный
 */
export function TelegramBackButtonProvider({ children }: TelegramBackButtonProviderProps) {
  const handlersRef = useRef<BackButtonHandler[]>([])
  const currentHandlerRef = useRef<(() => void) | null>(null)

  // Применить текущий активный обработчик
  const applyActiveHandler = useCallback(() => {
    try {
      // Находим последний обработчик с show: true
      const activeHandler = [...handlersRef.current].reverse().find((h) => h.show)

      if (activeHandler) {
        // Удаляем старый обработчик если он отличается
        if (currentHandlerRef.current && currentHandlerRef.current !== activeHandler.onClick) {
          WebApp?.BackButton?.offClick(currentHandlerRef.current)
        }

        // Устанавливаем новый обработчик только если он изменился
        if (currentHandlerRef.current !== activeHandler.onClick) {
          currentHandlerRef.current = activeHandler.onClick
          WebApp?.BackButton?.onClick(activeHandler.onClick)
        }

        WebApp?.BackButton?.show()
      } else {
        // Нет активных обработчиков - скрываем кнопку
        if (currentHandlerRef.current) {
          WebApp?.BackButton?.offClick(currentHandlerRef.current)
          currentHandlerRef.current = null
        }
        WebApp?.BackButton?.hide()
      }
    } catch (error) {
      console.warn('[TelegramBackButton] Ошибка при обновлении обработчика:', error)
    }
  }, [])

  // Регистрация нового обработчика
  const register = useCallback(
    (id: string, onClick: () => void, show: boolean) => {
      // Удаляем старый обработчик с таким же id если есть
      handlersRef.current = handlersRef.current.filter((h) => h.id !== id)
      // Добавляем новый
      handlersRef.current.push({ id, onClick, show })

      applyActiveHandler()
    },
    [applyActiveHandler]
  )

  // Удаление обработчика
  const unregister = useCallback(
    (id: string) => {
      handlersRef.current = handlersRef.current.filter((h) => h.id !== id)
      applyActiveHandler()
    },
    [applyActiveHandler]
  )

  // Обновление обработчика
  const update = useCallback(
    (id: string, onClick: () => void, show: boolean) => {
      // Удаляем старый и добавляем обновленный
      handlersRef.current = handlersRef.current.filter((h) => h.id !== id)
      handlersRef.current.push({ id, onClick, show })

      applyActiveHandler()
    },
    [applyActiveHandler]
  )

  // При размонтировании провайдера - очищаем все
  useEffect(() => {
    return () => {
      try {
        if (currentHandlerRef.current) {
          WebApp?.BackButton?.offClick(currentHandlerRef.current)
        }
        WebApp?.BackButton?.hide()
      } catch (error) {
        console.warn('[TelegramBackButton] Ошибка при очистке:', error)
      }
    }
  }, [])

  const value: TelegramBackButtonContextValue = {
    register,
    unregister,
    update,
  }

  return (
    <TelegramBackButtonContext.Provider value={value}>
      {children}
    </TelegramBackButtonContext.Provider>
  )
}

/**
 * Хук для использования контекста кнопки "Назад"
 */
export function useTelegramBackButtonContext() {
  const context = useContext(TelegramBackButtonContext)

  if (!context) {
    throw new Error(
      'useTelegramBackButtonContext должен использоваться внутри TelegramBackButtonProvider'
    )
  }

  return context
}
