/**
 * Confetti Store
 *
 * Jotai atoms for global confetti management.
 * Use this to trigger confetti effects from anywhere in the app.
 *
 * @module shared/libs/stores/confetti
 */

import { atom } from 'jotai'

// ============================================================================
// Types
// ============================================================================

export interface ConfettiConfig {
  /** Количество частиц (по умолчанию 400) */
  numberOfPieces?: number
  /** Гравитация (по умолчанию 0.3) */
  gravity?: number
  /** Цвета конфетти (по умолчанию черно-белая гамма) */
  colors?: string[]
  /** Повторять ли анимацию (по умолчанию false) */
  recycle?: boolean
  /** Длительность показа в мс (по умолчанию 5000) */
  duration?: number
}

// ============================================================================
// Constants
// ============================================================================

/** Цвета конфетти по умолчанию: черный, серый, белый */
export const DEFAULT_CONFETTI_COLORS = [
  '#000000',
  '#333333',
  '#666666',
  '#999999',
  '#CCCCCC',
  '#FFFFFF',
]

const DEFAULT_CONFETTI_CONFIG: Required<ConfettiConfig> = {
  numberOfPieces: 400,
  gravity: 0.3,
  colors: DEFAULT_CONFETTI_COLORS,
  recycle: false,
  duration: 5000,
}

// ============================================================================
// Atoms
// ============================================================================

/**
 * Показывается ли сейчас конфетти
 */
export const confettiVisibleAtom = atom<boolean>(false)

/**
 * Текущая конфигурация конфетти
 */
export const confettiConfigAtom = atom<Required<ConfettiConfig>>(DEFAULT_CONFETTI_CONFIG)

/**
 * Write-only atom для запуска конфетти
 * @param config - опциональная конфигурация
 */
export const triggerConfettiAtom = atom(null, (get, set, config?: ConfettiConfig) => {
  const mergedConfig: Required<ConfettiConfig> = {
    ...DEFAULT_CONFETTI_CONFIG,
    ...config,
  }

  set(confettiConfigAtom, mergedConfig)
  set(confettiVisibleAtom, true)

  // Автоматически скрываем конфетти после duration
  setTimeout(() => {
    set(confettiVisibleAtom, false)
  }, mergedConfig.duration)
})

/**
 * Write-only atom для скрытия конфетти
 */
export const hideConfettiAtom = atom(null, (_get, set) => {
  set(confettiVisibleAtom, false)
})
