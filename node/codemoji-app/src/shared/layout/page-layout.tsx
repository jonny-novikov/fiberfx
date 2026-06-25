import { cn } from '@/shared/libs'

interface PageLayoutProps {
  children: React.ReactNode
  className?: string
}

export const PageLayout = ({ children, className }: PageLayoutProps) => {
  return <div className={cn('flex flex-col gap-3 min-h-screen', className)}>{children}</div>
}
