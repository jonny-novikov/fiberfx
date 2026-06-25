import { GameLeaderboardEntryDto } from '@codemoji/types'

export type LeaderboardItemDto = GameLeaderboardEntryDto
export type GameLeaderboardEntryResponse = {
  items: GameLeaderboardEntryDto[]
}
