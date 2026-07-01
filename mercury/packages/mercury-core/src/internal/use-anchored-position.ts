import { useCallback, useLayoutEffect, useRef, useState } from "react";
import type { CSSProperties, RefObject } from "react";

/** A side, optionally refined by a cross-axis alignment (`bottom-start` …). */
export type AnchoredPlacement =
	| "top"
	| "bottom"
	| "left"
	| "right"
	| "top-start"
	| "top-end"
	| "bottom-start"
	| "bottom-end"
	| "left-start"
	| "left-end"
	| "right-start"
	| "right-end";

/** Cross-axis alignment for a bare side (`placement: "bottom"` + `align: "end"`). */
export type AnchoredAlign = "start" | "center" | "end";

/** A pointer anchor (e.g. a context menu) — overrides the anchor element's rect. */
export interface AnchoredPoint {
	x: number;
	y: number;
}

/**
 * Options for {@link useAnchoredPosition}.
 */
export interface UseAnchoredPositionOptions {
	/** The placed side (+ optional compound alignment). Default `"bottom-start"`. */
	placement?: AnchoredPlacement;
	/** Cross-axis alignment when `placement` is a bare side. Default `"center"`. */
	align?: AnchoredAlign;
	/** A fixed float width (px). When set, overrides the measured width. */
	width?: number;
	/** Offset between the anchor and the float (px). Default `8`. */
	gap?: number;
	/** Viewport-edge clamp padding (px). Default `8`. */
	padding?: number;
	/** Recompute while open and track scroll/resize. Default open when omitted. */
	open?: boolean;
	/** Pointer anchor — overrides the anchor rect (context-menu case). */
	point?: AnchoredPoint | null;
}

/** The return of {@link useAnchoredPosition}. */
export interface UseAnchoredPositionReturn {
	/** A `position: fixed` style to spread onto the float element. */
	style: CSSProperties;
	/** Force a recompute (e.g. after the float's content resizes). */
	update: () => void;
}

type Side = "top" | "bottom" | "left" | "right";

interface RectLike {
	top: number;
	bottom: number;
	left: number;
	right: number;
}

function normalize(
	placement: AnchoredPlacement,
	alignOpt: AnchoredAlign | undefined,
): { side: Side; align: AnchoredAlign } {
	const dash = placement.indexOf("-");
	const side = (dash === -1 ? placement : placement.slice(0, dash)) as Side;
	const compound = dash === -1 ? undefined : (placement.slice(dash + 1) as AnchoredAlign);
	return { side, align: compound ?? alignOpt ?? "center" };
}

/** Position along one axis: align the float's start/center/end within [start,end]. */
function alongAxis(start: number, end: number, size: number, align: AnchoredAlign): number {
	if (align === "start") return start;
	if (align === "end") return end - size;
	return start + (end - start - size) / 2;
}

function computePosition(
	rect: RectLike,
	floatW: number,
	floatH: number,
	o: UseAnchoredPositionOptions,
): { top: number; left: number } {
	const { side, align } = normalize(o.placement ?? "bottom-start", o.align);
	const gap = o.gap ?? 8;
	const pad = o.padding ?? 8;
	let top = 0;
	let left = 0;
	switch (side) {
		case "top":
			top = rect.top - floatH - gap;
			left = alongAxis(rect.left, rect.right, floatW, align);
			break;
		case "bottom":
			top = rect.bottom + gap;
			left = alongAxis(rect.left, rect.right, floatW, align);
			break;
		case "left":
			left = rect.left - floatW - gap;
			top = alongAxis(rect.top, rect.bottom, floatH, align);
			break;
		case "right":
			left = rect.right + gap;
			top = alongAxis(rect.top, rect.bottom, floatH, align);
			break;
	}
	// Clamp within the viewport so a panel never overflows an edge.
	const maxLeft = Math.max(pad, window.innerWidth - floatW - pad);
	const maxTop = Math.max(pad, window.innerHeight - floatH - pad);
	return {
		top: Math.min(Math.max(pad, top), maxTop),
		left: Math.min(Math.max(pad, left), maxLeft),
	};
}

/**
 * Hand-rolled anchored positioning (no positioning dependency — §D). Places
 * `floatRef` relative to `anchorRef` (or a pointer `point`) using `position:
 * fixed` + `getBoundingClientRect`, so it escapes overflow/stacking contexts and
 * pairs with the `<Portal>`. Recomputes on scroll/resize while open and clamps to
 * the viewport. Supports every enum placement + the pointer case the overlay
 * family needs. Guards the React-19 nullable refs.
 */
export function useAnchoredPosition(
	anchorRef: RefObject<HTMLElement | null>,
	floatRef: RefObject<HTMLElement | null>,
	options: UseAnchoredPositionOptions = {},
): UseAnchoredPositionReturn {
	const optsRef = useRef(options);
	optsRef.current = options;
	const [style, setStyle] = useState<CSSProperties>({
		position: "fixed",
		top: 0,
		left: 0,
		visibility: "hidden",
	});

	const update = useCallback(() => {
		const o = optsRef.current;
		if (o.open === false) return;
		const float = floatRef.current;
		if (!float) return;
		const fr = float.getBoundingClientRect();
		const floatW = o.width ?? fr.width;
		const floatH = fr.height;

		let rect: RectLike | null = null;
		if (o.point) {
			rect = { top: o.point.y, bottom: o.point.y, left: o.point.x, right: o.point.x };
		} else {
			const anchor = anchorRef.current;
			if (anchor) {
				const r = anchor.getBoundingClientRect();
				rect = { top: r.top, bottom: r.bottom, left: r.left, right: r.right };
			}
		}
		if (!rect) return;

		const { top, left } = computePosition(rect, floatW, floatH, o);
		setStyle({
			position: "fixed",
			top,
			left,
			visibility: "visible",
			...(o.width != null ? { width: o.width } : {}),
		});
	}, [anchorRef, floatRef]);

	useLayoutEffect(() => {
		if (options.open === false) return;
		update();
		window.addEventListener("scroll", update, true);
		window.addEventListener("resize", update);
		return () => {
			window.removeEventListener("scroll", update, true);
			window.removeEventListener("resize", update);
		};
	}, [
		options.open,
		options.placement,
		options.align,
		options.width,
		options.gap,
		options.point?.x,
		options.point?.y,
		update,
	]);

	return { style, update };
}
