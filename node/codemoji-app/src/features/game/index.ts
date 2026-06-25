// api
export { gameQueryKeys } from './api/game.query-keys'

// types
export type { RoomResponse, ClaimPrizeResponse, GameDetailsResponse } from './model/game.types'

// queries
export { useRoomStateQuery, useGameStateQuery, useGameQuery } from './api/game.queries'
// mutations
export { useGuessSubmitMutation, useClaimPrizeMutation } from './api/game.mutations'
// golden mutations
export { useGoldenGuessSubmitMutation } from './api/golden-game.mutations'
// golden types
export type { BlindGuessSubmitResponse } from './model/golden-game.types'

// store
export {
  selectedEmojisAtom,
  cleanSelectedEmojisAtom,
  clearEmojisAtom,
  resetGameStateAtom,
  isSelectionReadyAtom,
  disintegrateTriggerAtom,
  triggerDisintegrateAtom,
} from './model/gameplay.store'
