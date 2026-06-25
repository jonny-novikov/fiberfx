export const gameQueryKeys = {
  roomState: (roomCode: string) => ['room', roomCode],
  gameState: (gameId: string) => ['game', gameId],
  gameDetails: (gameId: string) => ['game', 'details', gameId],
  goldenGameState: (gameId: string) => ['game', 'golden', gameId],
}
