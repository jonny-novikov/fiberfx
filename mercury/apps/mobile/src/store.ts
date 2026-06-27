/*
 * Mobile app state — modelled in Effector, the same way a real Mercury consumer
 * wires its cross-cutting state. The @mercury/effector plug owns the theme,
 * toasts, and the send-money form; this file owns auth + navigation.
 */
import { createEvent, createStore } from "effector";
import { useUnit } from "effector-react";
import { createForm } from "@mercury/effector";

export type Tab = "home" | "activity" | "wallet" | "profile";
/** The effective screen — `send` is an overlay reachable from several tabs. */
export type Screen = Tab | "send";
export type Filter = "all" | "in" | "out" | "pend";

/* ── Auth ── */
export const login = createEvent();
export const logout = createEvent();
export const $authed = createStore(true)
  .on(login, () => true)
  .on(logout, () => false);
export const useAuthed = (): boolean => useUnit($authed);

/* ── Navigation ── */
export const setTab = createEvent<Tab>();
export const startSend = createEvent();
/** Leave the send overlay and land on the activity feed (mirrors the mock). */
export const completeSend = createEvent();

export const $tab = createStore<Tab>("home")
  .on(setTab, (_, t) => t)
  .on(completeSend, () => "activity");

// `sending` is a separate flag so returning from Send restores the prior tab.
export const $sending = createStore(false)
  .on(startSend, () => true)
  .on(setTab, () => false)
  .on(completeSend, () => false)
  .on(logout, () => false);

export const useTab = (): Tab => useUnit($tab);
export const useSending = (): boolean => useUnit($sending);

/* ── Activity filter (selection only — the mock doesn't slice the list) ── */
export const setFilter = createEvent<Filter>();
export const $filter = createStore<Filter>("all").on(setFilter, (_, f) => f);
export const useFilter = (): Filter => useUnit($filter);

/* ── Send-money form (the @mercury/effector form plug) ── */
export interface SendValues extends Record<string, unknown> {
  recipient: string;
  amount: string;
  note: string;
}
export const sendForm = createForm<SendValues>({
  initialValues: { recipient: "ana@example.com", amount: "120.00", note: "" },
  validate: ({ recipient, amount }) => {
    const errors: Partial<Record<keyof SendValues, string>> = {};
    if (!recipient.trim()) errors.recipient = "Add a recipient";
    if (!/^\d+(\.\d{1,2})?$/.test(amount.trim())) errors.amount = "Enter a valid amount";
    return errors;
  },
});
