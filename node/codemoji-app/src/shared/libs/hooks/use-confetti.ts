/**
 * useConfetti Hook
 *
 * Хук для управления глобальным конфетти эффектом.
 *
 * @example
 * ```tsx
 * const { triggerConfetti, hideConfetti, isVisible } = useConfetti()
 *
 * // Запустить с настройками по умолчанию
 * triggerConfetti()
 *
 * // Запустить с кастомными настройками
 * triggerConfetti({
 *   numberOfPieces: 200,
 *   colors: ['#FF0000', '#00FF00', '#0000FF'],
 *   duration: 3000
 * })
 *
 * // Скрыть конфетти раньше времени
 * hideConfetti()
 * ```
 */

import { useAtom, useAtomValue } from 'jotai'
import { useCallback } from 'react'

import {
  type ConfettiConfig,
  confettiVisibleAtom,
  hideConfettiAtom,
  triggerConfettiAtom,
} from '../stores/confetti.store'

export const useConfetti = () => {
  const isVisible = useAtomValue(confettiVisibleAtom)
  const [, triggerConfettiAction] = useAtom(triggerConfettiAtom)
  const [, hideConfettiAction] = useAtom(hideConfettiAtom)

  const triggerConfetti = useCallback(
    (config?: ConfettiConfig) => {
      triggerConfettiAction(config)
    },
    [triggerConfettiAction]
  )

  const hideConfetti = useCallback(() => {
    hideConfettiAction()
  }, [hideConfettiAction])

  return {
    /** Видимо ли сейчас конфетти */
    isVisible,
    /** Запустить конфетти */
    triggerConfetti,
    /** Скрыть конфетти */
    hideConfetti,
  }
}
