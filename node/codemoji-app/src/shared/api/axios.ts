import axios, { AxiosError, InternalAxiosRequestConfig } from 'axios'

import { TelegramUtils } from '@/shared/libs/utils/telegram'

const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:6003/api/v2'
const DEBUG = import.meta.env.DEV || import.meta.env.VITE_DEBUG === 'true'

const TOKEN_KEY = 'codemoji_access_token'
const REFRESH_TOKEN_KEY = 'codemoji_refresh_token'
const TOKEN_EXPIRY_KEY = 'codemoji_token_expiry'

export const tokenStorage = {
  getAccessToken: (): string | null => {
    if (typeof window === 'undefined') return null
    return localStorage.getItem(TOKEN_KEY)
  },

  getRefreshToken: (): string | null => {
    if (typeof window === 'undefined') return null
    return localStorage.getItem(REFRESH_TOKEN_KEY)
  },

  setTokens: (accessToken: string, refreshToken?: string, expiresIn?: number): void => {
    if (typeof window === 'undefined') return
    localStorage.setItem(TOKEN_KEY, accessToken)
    if (refreshToken) {
      localStorage.setItem(REFRESH_TOKEN_KEY, refreshToken)
    }
    if (expiresIn) {
      const expiry = Date.now() + expiresIn * 1000
      localStorage.setItem(TOKEN_EXPIRY_KEY, String(expiry))
    }
  },

  clearTokens: (): void => {
    if (typeof window === 'undefined') return
    localStorage.removeItem(TOKEN_KEY)
    localStorage.removeItem(REFRESH_TOKEN_KEY)
    localStorage.removeItem(TOKEN_EXPIRY_KEY)
  },

  isTokenValid: (): boolean => {
    if (typeof window === 'undefined') return false
    const token = localStorage.getItem(TOKEN_KEY)
    const expiry = localStorage.getItem(TOKEN_EXPIRY_KEY)
    if (!token) return false
    if (!expiry) return true // No expiry set, assume valid
    return Date.now() < parseInt(expiry, 10)
  },

  isTokenExpiringSoon: (thresholdMs: number = 60000): boolean => {
    if (typeof window === 'undefined') return false
    const expiry = localStorage.getItem(TOKEN_EXPIRY_KEY)
    if (!expiry) return false
    return Date.now() + thresholdMs >= parseInt(expiry, 10)
  },
}

// ============================================================================
// Axios Instance
// ============================================================================

export const api = axios.create({
  baseURL: API_URL,
  timeout: 30000,
  withCredentials: true,
  headers: {
    'Content-Type': 'application/json',
  },
})

// ============================================================================
// Request Interceptor - Add Authorization Header
// ============================================================================

api.interceptors.request.use(
  (config: InternalAxiosRequestConfig) => {
    const token = tokenStorage.getAccessToken()

    // Add Bearer token if available
    if (token) {
      config.headers.Authorization = `Bearer ${token}`
    }

    // Add platform-auth header with fresh Telegram initData (for dual-auth support)
    // Get fresh from SDK each request - more secure than storing in localStorage
    const initData = TelegramUtils.getInitData()
    if (initData) {
      config.headers['platform-auth'] = initData
    }

    // if (DEBUG) {
    //   console.log(`[API] ${config.method?.toUpperCase()} ${config.url}`)
    // }

    return config
  },
  (error) => {
    return Promise.reject(error)
  }
)

// ============================================================================
// Response Interceptor - Handle Errors & Token Refresh
// ============================================================================

let isRefreshing = false
let refreshSubscribers: ((token: string) => void)[] = []

function subscribeToTokenRefresh(callback: (token: string) => void) {
  refreshSubscribers.push(callback)
}

function onTokenRefreshed(token: string) {
  refreshSubscribers.forEach((callback) => callback(token))
  refreshSubscribers = []
}

api.interceptors.response.use(
  (response) => response,
  async (error: AxiosError) => {
    const originalRequest = error.config

    // Handle 401 Unauthorized
    if (error.response?.status === 401 && originalRequest) {
      // Prevent infinite loop - don't retry auth endpoints
      if (originalRequest.url?.includes('/api/auth/')) {
        tokenStorage.clearTokens()
        return Promise.reject(error)
      }

      // If already refreshing, queue the request
      if (isRefreshing) {
        return new Promise((resolve) => {
          subscribeToTokenRefresh((token: string) => {
            originalRequest.headers.Authorization = `Bearer ${token}`
            resolve(api(originalRequest))
          })
        })
      }

      isRefreshing = true

      try {
        const refreshToken = tokenStorage.getRefreshToken()

        if (!refreshToken) {
          throw new Error('No refresh token available')
        }

        // Call refresh endpoint
        const response = await axios.post(`${API_URL}/auth/refresh`, {
          token: refreshToken,
        })

        const { token: newToken } = response.data

        tokenStorage.setTokens(newToken, refreshToken)
        onTokenRefreshed(newToken)

        // Retry original request
        originalRequest.headers.Authorization = `Bearer ${newToken}`
        return api(originalRequest)
      } catch (refreshError) {
        // Refresh failed - clear tokens and redirect to login
        tokenStorage.clearTokens()
        refreshSubscribers = []

        if (DEBUG) {
          console.error('[API] Token refresh failed:', refreshError)
        }

        return Promise.reject(refreshError)
      } finally {
        isRefreshing = false
      }
    }

    // Log errors in debug mode
    if (DEBUG && error.response) {
      console.error(`[API] Error ${error.response.status}:`, error.response.data)
    }

    return Promise.reject(error)
  }
)

export default api
