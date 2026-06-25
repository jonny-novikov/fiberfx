import { useEffect, useRef, useMemo, useCallback } from 'react'

import { useTelegramBackButtonContext } from '../contexts/telegram-back-button.context'

import type { UseTelegramBackButtonOptions, TelegramBackButtonControls } from './types'

/**
 * Хук для работы с кнопкой "Назад" в Telegram WebApp
 * Использует систему стека обработчиков - последний зарегистрированный обработчик активен
 *
 * @example
 * // Простое использование с автоматической навигацией назад
 * useTelegramBackButton();
 *
 * @example
 * // С кастомным обработчиком
 * useTelegramBackButton({
 *   onClick: () => {
 *     // Ваша логика
 *     navigate(-1);
 *   }
 * });
 *
 * @example
 * // Управление видимостью
 * useTelegramBackButton({
 *   show: isModalOpen,
 *   onClick: () => setIsModalOpen(false)
 * });
 */
export function useTelegramBackButton(
  options: UseTelegramBackButtonOptions = {}
): TelegramBackButtonControls {
  const { onClick, show = true } = options
  const context = useTelegramBackButtonContext()

  // Генерируем уникальный ID для этого экземпляра хука
  const handlerId = useRef(`handler-${Math.random().toString(36).substr(2, 9)}`).current

  // Сохраняем onClick в ref чтобы не пересоздавать handleClick
  const onClickRef = useRef(onClick)
  useEffect(() => {
    onClickRef.current = onClick
  }, [onClick])

  // Стабильный обработчик клика
  const handleClick = useCallback(() => {
    if (onClickRef.current) {
      onClickRef.current()
    }
  }, [])

  // Регистрируем/обновляем при монтировании и изменении show
  useEffect(() => {
    context.register(handlerId, handleClick, show)

    return () => {
      context.unregister(handlerId)
    }
    // handleClick стабилен, поэтому не включаем в зависимости
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [context, handlerId, show])

  // Возвращаем API для ручного управления (опционально)
  return useMemo(
    () => ({
      show: () => context.update(handlerId, handleClick, true),
      hide: () => context.update(handlerId, handleClick, false),
      setOnClick: (newHandler: () => void) => {
        onClickRef.current = newHandler
        context.update(handlerId, handleClick, show)
      },
      removeOnClick: () => context.unregister(handlerId),
      isVisible: show,
    }),
    [context, handlerId, handleClick, show]
  )
}

export default useTelegramBackButton
