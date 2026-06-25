import { useSetAtom, useAtomValue } from 'jotai'

import {
  showGameOverDialogAtom,
  hideGameOverDialogAtom,
  gameOverDialogOpenAtom,
  gameOverDialogDataAtom,
  type GameOverDialogData,
} from '../model/game-over-dialog.store'

/**
 * Хук для управления модальным окном проигрыша
 *
 * @example
 * ```typescript
 * function GameComponent() {
 *   const { show, hide, isOpen, data } = useGameOverDialog()
 *
 *   const handleGameOver = () => {
 *     show({
 *       winnerName: 'Player123',
 *       playerPosition: 3,
 *       earnedPoints: 25,
 *       reason: 'winner_found'
 *     })
 *   }
 *
 *   return <button onClick={handleGameOver}>End Game</button>
 * }
 * ```
 */
export const useGameOverDialog = () => {
  const show = useSetAtom(showGameOverDialogAtom)
  const hide = useSetAtom(hideGameOverDialogAtom)
  const isOpen = useAtomValue(gameOverDialogOpenAtom)
  const data = useAtomValue(gameOverDialogDataAtom)

  return {
    /**
     * Показать модальное окно проигрыша с данными
     */
    show: (dialogData: GameOverDialogData) => show(dialogData),
    /**
     * Скрыть модальное окно проигрыша
     */
    hide,
    /**
     * Текущее состояние модального окна (открыто/закрыто)
     */
    isOpen,
    /**
     * Данные, отображаемые в модальном окне
     */
    data,
  }
}
