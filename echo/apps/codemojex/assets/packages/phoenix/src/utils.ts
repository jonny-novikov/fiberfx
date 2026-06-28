// wraps value in closure or returns closure
// `value` is genuinely untyped upstream (a plain value or a thunk); the return
// is always a zero-arg accessor. `any` matches @types/phoenix's untyped posture.
export let closure = (value: any): (() => any) => {
  if(typeof value === "function"){
    return value
  } else {
    let closure = function (){ return value }
    return closure
  }
}
