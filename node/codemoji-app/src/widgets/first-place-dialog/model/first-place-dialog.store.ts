import { atom } from 'jotai'

/**
 * Интерфейс данных для модального окна первого места
 */
export interface FirstPlaceDialogData {
  /** Размер призового фонда */
  prizePool?: number
  /** Бонусные очки за выход на первое место */
  bonusPoints?: number
}

/**
 * Atom для управления открытием/закрытием модального окна первого места
 */
export const firstPlaceDialogOpenAtom = atom<boolean>(false)

/**
 * Atom для хранения данных диалога первого места
 */
export const firstPlaceDialogDataAtom = atom<FirstPlaceDialogData | null>(null)

/**
 * Write-only atom для открытия модального окна с данными
 */
export const showFirstPlaceDialogAtom = atom(null, (_get, set, data?: FirstPlaceDialogData) => {
  set(firstPlaceDialogDataAtom, data ?? null)
  set(firstPlaceDialogOpenAtom, true)
})

/**
 * Write-only atom для закрытия модального окна
 */
export const hideFirstPlaceDialogAtom = atom(null, (_get, set) => {
  set(firstPlaceDialogOpenAtom, false)
  // Очищаем данные с задержкой, чтобы не нарушить анимацию закрытия
  setTimeout(() => {
    set(firstPlaceDialogDataAtom, null)
  }, 300)
})
