import { useQuery } from '@tanstack/react-query'

import { getMyProfile, getMyResources } from './player.api'
import { playerQueryKeys } from './player.query-keys'

export const usePlayerProfile = () => {
  return useQuery({
    queryKey: playerQueryKeys.profile(),
    queryFn: () => getMyProfile(),
  })
}

export const useMyResources = () => {
  return useQuery({
    queryKey: playerQueryKeys.resources(),
    queryFn: () => getMyResources(),
  })
}
