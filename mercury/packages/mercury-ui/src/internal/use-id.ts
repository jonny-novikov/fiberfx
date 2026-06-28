let counter = 0;

/**
 * Generates a process-unique id with the given prefix. Despite the name this is
 * NOT a React hook — it's a plain monotonic counter (base36), safe to call from
 * anywhere a stable, collision-free id is needed.
 */
export function useId(prefix = "mx"): string {
	counter += 1;
	return `${prefix}-${counter.toString(36)}`;
}
