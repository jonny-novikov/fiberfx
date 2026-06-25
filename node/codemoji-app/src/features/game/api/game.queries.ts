import { useQuery } from '@tanstack/react-query'

import { getGame, getGameState, getRoomState } from './game.api'
import { gameQueryKeys } from './game.query-keys'

export function useRoomStateQuery(roomId: string) {
  return useQuery({
    queryKey: gameQueryKeys.roomState(roomId),
    queryFn: () => getRoomState(roomId),
    enabled: !!roomId,
    // refetchInterval: 5000,
  })
}

export function useGameStateQuery(gameId: string) {
  return useQuery({
    queryKey: gameQueryKeys.gameState(gameId),
    queryFn: () => getGameState(gameId),
    enabled: !!gameId,
    refetchInterval: 2000,
  })
}

/**
 * Хук для получения деталей игры
 * Возвращает secretCode только для завершённых игр (status === 'finalized')
 * @param gameId - ID игры в формате GAMxxxxxxxxxxx
 */
export function useGameQuery(gameId: string) {
  return useQuery({
    queryKey: gameQueryKeys.gameDetails(gameId),
    queryFn: () => getGame(gameId),
    enabled: !!gameId,
  })
}
