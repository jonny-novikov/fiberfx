import { useQueryClient } from '@tanstack/react-query'

import { playerQueryKeys } from '../../api/player.query-keys'

export function useInvalidatePlayerQueries() {
  const queryClient = useQueryClient()

  return {
    /** Инвалидировать ресурсы конкретного игрока */
    invalidateResources: (playerId: string) => {
      queryClient.invalidateQueries({ queryKey: playerQueryKeys.resources(playerId) })
    },
    /** Инвалидировать все player запросы */
    invalidateAll: () => {
      queryClient.invalidateQueries({ queryKey: playerQueryKeys.all })
    },
  }
}
