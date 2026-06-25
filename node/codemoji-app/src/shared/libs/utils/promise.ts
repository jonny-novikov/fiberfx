export const promiseTimeout = (ms: number) => {
  return new Promise((resolve) => {
    setTimeout(resolve, ms)
  })
}

export const retry = async <TReturn>(
  fn: () => Promise<TReturn>,
  retries = 100,
  baseDelay = 1000
): Promise<TReturn> => {
  for (let i = 0; i < retries; i++) {
    try {
      return await fn()
    } catch (e) {
      console.error(e, `Retry attempt: ${i}, next attempt in ${baseDelay * (i + 1)}ms`)
      await promiseTimeout(baseDelay * (i + 1))
    }
  }

  throw new Error(`Failed to execute function after ${retries} retries`)
}
