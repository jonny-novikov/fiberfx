import { useSetAtom, useAtomValue } from 'jotai'

import {
  showFirstPlaceDialogAtom,
  hideFirstPlaceDialogAtom,
  firstPlaceDialogOpenAtom,
  firstPlaceDialogDataAtom,
  type FirstPlaceDialogData,
} from '../model/first-place-dialog.store'

/**
 * Хук для управления модальным окном первого места
 *
 * @example
 * ```typescript
 * function GameComponent() {
 *   const { show, hide, isOpen, data } = useFirstPlaceDialog()
 *
 *   const handleBecameLeader = () => {
 *     show({ prizePool: 1000 })
 *   }
 *
 *   return <button onClick={handleBecameLeader}>Became Leader</button>
 * }
 * ```
 */
export const useFirstPlaceDialog = () => {
  const show = useSetAtom(showFirstPlaceDialogAtom)
  const hide = useSetAtom(hideFirstPlaceDialogAtom)
  const isOpen = useAtomValue(firstPlaceDialogOpenAtom)
  const data = useAtomValue(firstPlaceDialogDataAtom)

  return {
    /**
     * Показать модальное окно первого места с данными
     */
    show: (dialogData?: FirstPlaceDialogData) => show(dialogData),
    /**
     * Скрыть модальное окно первого места
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
