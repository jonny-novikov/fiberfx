import { createEvent, createStore } from "effector";
import { useUnit } from "effector-react";

/**
 * createCooldown — a countdown timer as Effector state, for "resend in 30s"
 * style rate-limit affordances. The interval lives outside React; components
 * read `useCooldown()` and call `start(seconds)`.
 */
export function createCooldown() {
  const started = createEvent<number>();
  const ticked = createEvent();
  const stopped = createEvent();

  const $remaining = createStore(0)
    .on(started, (_, seconds) => Math.max(0, Math.floor(seconds)))
    .on(ticked, (n) => Math.max(0, n - 1))
    .on(stopped, () => 0);

  let timer: ReturnType<typeof setInterval> | null = null;
  function clear() {
    if (timer !== null) {
      clearInterval(timer);
      timer = null;
    }
  }

  function start(seconds: number) {
    clear();
    started(seconds);
    timer = setInterval(() => {
      ticked();
      if ($remaining.getState() <= 0) clear();
    }, 1000);
  }

  function stop() {
    clear();
    stopped();
  }

  const useCooldown = (): number => useUnit($remaining);

  return { $remaining, start, stop, useCooldown };
}
