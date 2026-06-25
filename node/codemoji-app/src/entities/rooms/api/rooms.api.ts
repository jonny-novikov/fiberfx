import type {
  RoomsListResponse,
  RoomsListParams,
  JoinRoomResponse,
  ArchiveGamesResponse,
  ArchiveGamesParams,
} from '../model/types/rooms.types'

import { api } from '@/shared/api/axios'

export async function getRoomsList(params?: RoomsListParams) {
  const response = await api.get<RoomsListResponse>('/rooms', { params })
  return response.data
}

/**
 * Get room details by roomId (branded ID)
 * @param roomId - Room ID in format ROMxxxxxxxxxxx
 */
export async function getRoomById(roomId: string) {
  const response = await api.get<JoinRoomResponse>(`/rooms/${roomId}`)
  return response.data
}

/**
 * Join a room by roomId (branded ID)
 * @param roomId - Room ID in format ROMxxxxxxxxxxx (from room list)
 * @returns Join response with roomId, roomCode, status
 */
export async function joinRoom(roomId: string) {
  const response = await api.post<JoinRoomResponse>(`/rooms/${roomId}/join`)
  return response.data
}

/**
 * Leave a room by roomId
 * @param roomId - Room ID in format ROMxxxxxxxxxxx
 */
export async function leaveRoom(roomId: string) {
  const response = await api.post<{ success: boolean }>(`/rooms/${roomId}/leave`)
  return response.data
}

/**
 * Set ready status in a room
 * @param roomId - Room ID in format ROMxxxxxxxxxxx
 * @param isReady - Whether player is ready
 */
export async function setReady(roomId: string, isReady: boolean) {
  const response = await api.post<{ success: boolean }>(`/rooms/${roomId}/ready`, { isReady })
  return response.data
}

/**
 * Get archived (finished) games
 * @param params - Filter and pagination params
 * @returns List of archived games with winner and secret code
 */
export async function getArchiveGames(params?: ArchiveGamesParams) {
  const response = await api.get<ArchiveGamesResponse>('/rooms/games/archive', { params })
  return response.data
}
