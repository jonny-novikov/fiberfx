import type {
  PlayerDTO,
  PlayerStatsDto,
  PlayerResourcesDto,
  PlayerProfileDto,
} from '@codemoji/types'

export type Player = PlayerDTO
export type PlayerStats = PlayerStatsDto
export type PlayerResources = PlayerResourcesDto
export type PlayerProfile = PlayerProfileDto

export type PlayerInfo = {
  id: string
  telegramId: string
  firstName: string
  isPremium: boolean
  createdAt: string
  lastActiveAt: string
  username?: string
  lastName?: string
  photoUrl?: string
  languageCode?: string
}
