import type { InitMeta } from '@codemoji/types'

import { AuthResponse } from '../model/types/auth.types'

import { api } from '@/shared/api/axios'

export async function authTelegram(initData: string, initMeta?: InitMeta) {
  const response = await api.post<AuthResponse>('/auth/telegram', {
    initData,
    initMeta,
  })
  return response.data
}

// async function devAuth(input: DevAuthInput = {}): Promise<DevAuthResponse> {
//   const response = await api.post<DevAuthResponse>('/api/auth/dev', input)
//   return response.data
// }

// async function getCurrentUser(): Promise<CurrentUserResponse> {
//   const response = await api.get<CurrentUserResponse>('/api/auth/me')
//   return response.data
// }

// async function refreshToken(token: string): Promise<{ success: boolean; token: string }> {
//   const response = await api.post<{ success: boolean; token: string }>('/api/auth/refresh', {
//     token,
//   })
//   return response.data
// }
