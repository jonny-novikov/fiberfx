import type { ArchiveGamesParams, RoomsListParams } from '../model/types/rooms.types'

export const roomQueryKeys = {
  all: ['rooms'] as const,
  /** Include params so list cache differs by filters (e.g. type=all vs standard-only). */
  list: (params?: RoomsListParams) => [...roomQueryKeys.all, 'list', params ?? {}] as const,
  lists: () => [...roomQueryKeys.all, 'list'] as const,
  archive: (params?: ArchiveGamesParams) => [...roomQueryKeys.all, 'archive', params ?? {}] as const,
  archiveInfinite: (params?: Omit<ArchiveGamesParams, 'offset'>) =>
    [...roomQueryKeys.all, 'archive', 'infinite', params ?? {}] as const,
}

// Пример
// import type { GetRoomsListParams } from './types'

// export const roomQueryKeys = {
//   all: ['rooms'] as const,
//   list: (params?: GetRoomsListParams) =>
//     ['rooms', 'list', params ?? {}] as const,
//   // в будущем: details: (roomCode: string) => ['rooms', 'details', roomCode] as const,
// }
