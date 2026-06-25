import type { FallbackProps } from 'react-error-boundary'

import { Button } from '@/shared/ui'

export const ErrorFallback = ({ error }: FallbackProps) => {
  return (
    <div className="flex h-[100dvh] w-full items-center justify-center p-6">
      <div className="max-w-md w-full rounded-xl bg-black/50 backdrop-blur-md border border-white/10 p-6 text-center space-y-4">
        <p className="text-xl font-semibold">Generic error</p>
        <p className="text-white/70 break-words">
          {(error && (error.message || String(error))) || 'Generic error'}
        </p>
        <div className="flex gap-3 justify-center">
          <Button>Try Again</Button>
          <Button>Back</Button>
        </div>
      </div>
    </div>
  )
}
