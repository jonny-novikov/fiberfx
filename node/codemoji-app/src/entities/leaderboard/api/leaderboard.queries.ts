import { useQuery } from '@tanstack/react-query'

import { getGameLeaderboard } from './leaderboard.api'
import { leaderboardQueryKeys } from './leaderboard.query-keys'

/**
 * Хук для получения лидерборда комнаты
 *
 * @param roomCode - код комнаты
 * @param params - параметры запроса (limit, playerId)
 * @param options - дополнительные опции
 */
export const useGameLeaderboard = (gameId: string) => {
  return useQuery({
    queryKey: leaderboardQueryKeys.byGame(gameId),
    queryFn: () => getGameLeaderboard(gameId),
    enabled: !!gameId,
    refetchInterval: 2000,
  })
}
