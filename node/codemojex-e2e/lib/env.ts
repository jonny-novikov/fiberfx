import { readFileSync } from "node:fs";

/**
 * The Codemoji bot token, used to HMAC-sign forged Telegram initData so the e2e
 * tests exercise the REAL auth handshake (not a bypass). Prefers the process env
 * (the dev server is booted with echo/.env sourced); otherwise it parses the same
 * echo/.env file directly.
 */
export function botToken(): string {
  if (process.env.CODEMOJI_BOT_TOKEN) return process.env.CODEMOJI_BOT_TOKEN;

  const envPath =
    process.env.CODEMOJEX_ENV_FILE ?? "/Users/jonny/dev/jonnify/echo/.env";
  let text: string;
  try {
    text = readFileSync(envPath, "utf8");
  } catch {
    throw new Error(
      `CODEMOJI_BOT_TOKEN not in env and ${envPath} unreadable. ` +
        `Set CODEMOJI_BOT_TOKEN or CODEMOJEX_ENV_FILE.`,
    );
  }
  const m = text.match(/^\s*CODEMOJI_BOT_TOKEN\s*=\s*(.+?)\s*$/m);
  if (!m) throw new Error(`CODEMOJI_BOT_TOKEN not found in ${envPath}`);
  return m[1].trim().replace(/^["']|["']$/g, "");
}
