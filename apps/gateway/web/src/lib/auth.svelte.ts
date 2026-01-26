const TOKEN_KEY = 'gateway_token';
const USER_KEY = 'gateway_user';

interface User {
  username: string;
  telegram_id: number;
  role: string;
  expires_at: number;
}

interface LoginResponse {
  token: string;
  username: string;
  expiresAt: number;
}

// Reactive state
let user = $state<User | null>(null);
let token = $state<string | null>(null);
let isLoading = $state(false);
let error = $state<string | null>(null);

export const auth = {
  get isAuthenticated() {
    return !!token && !!user;
  },
  get user() {
    return user;
  },
  get token() {
    return token;
  },
  get isLoading() {
    return isLoading;
  },
  get error() {
    return error;
  },

  init() {
    // Load from localStorage
    const savedToken = localStorage.getItem(TOKEN_KEY);
    const savedUser = localStorage.getItem(USER_KEY);

    if (savedToken && savedUser) {
      try {
        const parsed = JSON.parse(savedUser);
        // Check if token is expired
        if (parsed.expires_at && parsed.expires_at * 1000 > Date.now()) {
          token = savedToken;
          user = parsed;
          // Verify token is still valid
          this.verify();
        } else {
          this.logout();
        }
      } catch {
        this.logout();
      }
    }
  },

  async login(username: string, password: string): Promise<boolean> {
    isLoading = true;
    error = null;

    try {
      const res = await fetch('/api/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ username, password }),
      });

      if (!res.ok) {
        const data = await res.json().catch(() => ({ message: 'Login failed' }));
        error = data.message || 'Invalid credentials';
        return false;
      }

      const data: LoginResponse = await res.json();

      token = data.token;
      user = {
        username: data.username,
        telegram_id: 0,
        role: 'admin',
        expires_at: data.expiresAt,
      };

      localStorage.setItem(TOKEN_KEY, data.token);
      localStorage.setItem(USER_KEY, JSON.stringify(user));

      return true;
    } catch (err) {
      error = err instanceof Error ? err.message : 'Network error';
      return false;
    } finally {
      isLoading = false;
    }
  },

  async verify(): Promise<boolean> {
    if (!token) return false;

    try {
      const res = await fetch('/api/me', {
        headers: { Authorization: `Bearer ${token}` },
      });

      if (!res.ok) {
        if (res.status === 401) {
          this.logout();
        }
        return false;
      }

      const data = await res.json();
      user = {
        username: data.username,
        telegram_id: data.telegram_id,
        role: data.role,
        expires_at: data.expires_at,
      };
      localStorage.setItem(USER_KEY, JSON.stringify(user));

      return true;
    } catch {
      return false;
    }
  },

  logout() {
    user = null;
    token = null;
    error = null;
    localStorage.removeItem(TOKEN_KEY);
    localStorage.removeItem(USER_KEY);

    // Call logout API (fire and forget)
    fetch('/api/auth/logout', { method: 'POST' }).catch(() => {});
  },
};
