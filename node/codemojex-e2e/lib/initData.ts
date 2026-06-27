import { createHmac } from "node:crypto";

export interface FakeUser {
  id: number;
  first_name?: string;
  last_name?: string;
  username?: string;
  language_code?: string;
}

/**
 * Build a valid Telegram WebApp `initData` string, HMAC-signed with the bot token.
 *
 * Mirrors `Codemojex.InitData.verify/3` exactly (the server is the source of truth):
 *   - data-check-string = every field EXCEPT `hash` and `signature`, sorted by key,
 *     joined `key=value` with "\n", over the RAW (url-decoded) values;
 *   - secret_key = HMAC-SHA256(key: "WebAppData", msg: token)   (WebApp derivation);
 *   - hash       = lower-hex HMAC-SHA256(key: secret_key, msg: data-check-string).
 *
 * The server url-decodes each value (`URI.decode_query`) before rebuilding the
 * check string, so signing over the raw values here matches.
 */
export function signInitData(
  botToken: string,
  user: FakeUser,
  authDate: number = Math.floor(Date.now() / 1000),
): string {
  const params: Record<string, string> = {
    auth_date: String(authDate),
    query_id: "AAE2E" + authDate,
    user: JSON.stringify({ first_name: "E2E", ...user }),
  };

  const dataCheckString = Object.keys(params)
    .sort()
    .map((k) => `${k}=${params[k]}`)
    .join("\n");

  const secretKey = createHmac("sha256", "WebAppData").update(botToken).digest();
  const hash = createHmac("sha256", secretKey).update(dataCheckString).digest("hex");

  // URLSearchParams url-encodes each value; the server url-decodes them back.
  return new URLSearchParams({ ...params, hash }).toString();
}

/**
 * A Playwright cookie that carries a freshly-signed initData as the `tg_init`
 * cookie the static welcome forwards (value = encodeURIComponent(initData), which
 * MiniAppAuth reverses with URI.decode). Drop it into a context to authenticate.
 */
export function tgInitCookie(baseURL: string, botToken: string, user: FakeUser) {
  const initData = signInitData(botToken, user);
  return {
    name: "tg_init",
    value: encodeURIComponent(initData),
    url: baseURL,
    sameSite: "Lax" as const,
  };
}
