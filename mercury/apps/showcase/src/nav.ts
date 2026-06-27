/* Navigation model — the sidebar groups, the overview card grid, and the
 * breadcrumb derivation. Pure data; the chrome renders it. */
import type { Route } from "./store";

export interface NavItem {
  route: Route;
  label: string;
}
export interface NavGroup {
  label: string;
  items: NavItem[];
}

export const NAV: NavGroup[] = [
  {
    label: "Getting started",
    items: [{ route: "overview", label: "Overview" }],
  },
  {
    label: "Foundations",
    items: [
      { route: "foundations/colors", label: "Colors" },
      { route: "foundations/type", label: "Typography" },
      { route: "foundations/spacing", label: "Spacing & radius" },
    ],
  },
  {
    label: "Components",
    items: [
      { route: "components/button", label: "Button" },
      { route: "components/input", label: "Input" },
      { route: "components/selection", label: "Selection" },
      { route: "components/chip", label: "Chip & Badge" },
      { route: "components/avatar", label: "Avatar" },
      { route: "components/alert", label: "Alert" },
      { route: "components/progress", label: "Progress" },
      { route: "components/tabs", label: "Tabs" },
      { route: "components/modal", label: "Modal" },
      { route: "components/table", label: "Table" },
    ],
  },
  {
    label: "Patterns",
    items: [
      { route: "patterns/forms", label: "Form · Sign-in" },
      { route: "patterns/dashboard", label: "Dashboard" },
    ],
  },
];

export interface OverviewCard {
  route: Route;
  title: string;
  desc: string;
}

export const OVERVIEW_CARDS: OverviewCard[] = [
  { route: "foundations/colors", title: "Colors", desc: "Slate, iris, indigo scales plus status hues." },
  { route: "foundations/type", title: "Typography", desc: "DM Sans, DM Mono, DM Serif Display — seven roles." },
  { route: "foundations/spacing", title: "Spacing & radius", desc: "4-point base, radius tokens, elevation shadows." },
  { route: "components/button", title: "Button", desc: "Six variants, three sizes, leading / trailing slots." },
  { route: "components/input", title: "Input", desc: "Labels, hints, validation, leading adornments." },
  { route: "components/selection", title: "Selection", desc: "Checkbox, radio, switch, segmented control." },
  { route: "components/chip", title: "Chip & Badge", desc: "Status tags, filters, count pills." },
  { route: "components/avatar", title: "Avatar", desc: "Initials, images, presence dots." },
  { route: "components/alert", title: "Alert", desc: "Info, positive, caution, negative banners." },
  { route: "components/tabs", title: "Tabs", desc: "Underline and pill variants." },
  { route: "components/modal", title: "Modal", desc: "Dialog with header, body, footer." },
  { route: "components/table", title: "Table", desc: "Data table with custom cell renderers." },
  { route: "patterns/forms", title: "Form pattern", desc: "A realistic sign-in form composed from primitives." },
  { route: "patterns/dashboard", title: "Dashboard", desc: "Metrics, table and status composition." },
];

/** "components / button" → "components / button"; "overview" → "overview". */
export function crumb(route: Route): string {
  const seg = route.split("/");
  return seg.length > 1 ? `${seg[0]} / ${seg[1]}` : seg[0] || "overview";
}
