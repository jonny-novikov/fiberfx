/**
 * A self-contained `clsx` — joins class values (strings, numbers, arrays, and
 * `{ class: boolean }` dictionaries) into one className string, skipping falsy
 * entries. Inlined (no dependency) for `mergeProps`'s rich `class` merging.
 */
export type ClassValue = ClassValue[] | Record<string, unknown> | string | number | bigint | null | boolean | undefined;

function toVal(mix: ClassValue): string {
	let str = "";

	if (typeof mix === "string" || typeof mix === "number") {
		str += mix;
	} else if (typeof mix === "object" && mix !== null) {
		if (Array.isArray(mix)) {
			for (const item of mix) {
				if (item) {
					const resolved = toVal(item);
					if (resolved) str += (str && " ") + resolved;
				}
			}
		} else {
			for (const key in mix) {
				if (mix[key]) str += (str && " ") + key;
			}
		}
	}

	return str;
}

export function clsx(...inputs: ClassValue[]): string {
	let str = "";
	for (const input of inputs) {
		if (input) {
			const resolved = toVal(input);
			if (resolved) str += (str && " ") + resolved;
		}
	}
	return str;
}
