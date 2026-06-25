/**
 * Standardized Error Handler for API Responses
 *
 * @version 1.0.0
 */

import { AxiosError } from 'axios'

// ─── Error Response Types ────────────────────────────────────────────────────

/**
 * Backend error response format from codemoji-types/dtos/errors.dto.ts
 */
export interface ApiErrorResponse {
  success: false
  error: {
    code: ServiceErrCode
    message: string
    details?: Record<string, unknown>
  }
}

/**
 * Service error codes from backend
 * Must match SERVICE_ERR_CODES in codemoji-types/dtos/errors.dto.ts
 */
export type ServiceErrCode =
  | 'NOT_FOUND'
  | 'CONFLICT'
  | 'FORBIDDEN'
  | 'INSUFFICIENT_RESOURCES'
  | 'INVALID_STATE'
  | 'VALIDATION_ERROR'
  | 'RATE_LIMITED'
  | 'GAME_CLOSED'
  | 'MAX_GUESSES'
  | 'UNAUTHORIZED'
  | 'INTERNAL'

/**
 * Client-side error with code and user-friendly message
 */
export interface ClientError {
  code: ClientErrorCode
  message: string
  details?: Record<string, unknown>
  statusCode?: number
  retry?: boolean
}

/**
 * Client error codes (superset of service codes + network errors)
 */
export type ClientErrorCode =
  | ServiceErrCode
  | 'NETWORK'
  | 'TIMEOUT'
  | 'UNKNOWN'

// ─── Error Code Mapping ──────────────────────────────────────────────────────

/**
 * User-friendly messages for each error code
 */
const ERROR_MESSAGES: Record<ServiceErrCode, string> = {
  NOT_FOUND: 'The requested resource was not found',
  CONFLICT: 'This action conflicts with the current state',
  FORBIDDEN: 'You do not have permission to perform this action',
  INSUFFICIENT_RESOURCES: 'Not enough keys to perform this action',
  INVALID_STATE: 'This action cannot be performed in the current state',
  VALIDATION_ERROR: 'Invalid request data',
  RATE_LIMITED: 'Too many requests. Please wait and try again',
  GAME_CLOSED: 'This game has ended',
  MAX_GUESSES: 'Maximum number of guesses reached',
  UNAUTHORIZED: 'Please sign in to continue',
  INTERNAL: 'An unexpected error occurred. Please try again',
}

/**
 * Error codes that suggest retrying might help
 */
const RETRYABLE_CODES: Set<ClientErrorCode> = new Set([
  'NETWORK',
  'TIMEOUT',
  'RATE_LIMITED',
  'INTERNAL',
])

// ─── Type Guards ─────────────────────────────────────────────────────────────

/**
 * Check if response is an API error response
 */
export function isApiErrorResponse(data: unknown): data is ApiErrorResponse {
  return (
    typeof data === 'object' &&
    data !== null &&
    'success' in data &&
    data.success === false &&
    'error' in data &&
    typeof (data as ApiErrorResponse).error === 'object' &&
    'code' in (data as ApiErrorResponse).error
  )
}

/**
 * Check if error code matches
 */
export function isErrorCode(
  error: ClientError | undefined,
  code: ServiceErrCode
): boolean {
  return error?.code === code
}

// ─── Error Parsing ───────────────────────────────────────────────────────────

/**
 * Parse an error into a standardized ClientError
 *
 * @param error - Error from API call (AxiosError or any)
 * @returns Standardized ClientError
 */
export function parseError(error: unknown): ClientError {
  // Handle AxiosError
  if (error instanceof AxiosError) {
    return parseAxiosError(error)
  }

  // Handle Error objects
  if (error instanceof Error) {
    return {
      code: 'UNKNOWN',
      message: error.message || 'An unexpected error occurred',
      retry: false,
    }
  }

  // Handle unknown errors
  return {
    code: 'UNKNOWN',
    message: 'An unexpected error occurred',
    retry: false,
  }
}

/**
 * Parse an AxiosError into a ClientError
 */
function parseAxiosError(error: AxiosError): ClientError {
  // Network error (no response)
  if (!error.response) {
    if (error.code === 'ECONNABORTED' || error.message.includes('timeout')) {
      return {
        code: 'TIMEOUT',
        message: 'Request timed out. Please check your connection and try again',
        retry: true,
      }
    }
    return {
      code: 'NETWORK',
      message: 'Unable to connect. Please check your internet connection',
      retry: true,
    }
  }

  const { status, data } = error.response

  // Parse backend error response
  if (isApiErrorResponse(data)) {
    const { code, message, details } = data.error
    return {
      code,
      message: ERROR_MESSAGES[code] || message,
      details,
      statusCode: status,
      retry: RETRYABLE_CODES.has(code),
    }
  }

  // Handle HTTP status codes without structured error
  switch (status) {
    case 400:
      return {
        code: 'VALIDATION_ERROR',
        message: 'Invalid request. Please check your input',
        statusCode: status,
        retry: false,
      }
    case 401:
      return {
        code: 'UNAUTHORIZED',
        message: 'Please sign in to continue',
        statusCode: status,
        retry: false,
      }
    case 403:
      return {
        code: 'FORBIDDEN',
        message: 'You do not have permission to perform this action',
        statusCode: status,
        retry: false,
      }
    case 404:
      return {
        code: 'NOT_FOUND',
        message: 'The requested resource was not found',
        statusCode: status,
        retry: false,
      }
    case 409:
      return {
        code: 'CONFLICT',
        message: 'This action conflicts with the current state',
        statusCode: status,
        retry: false,
      }
    case 429:
      return {
        code: 'RATE_LIMITED',
        message: 'Too many requests. Please wait and try again',
        statusCode: status,
        retry: true,
      }
    case 500:
    case 502:
    case 503:
    case 504:
      return {
        code: 'INTERNAL',
        message: 'Server error. Please try again later',
        statusCode: status,
        retry: true,
      }
    default:
      return {
        code: 'UNKNOWN',
        message: 'An unexpected error occurred',
        statusCode: status,
        retry: false,
      }
  }
}

// ─── UI Helper Functions ─────────────────────────────────────────────────────

/**
 * Get user-friendly message for display
 */
export function getErrorMessage(error: ClientError): string {
  return error.message
}

/**
 * Check if error suggests showing purchase modal
 */
export function shouldShowPurchaseModal(error: ClientError): boolean {
  return error.code === 'INSUFFICIENT_RESOURCES'
}

/**
 * Check if error suggests navigating to lobby
 */
export function shouldNavigateToLobby(error: ClientError): boolean {
  return error.code === 'GAME_CLOSED' || error.code === 'NOT_FOUND'
}

/**
 * Check if error requires re-authentication
 */
export function shouldReauthenticate(error: ClientError): boolean {
  return error.code === 'UNAUTHORIZED'
}

/**
 * Check if error can be retried
 */
export function isRetryable(error: ClientError): boolean {
  return error.retry === true
}

// ─── Exports ─────────────────────────────────────────────────────────────────

export default {
  parseError,
  isApiErrorResponse,
  isErrorCode,
  getErrorMessage,
  shouldShowPurchaseModal,
  shouldNavigateToLobby,
  shouldReauthenticate,
  isRetryable,
}
