import { cn } from '../../libs'

function Skeleton({ className, ...props }: React.HTMLAttributes<HTMLDivElement>) {
  return <div className={cn('animate-pulse rounded-md bg-white/60', className)} {...props} />
}

export { Skeleton }
