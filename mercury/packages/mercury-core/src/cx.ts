export type ClassValue = string | false | null | undefined;

/** Tiny classNames join — filters falsy, joins with spaces. */
export function cx(...parts: ClassValue[]): string {
  return parts.filter(Boolean).join(" ");
}
