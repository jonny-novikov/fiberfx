import { cn } from '@/shared/libs';

export const ProgressBar = ({
  className,
  label,
  progress = 50,
  colorClassName = 'bg-[#AFC7D6]',
}: {
  className?: string | number;
  label?: string;
  progress?: number;
  colorClassName?: string;
}) => {
  return (
    <div className={cn('flex gap-2 items-center h-4', className)}>
      <div className="w-full h-full bg-[#DDEDFC] rounded-full">
        <div
          className={cn(
            'h-full rounded-l-full',
            {
              'rounded-r-full': progress === 100,
            },
            colorClassName
          )}
          style={{ width: `${progress}%` }}
         />
      </div>
      {label && (
        <p className="text-muted text-[13px] font-medium shrink-0 leading-none">
          {label}
        </p>
      )}
    </div>
  );
};
