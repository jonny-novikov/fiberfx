import { useMutation } from '@tanstack/react-query'

import type { JoinRoomResponse } from '../model/types/rooms.types'

import { joinRoom, leaveRoom } from './rooms.api'

export const useJoinRoomMutation = () => {
  return useMutation<JoinRoomResponse, Error, string>({
    mutationFn: (roomId) => joinRoom(roomId),
  })
}

export const useLeaveRoomMutation = () => {
  return useMutation<{ success: boolean }, Error, string>({
    mutationFn: (roomId) => leaveRoom(roomId),
  })
}
