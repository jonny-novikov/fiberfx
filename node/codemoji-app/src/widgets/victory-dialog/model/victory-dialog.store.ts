import { atom } from 'jotai'

/**
 * Интерфейс данных для модального окна победителя
 */
export interface VictoryDialogData {
  /** ID игры для начисления приза */
  gameId?: string
  /** Имя победителя */
  playerName?: string
  /** Сумма выигрыша в долларах */
  prizeAmount?: number
  /** Количество начисленных ключей (legacy, now awarded as diamonds) */
  keysAwarded?: number
  /** Количество начисленных алмазов */
  diamondsAwarded?: number
  /** Текущий баланс алмазов после начисления */
  newDiamondBalance?: number
  /** Сколько ключей можно конвертировать из алмазов (10:1) */
  convertibleToKeys?: number
  /** Заработанные баллы */
  earnedPoints?: number
  /** Позиция в рейтинге */
  leaderboardPosition?: number
  /** Дополнительные награды */
  bonusRewards?: {
    keys?: number
    specialItems?: string[]
  }
}

/**
 * Atom для управления открытием/закрытием модального окна победителя
 */
export const victoryDialogOpenAtom = atom<boolean>(false)

/**
 * Atom для хранения данных победителя
 */
export const victoryDialogDataAtom = atom<VictoryDialogData | null>(null)

/**
 * Write-only atom для открытия модального окна с данными
 */
export const showVictoryDialogAtom = atom(
  null,
  (get, set, data: VictoryDialogData) => {
    set(victoryDialogDataAtom, data)
    set(victoryDialogOpenAtom, true)
  }
)

/**
 * Write-only atom для закрытия модального окна
 */
export const hideVictoryDialogAtom = atom(null, (get, set) => {
  set(victoryDialogOpenAtom, false)
  // Очищаем данные с задержкой, чтобы не нарушить анимацию закрытия
  setTimeout(() => {
    set(victoryDialogDataAtom, null)
  }, 300)
})

