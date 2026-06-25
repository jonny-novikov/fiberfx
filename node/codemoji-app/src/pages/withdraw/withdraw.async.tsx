import { lazy } from 'react'

export const WithdrawPage = lazy(() =>
  import('./withdraw.page').then((m) => ({ default: m.WithdrawPage }))
)
