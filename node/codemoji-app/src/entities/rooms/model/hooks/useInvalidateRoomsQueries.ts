import { useQueryClient } from '@tanstack/react-query'

import { roomQueryKeys } from '../../api/rooms.query-keys'

export function useInvalidateRoomsQueries() {
  const queryClient = useQueryClient()

  return {
    invalidateAll: () => {
      queryClient.invalidateQueries({ queryKey: roomQueryKeys.all })
    },

    invalidateLists: () => {
      queryClient.invalidateQueries({ queryKey: roomQueryKeys.lists() })
    },
  }
}
