import { useQuery } from '@tanstack/react-query'

import { getGuessHistory } from './history.api'
import { historyQueryKeys } from './history.query-keys'

/**
 * Хук для получения истории попыток игрока в комнате
 *
 * @param roomCode - код комнаты
 * @param options - дополнительные опции
 */
export const usePlayerGuessHistory = (gameId: string) => {
  return useQuery({
    queryKey: historyQueryKeys.byGame(gameId),
    queryFn: () => getGuessHistory(gameId),
    enabled: !!gameId,
  })
}
