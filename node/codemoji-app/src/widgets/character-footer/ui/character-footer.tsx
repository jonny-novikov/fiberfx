import { cn } from '@/shared/libs'

interface CharacterFooterProps {
  className?: string
}
export const CharacterFooter = ({ className }: CharacterFooterProps) => {
  return (
    <div className={cn(className)}>
      <img src="/images/freeman/freeman-on-throne.webp" alt="character-footer" className="w-full" />
    </div>
  )
}
