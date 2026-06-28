// wraps value in closure or returns closure
// `value` is a plain value or a zero-arg thunk producing that value; the return
// is always a zero-arg accessor. Generic over the produced value `T` so callers
// keep their precise accessor type (e.g. `() => object`) instead of `() => any`.
export let closure = <T>(value: T | (() => T)): (() => T) => {
  if(typeof value === "function"){
    // The `typeof === "function"` guard cannot narrow `T | (() => T)` to the
    // thunk arm for an unconstrained `T`, so assert the accessor shape here.
    return value as () => T
  } else {
    let closure = function (){ return value }
    return closure
  }
}
