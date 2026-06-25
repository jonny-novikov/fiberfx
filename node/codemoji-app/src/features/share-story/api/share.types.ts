/** POST /share/create response */
export interface CreateShareResponse {
  shareUrl: string
  status: string
  shareDate: string
  referralCode: string
}

/** GET /share/status response */
export interface ShareStatusResponse {
  status: string
  shareDate: string
  rewardedAt: string | null
  shareUrl: string | null
  referralCode: string | null
}
