import { useQuery, UseQueryOptions } from '@tanstack/react-query'

import { RoomsListParams, RoomsListResponse } from '../model/types/rooms.types'

import { getRoomsList } from './rooms.api'
import { roomQueryKeys } from './rooms.query-keys'

export function useRoomsListQuery(
  params: RoomsListParams,
  options?: UseQueryOptions<RoomsListResponse, Error>
) {
  return useQuery({
    queryKey: roomQueryKeys.list(params),
    queryFn: () => getRoomsList(params),
    staleTime: 30_000,
    refetchInterval: 5000,
    ...options,
  })
}
