import { useQuery, useInfiniteQuery, UseQueryOptions } from '@tanstack/react-query'

import type { ArchiveGamesParams, ArchiveGamesResponse } from '../model/types/rooms.types'

import { getArchiveGames } from './rooms.api'
import { roomQueryKeys } from './rooms.query-keys'

/**
 * Hook for fetching archived games
 * Uses longer staleTime since archive data doesn't change
 */
export function useArchiveGames(
  params?: ArchiveGamesParams,
  options?: UseQueryOptions<ArchiveGamesResponse, Error>
) {
  return useQuery({
    queryKey: roomQueryKeys.archive(params),
    queryFn: () => getArchiveGames(params),
    staleTime: 5 * 60 * 1000, // 5 minutes - archive doesn't change often
    gcTime: 10 * 60 * 1000, // 10 minutes
    ...options,
  })
}

/**
 * Infinite query hook for "Load More" pagination
 */
export function useArchiveGamesInfinite(params?: Omit<ArchiveGamesParams, 'offset'>) {
  const limit = params?.limit ?? 10

  return useInfiniteQuery({
    queryKey: roomQueryKeys.archiveInfinite(params),
    queryFn: ({ pageParam = 0 }) =>
      getArchiveGames({
        ...params,
        limit,
        offset: pageParam,
      }),
    initialPageParam: 0,
    getNextPageParam: (lastPage, allPages) => {
      if (!lastPage.hasMore) return undefined
      return allPages.length * limit
    },
    staleTime: 5 * 60 * 1000,
    gcTime: 10 * 60 * 1000,
  })
}
