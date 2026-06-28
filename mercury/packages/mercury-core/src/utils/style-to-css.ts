import type { StyleProperties } from "../types";

function createParser(matcher: string | RegExp, replacer: (match: string) => string) {
	const regex = RegExp(matcher, "g");
	return (str: string): string => {
		// throw an error if not a string
		if (typeof str !== "string") {
			throw new TypeError(`expected an argument of type string, but got ${typeof str}`);
		}

		// if no match between string and matcher
		if (!str.match(regex)) return str;

		// executes the replacer function for each match
		return str.replace(regex, replacer);
	};
}

const camelToKebab = createParser(/[A-Z]/, (match) => `-${match.toLowerCase()}`);

export function styleToCSS(styleObj: object) {
	if (!styleObj || typeof styleObj !== "object" || Array.isArray(styleObj)) {
		throw new TypeError(`expected an argument of type object, but got ${typeof styleObj}`);
	}
	return Object.keys(styleObj)
		.map((property) => `${camelToKebab(property)}: ${styleObj[property as keyof typeof styleObj]};`)
		.join("\n");
}

/**
 * Parse a CSS declaration string (`"display: none; --x: 1"`) into a style
 * object. Standard properties are camelCased; `--*` custom properties are kept
 * verbatim. The inverse of {@link styleToCSS}; used by `mergeProps` to merge a
 * string `style` with an object one.
 */
export function cssToStyleObj(css: string | null | undefined): StyleProperties {
	const styleObj: Record<string, unknown> = {};
	if (!css) return styleObj as StyleProperties;

	for (const declaration of css.split(";")) {
		const colon = declaration.indexOf(":");
		if (colon === -1) continue;
		const prop = declaration.slice(0, colon).trim();
		const value = declaration.slice(colon + 1).trim();
		if (!prop) continue;
		const key = prop.startsWith("--")
			? prop
			: prop.replace(/-([a-z])/g, (_, char: string) => char.toUpperCase());
		styleObj[key] = value;
	}

	return styleObj as StyleProperties;
}
