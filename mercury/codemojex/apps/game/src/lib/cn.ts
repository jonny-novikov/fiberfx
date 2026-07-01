// The one class-merge point (cmt.4.1-D3): clsx composes conditional inputs,
// tailwind-merge resolves conflicting utilities (last wins). The smoke — and the
// cmt.4.2 board composition after it — import this as `@/lib/cn`.
import { clsx, type ClassValue } from "clsx";
import { twMerge } from "tailwind-merge";

export function cn(...inputs: ClassValue[]): string {
  return twMerge(clsx(inputs));
}
