// `DEV` without the `esm-env` dependency: Vite statically replaces
// `import.meta.env.DEV` at build (true in dev, false in prod); the cast keeps
// `tsc` happy without pulling in `vite/client` global types.
const DEV: boolean = (import.meta as ImportMeta & { env?: { DEV?: boolean } }).env?.DEV ?? false;

let seen: Set<string> | undefined;

export function warn(...messages: string[]) {
	if (!DEV) return;
	seen ??= new Set<string>();
	const msg = messages.join(" ");
	if (seen.has(msg)) return;
	seen.add(msg);
	// oxlint-disable-next-line no-console
	console.warn(`[Mercury UI]: ${msg}`);
}
