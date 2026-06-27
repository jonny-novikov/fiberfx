/*
 * Pure presentational data for the mobile app — deterministic, no Date/random,
 * so every render is identical. Mirrors the fixtures in static/mobile-app.html.
 */
import type { Filter } from "./store";

export interface ActRow {
  title: string;
  meta: string;
  amount: string;
  /** Incoming (green, down-left arrow) vs outgoing (neutral, up-right arrow). */
  positive: boolean;
}

export const HOME_ACTIVITY: ActRow[] = [
  { title: "Ana Reyes", meta: "Today · Transfer", amount: "−$86.50", positive: false },
  { title: "Top-up · Visa ••4921", meta: "Yesterday", amount: "+$500.00", positive: true },
  { title: "Karim Li", meta: "Mon · Transfer", amount: "−$42.00", positive: false },
  { title: "Refund · Uber", meta: "Sun", amount: "+$12.80", positive: true },
];

export const ALL_ACTIVITY: ActRow[] = [
  { title: "Ana Reyes", meta: "Today · Transfer", amount: "−$86.50", positive: false },
  { title: "Top-up · Visa ••4921", meta: "Yesterday", amount: "+$500.00", positive: true },
  { title: "Spotify", meta: "Mon · Subscription", amount: "−$9.99", positive: false },
  { title: "Karim Li", meta: "Mon · Transfer", amount: "−$42.00", positive: false },
  { title: "Refund · Uber", meta: "Sun", amount: "+$12.80", positive: true },
  { title: "Sofia HM", meta: "Sat · Transfer", amount: "−$512.00", positive: false },
];

export const FILTERS: { label: string; value: Filter }[] = [
  { label: "All", value: "all" },
  { label: "Incoming", value: "in" },
  { label: "Outgoing", value: "out" },
  { label: "Pending", value: "pend" },
];

export const BALANCE = {
  label: "Available balance",
  ccy: "USD",
  amount: "4,218.40",
  delta: "+$128.20 this week",
};

export const SCREEN_TITLES: Record<string, string> = {
  home: "Home",
  activity: "Activity",
  send: "Send money",
  wallet: "Wallet",
  profile: "You",
};
