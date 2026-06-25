import { useSetAtom, useAtomValue } from 'jotai'

import {
  showVictoryDialogAtom,
  hideVictoryDialogAtom,
  victoryDialogOpenAtom,
  victoryDialogDataAtom,
  type VictoryDialogData,
} from '../model/victory-dialog.store'

/**
 * Хук для управления модальным окном победителя
 *
 * @example
 * ```typescript
 * function GameComponent() {
 *   const { show, hide, isOpen, data } = useVictoryDialog()
 *
 *   const handleWin = () => {
 *     show({
 *       playerName: 'Player1',
 *       prizeAmount: 1000,
 *       earnedPoints: 50
 *     })
 *   }
 *
 *   return <button onClick={handleWin}>Win Game</button>
 * }
 * ```
 */
export const useVictoryDialog = () => {
  const show = useSetAtom(showVictoryDialogAtom)
  const hide = useSetAtom(hideVictoryDialogAtom)
  const isOpen = useAtomValue(victoryDialogOpenAtom)
  const data = useAtomValue(victoryDialogDataAtom)

  return {
    /**
     * Показать модальное окно победителя с данными
     */
    show: (dialogData: VictoryDialogData) => show(dialogData),
    /**
     * Скрыть модальное окно победителя
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
