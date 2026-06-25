/** Blind guess result — golden rooms return no scoring data (D-21, D-24) */
export interface BlindGuessSubmitResponse {
  entryId: string
  attemptNumber: number
  submittedAt: string // ISO 8601 (wire format is string, not Date)
}
