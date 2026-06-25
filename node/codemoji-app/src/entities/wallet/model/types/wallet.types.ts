export interface WalletInfo {
  address: string
  network: 'mainnet' | 'testnet'
  isPrimary?: boolean
}

export interface WalletBalance {
  crystals: number
  availableForWithdraw: number
  lockedUntilDays?: number
  lockedAmount?: number
}

export interface WithdrawRate {
  crystalToTon: number // 1 кристалл = X TON
  crystalToUsdt: number // 1 кристалл = X USDT
}
