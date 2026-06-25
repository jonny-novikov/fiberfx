import type { CreateShareResponse, ShareStatusResponse } from './share.types'
import { api } from '@/shared/api/axios'

export async function createShare() {
  const response = await api.post<CreateShareResponse>('/share/create')
  return response.data
}

export async function getShareStatus() {
  const response = await api.get<ShareStatusResponse>('/share/status')
  return response.data
}
