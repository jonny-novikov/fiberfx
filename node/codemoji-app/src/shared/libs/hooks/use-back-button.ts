import { useCallback } from 'react'
import { useNavigate } from 'react-router-dom'

import type { UseBackButtonOptions, BackButtonControls } from './types'
import { useTelegramBackButton } from './use-telegram-back-button'

/**
 * Удобный хук для работы с кнопкой "Назад", который автоматически
 * интегрируется с React Router
 *
 * @example
 * // Автоматическая навигация назад при нажатии
 * useBackButton();
 *
 * @example
 * // Навигация на конкретный путь
 * useBackButton({ navigateTo: '/rooms' });
 *
 * @example
 * // Кастомная логика перед навигацией
 * useBackButton({
 *   onClick: () => {
 *     saveData();
 *     navigate('/rooms');
 *   }
 * });
 *
 * @example
 * // Условное отображение кнопки
 * useBackButton({ show: isModalOpen });
 */
export function useBackButton(options: UseBackButtonOptions = {}): BackButtonControls {
  const { onClick, navigateTo, show = true, disableAutoNavigate = false } = options
  const navigate = useNavigate()

  // Стабильный обработчик клика с useCallback
  const handleClick = useCallback(() => {
    if (onClick) {
      onClick()
    } else if (!disableAutoNavigate) {
      if (navigateTo) {
        navigate(navigateTo)
      } else {
        navigate(-1)
      }
    }
  }, [onClick, navigateTo, disableAutoNavigate, navigate])

  // Используем базовый хук для работы с Telegram BackButton
  const backButton = useTelegramBackButton({
    onClick: handleClick,
    show,
  })

  return backButton
}

export default useBackButton
