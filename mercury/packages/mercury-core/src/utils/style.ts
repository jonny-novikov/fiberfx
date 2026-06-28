import { styleToCSS } from "./style-to-css.js";
import type { StyleProperties } from "../types";

export function styleToString(style: StyleProperties = {}): string {
	return styleToCSS(style).replace("\n", " ");
}
