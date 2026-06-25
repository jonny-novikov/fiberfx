interface AnimatedLoadingTextProps {
  text: string
  className?: string
}

export const AnimatedLoadingText = ({ text, className }: AnimatedLoadingTextProps) => {
  return (
    <span className={className}>
      {text}
      <span className="inline-flex w-[1.5em]">
        <span className="animate-dot-1">.</span>
        <span className="animate-dot-2">.</span>
        <span className="animate-dot-3">.</span>
      </span>
    </span>
  )
}
