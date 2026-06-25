/**
 * Toast Store
 *
 * Jotai atoms for toast/notification management.
 *
 * @module shared/libs/stores/toast
 */

import { atom } from 'jotai'

import type { UIToastNotification } from '@/shared/api/types'

// ============================================================================
// Toast/Notification Store
// ============================================================================

/**
 * Toast notifications queue
 */
export const toastsAtom = atom<UIToastNotification[]>([])

/**
 * Add a toast notification
 */
export const addToastAtom = atom(null, (get, set, toast: Omit<UIToastNotification, 'id'>) => {
  const id = `toast-${Date.now()}-${Math.random().toString(36).slice(2, 9)}`
  const newToast: UIToastNotification = { ...toast, id }
  set(toastsAtom, [...get(toastsAtom), newToast])

  // Auto-remove after duration
  const duration = toast.duration ?? 3000
  setTimeout(() => {
    set(toastsAtom, (prev) => prev.filter((t) => t.id !== id))
  }, duration)
})

/**
 * Remove a toast by ID
 */
export const removeToastAtom = atom(null, (get, set, id: string) => {
  set(
    toastsAtom,
    get(toastsAtom).filter((t) => t.id !== id)
  )
})

/**
 * Clear all toasts
 */
export const clearToastsAtom = atom(null, (_get, set) => {
  set(toastsAtom, [])
})
