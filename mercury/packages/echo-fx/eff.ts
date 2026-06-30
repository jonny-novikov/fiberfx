// core.ts — the fx ResultAsync effect (the surface the route handlers use: .map, .flatMap,
// .validate, .mapErr; fx.pure / fx.query / fx.all etc.), BCS branded ids, and the
// admin error type with a boundary mapper. No game logic lives here.

// ───────────────────────── Result ─────────────────────────
export type Result<E, A> = { readonly ok: true; readonly value: A } | { readonly ok: false; readonly error: E };
export const ok = <A>(value: A): Result<never, A> => ({ ok: true, value });
export const err = <E>(error: E): Result<E, never> => ({ ok: false, error });

// ───────────────────────── fx: ResultAsync effect ─────────────────────────
export class Eff<E, A> {
  constructor(private readonly _run: () => Promise<Result<E, A>>) {}
  run(): Promise<Result<E, A>> {
    return this._run();
  }
  map<B>(f: (a: A) => B): Eff<E, B> {
    return new Eff(async () => {
      const r = await this._run();
      return r.ok ? ok(f(r.value)) : r;
    });
  }
  flatMap<E2, B>(f: (a: A) => Eff<E2, B>): Eff<E | E2, B> {
    return new Eff<E | E2, B>(async () => {
      const r = await this._run();
      return r.ok ? f(r.value).run() : r;
    });
  }
  /** Guard the success value; fail with toErr(value) when the predicate is false. */
  validate<E2>(pred: (a: A) => boolean, toErr: (a: A) => E2): Eff<E | E2, A> {
    return new Eff<E | E2, A>(async () => {
      const r = await this._run();
      if (!r.ok) return r;
      return pred(r.value) ? r : err(toErr(r.value));
    });
  }
  mapErr<E2>(f: (e: E) => E2): Eff<E2, A> {
    return new Eff(async () => {
      const r = await this._run();
      return r.ok ? r : err(f(r.error));
    });
  }
  /** Side-effect on success without changing the value (telemetry, audit). */
  tap(f: (a: A) => void): Eff<E, A> {
    return this.map((a) => (f(a), a));
  }
}

export const fx = {
  pure: <A>(a: A): Eff<never, A> => new Eff(async () => ok(a)),
  fail: <E>(e: E): Eff<E, never> => new Eff(async () => err(e)),
  /** Lift a read whose only failure is infrastructure (caught into a Db error). */
  query: <A>(thunk: () => Promise<A>): Eff<Err, A> =>
    new Eff(async () => {
      try {
        return ok(await thunk());
      } catch (e) {
        return err(Err.db(e instanceof Error ? e.message : String(e)));
      }
    }),
  /** Lift an effectful op that returns its own Result; thrown exceptions become Db errors. */
  tryResult: <A>(thunk: () => Promise<Result<Err, A>>): Eff<Err, A> =>
    new Eff(async () => {
      try {
        return await thunk();
      } catch (e) {
        return err(Err.db(e instanceof Error ? e.message : String(e)));
      }
    }),
  /** Run effects concurrently; the first error wins (fewer wall-clock round-trips). */
  all: <E, A>(effs: ReadonlyArray<Eff<E, A>>): Eff<E, A[]> =>
    new Eff(async () => {
      const rs = await Promise.all(effs.map((e) => e.run()));
      const out: A[] = [];
      for (const r of rs) {
        if (!r.ok) return r;
        out.push(r.value);
      }
      return ok(out);
    }),
  /** Lift a nullable into the error channel with a not-found-style error. */
  required: <A>(a: A | null | undefined, onMissing: () => Err): Eff<Err, A> =>
    a === null || a === undefined ? fx.fail(onMissing()) : fx.pure(a),
};
