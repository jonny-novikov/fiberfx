import { atom } from 'jotai'

/**
 * Интерфейс данных для модального окна проигрыша
 */
export interface GameOverDialogData {
  /** ID игры */
  gameId: string
  /** Имя победителя, который обошел игрока */
  winnerName?: string
  /** Занятое место игрока */
  playerPosition?: number
  /** Заработанные баллы (утешительный приз) */
  earnedPoints?: number
  /** Сумма утешительного приза */
  consolationPrize?: number
  /** Осталось попыток */
  attemptsLeft?: number
  /** Причина проигрыша */
  reason?: 'winner_found' | 'time_expired' | 'attempts_exceeded'
  /** Дополнительная информация */
  additionalInfo?: string
}

/**
 * Atom для управления открытием/закрытием модального окна проигрыша
 */
export const gameOverDialogOpenAtom = atom<boolean>(false)

/**
 * Atom для хранения данных проигрыша
 */
export const gameOverDialogDataAtom = atom<GameOverDialogData | null>(null)

/**
 * Write-only atom для открытия модального окна с данными
 */
export const showGameOverDialogAtom = atom(
  null,
  (get, set, data: GameOverDialogData) => {
    set(gameOverDialogDataAtom, data)
    set(gameOverDialogOpenAtom, true)
  }
)

/**
 * Write-only atom для закрытия модального окна
 */
export const hideGameOverDialogAtom = atom(null, (get, set) => {
  set(gameOverDialogOpenAtom, false)
  // Очищаем данные с задержкой, чтобы не нарушить анимацию закрытия
  setTimeout(() => {
    set(gameOverDialogDataAtom, null)
  }, 300)
})

