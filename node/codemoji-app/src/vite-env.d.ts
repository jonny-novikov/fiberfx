/// <reference types="vite/client" />
/// <reference types="vite-plugin-svgr/client" />

/**
 * Environment variables for Codemoji Frontend
 * @see .env.example for documentation
 */
interface ImportMetaEnv {
  /** Backend API URL (default: http://localhost:6003) */
  readonly VITE_API_URL: string;
  /** Enable mock mode - returns mock data without hitting backend (default: true in dev) */
  readonly VITE_USE_MOCK: string;
  /** WebSocket URL for real-time updates */
  readonly VITE_WS_URL?: string;
  /** Enable debug logging */
  readonly VITE_DEBUG?: string;
  /** Enable browser mode - bypasses Telegram SDK requirement (default: true in dev) */
  readonly VITE_BROWSER_MODE?: string;
  /** Maintenance mode - shows maintenance screen instead of app */
  readonly VITE_MAINTENANCE_MODE?: string;
}

interface ImportMeta {
  readonly env: ImportMetaEnv;
}

/**
 * Telegram WebApp types
 */
interface TelegramWebApp {
  initData: string;
  initDataUnsafe: {
    user?: {
      id: number;
      first_name: string;
      last_name?: string;
      username?: string;
      language_code?: string;
    };
    auth_date?: number;
    hash?: string;
  };
  ready: () => void;
  expand: () => void;
  close: () => void;
}

interface Window {
  Telegram?: {
    WebApp: TelegramWebApp;
  };
}
