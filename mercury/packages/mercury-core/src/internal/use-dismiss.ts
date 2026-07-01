import { useEffect, useRef } from "react";
import type { RefObject } from "react";
import { isClickTrulyOutside } from "./dom.js";

/**
 * Options for {@link useDismiss}.
 */
export interface UseDismissOptions {
	/** Called when an outside press or `Escape` requests dismissal. */
	onDismiss: () => void;
	/** Dismiss on a press outside `ref`. Default `true`. `AlertDialog` opts out. */
	outsideClick?: boolean;
	/** Dismiss on `Escape`. Default `true`. */
	escapeKey?: boolean;
	/**
	 * Elements whose presses do NOT count as outside — typically the trigger /
	 * anchor, so re-pressing it toggles rather than double-firing dismiss + open.
	 */
	ignore?: ReadonlyArray<RefObject<HTMLElement | null> | null>;
	/** Gate the whole hook — a closed overlay ignores `Escape`/outside. Default `true`. */
	enabled?: boolean;
}

/**
 * The one true outside-press + `Escape` dismiss effect, replacing the overlays'
 * inline copies. Subscribes once while `enabled` and reads the latest options at
 * event time, so `outsideClick`/`escapeKey`/`onDismiss` may change without churn.
 *
 * Uses `pointerdown` (mouse + touch + pen, before `click`) and composes
 * `dom.isClickTrulyOutside`: a press dismisses only when it lands outside the
 * DOM subtree AND outside the content's box (the latter guards password-manager
 * overlays injected outside the tree but visually within). Guards the React-19
 * nullable `ref.current`.
 */
export function useDismiss(
	ref: RefObject<HTMLElement | null>,
	options: UseDismissOptions,
): void {
	const optsRef = useRef(options);
	optsRef.current = options;
	const enabled = options.enabled ?? true;

	useEffect(() => {
		if (!enabled) return;

		const onPointerDown = (event: PointerEvent) => {
			const o = optsRef.current;
			if (o.outsideClick === false) return;
			const content = ref.current;
			if (!content) return;
			const target = event.target as Node | null;
			if (target && content.contains(target)) return;
			if (o.ignore) {
				for (const r of o.ignore) {
					const el = r?.current;
					if (el && target && el.contains(target)) return;
				}
			}
			if (!isClickTrulyOutside(event, content)) return;
			o.onDismiss();
		};

		const onKeyDown = (event: KeyboardEvent) => {
			const o = optsRef.current;
			if (o.escapeKey === false) return;
			if (event.key === "Escape") o.onDismiss();
		};

		document.addEventListener("pointerdown", onPointerDown, true);
		document.addEventListener("keydown", onKeyDown, true);
		return () => {
			document.removeEventListener("pointerdown", onPointerDown, true);
			document.removeEventListener("keydown", onKeyDown, true);
		};
	}, [enabled, ref]);
}
