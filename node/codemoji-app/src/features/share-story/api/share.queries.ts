import { useQuery } from '@tanstack/react-query'

import { getShareStatus } from './share.api'
import { shareQueryKeys } from './share.query-keys'

export function useShareStatusQuery(enabled = true) {
  return useQuery({
    queryKey: shareQueryKeys.status(),
    queryFn: getShareStatus,
    refetchInterval: 10_000,
    enabled,
  })
}
