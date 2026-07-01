import { useEffect, useRef } from "react";
import type { RefObject } from "react";
import type { FocusableTarget } from "./focus.js";
import { shouldEnableFocusTrap } from "./should-enable-focus-trap.js";

/**
 * Options for {@link useFocusTrap}.
 */
export interface UseFocusTrapOptions {
	/** While `true`, `Tab`/`Shift+Tab` cycle within `ref`'s focusable descendants. */
	active: boolean;
	/**
	 * Where focus returns on deactivate — the trigger. Accepts a ref or a direct
	 * element. When omitted, focus returns to whatever held it when the trap engaged.
	 */
	returnFocusTo?: RefObject<FocusableTarget | null> | FocusableTarget | null;
	/**
	 * The element to focus first on engage (e.g. an alert dialog's confirm action).
	 * When omitted, focus moves to the first focusable descendant, else the container.
	 */
	initialFocus?: RefObject<FocusableTarget | null> | null;
	/** Composes `shouldEnableFocusTrap` — a portal that stays mounted while closed. */
	forceMount?: boolean;
}

const FOCUSABLE_SELECTOR = [
	"a[href]",
	"button:not([disabled])",
	"input:not([disabled])",
	"textarea:not([disabled])",
	"select:not([disabled])",
	'[tabindex]:not([tabindex="-1"])',
].join(",");

function isVisible(el: HTMLElement): boolean {
	return !!(el.offsetWidth || el.offsetHeight || el.getClientRects().length);
}

/** The visible, tabbable descendants of `container`, in DOM order. */
function getFocusableDescendants(container: HTMLElement): HTMLElement[] {
	const nodes = Array.from(container.querySelectorAll<HTMLElement>(FOCUSABLE_SELECTOR));
	return nodes.filter((el) => isVisible(el) && el.getAttribute("aria-hidden") !== "true");
}

function resolveTarget(
	t: RefObject<FocusableTarget | null> | FocusableTarget | null | undefined,
): FocusableTarget | null {
	if (!t) return null;
	if ("current" in t) return t.current;
	return t;
}

/**
 * Headless focus trap + focus return. While `active`, keyboard focus is confined
 * to `ref`'s focusable descendants (Tab wraps last→first, Shift+Tab first→last,
 * and focus that escapes is pulled back); on deactivate, focus returns to
 * `returnFocusTo` (or the element that held focus when the trap engaged).
 *
 * JSX/portal-free — the `<Portal>` wrapper lives in `@mercury/ui`. Guards the
 * React-19 nullable `ref.current`.
 */
export function useFocusTrap(
	ref: RefObject<HTMLElement | null>,
	{ active, returnFocusTo, initialFocus, forceMount = false }: UseFocusTrapOptions,
): void {
	const previouslyFocused = useRef<FocusableTarget | null>(null);

	useEffect(() => {
		const enabled = shouldEnableFocusTrap({ forceMount, open: active });
		const container = ref.current;
		if (!enabled || !container) return;

		previouslyFocused.current = (document.activeElement as FocusableTarget | null) ?? null;

		const explicit = resolveTarget(initialFocus);
		const firstFocusable = getFocusableDescendants(container).at(0) ?? null;
		(explicit ?? firstFocusable ?? container).focus?.();

		const onKeyDown = (event: KeyboardEvent) => {
			if (event.key !== "Tab") return;
			const focusables = getFocusableDescendants(container);
			if (focusables.length === 0) {
				event.preventDefault();
				container.focus?.();
				return;
			}
			const first = focusables[0];
			const last = focusables[focusables.length - 1];
			const activeEl = document.activeElement as HTMLElement | null;
			// Focus has escaped the container — pull it back to an edge.
			if (!activeEl || !container.contains(activeEl)) {
				event.preventDefault();
				(event.shiftKey ? last : first)?.focus?.();
				return;
			}
			if (event.shiftKey && activeEl === first) {
				event.preventDefault();
				last?.focus?.();
			} else if (!event.shiftKey && activeEl === last) {
				event.preventDefault();
				first?.focus?.();
			}
		};

		document.addEventListener("keydown", onKeyDown, true);
		return () => {
			document.removeEventListener("keydown", onKeyDown, true);
			(resolveTarget(returnFocusTo) ?? previouslyFocused.current)?.focus?.();
		};
	}, [active, forceMount, ref, returnFocusTo, initialFocus]);
}
