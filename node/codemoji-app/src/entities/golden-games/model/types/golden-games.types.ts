import type { GoldenGameItemDto, GoldenGamesResponseDto } from '@codemoji/types'

export type GoldenGameItem = GoldenGameItemDto
export type GoldenGamesResponse = GoldenGamesResponseDto

export interface GoldenGamesListParams {
  limit?: number
  offset?: number
}
