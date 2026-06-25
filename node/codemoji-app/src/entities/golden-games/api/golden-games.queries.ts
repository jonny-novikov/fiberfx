import { useQuery, useInfiniteQuery, UseQueryOptions } from '@tanstack/react-query'

import type { GoldenGamesListParams, GoldenGamesResponse } from '../model/types/golden-games.types'

import { getGoldenGames } from './golden-games.api'
import { goldenGamesQueryKeys } from './golden-games.query-keys'

export function useGoldenGamesQuery(
  params?: GoldenGamesListParams,
  options?: UseQueryOptions<GoldenGamesResponse, Error>
) {
  return useQuery({
    queryKey: goldenGamesQueryKeys.list(params),
    queryFn: () => getGoldenGames(params),
    staleTime: 60_000,
    ...options,
  })
}

export function useGoldenGamesInfinite(params?: Omit<GoldenGamesListParams, 'offset'>) {
  const limit = params?.limit ?? 10

  return useInfiniteQuery({
    queryKey: goldenGamesQueryKeys.infinite(params),
    queryFn: ({ pageParam = 0 }) =>
      getGoldenGames({
        ...params,
        limit,
        offset: pageParam,
      }),
    initialPageParam: 0,
    getNextPageParam: (lastPage, allPages) => {
      if (!lastPage.hasMore) return undefined
      return allPages.length * limit
    },
    staleTime: 60_000,
  })
}
