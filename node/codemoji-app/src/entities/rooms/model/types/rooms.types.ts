import {
  RoomListItemDto,
  ListRoomsQuery,
  JoinRoomResponseDto,
  ArchiveGameItemDto,
  ArchiveGamesResponseDto,
} from '@codemoji/types'

export type RoomListItem = RoomListItemDto
export type RoomsListParams = ListRoomsQuery
export type JoinRoomResponse = JoinRoomResponseDto

export interface RoomsListResponse {
  rooms: Array<RoomListItemDto>
  totalPrizePool: number
  totalRooms: number
}

// Archive Games Types
export type ArchiveGame = ArchiveGameItemDto
export type ArchiveGamesResponse = ArchiveGamesResponseDto

export interface ArchiveGamesParams {
  /** Filter: 'my' for player's games, 'all' for global archive */
  filter?: 'my' | 'all'
  /** Results per page (default 10) */
  limit?: number
  /** Pagination offset */
  offset?: number
}
