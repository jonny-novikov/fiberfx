import type { GoldenGamesListParams } from '../model/types/golden-games.types'

export const goldenGamesQueryKeys = {
  all: ['golden-games'] as const,
  lists: () => [...goldenGamesQueryKeys.all, 'list'] as const,
  list: (params?: GoldenGamesListParams) =>
    [...goldenGamesQueryKeys.all, 'list', params ?? {}] as const,
  infinite: (params?: Omit<GoldenGamesListParams, 'offset'>) =>
    [...goldenGamesQueryKeys.all, 'list', 'infinite', params ?? {}] as const,
}
