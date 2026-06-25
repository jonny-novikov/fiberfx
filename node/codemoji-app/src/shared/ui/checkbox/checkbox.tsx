import * as RadixCheckbox from '@radix-ui/react-checkbox';

import { cn } from '@/shared/libs';

interface CheckboxProps {
  checked: boolean;
  onChange: (checked: boolean) => void;
  labelRight?: React.ReactNode;
  labelLeft?: React.ReactNode;
  description?: string;
  className?: string;
  disabled?: boolean;
}

export const Checkbox = ({
  checked,
  onChange,
  labelRight,
  labelLeft,
  description,
  className,
  disabled = false,
}: CheckboxProps) => {
  return (
    <label
      className={cn(
        'flex items-start gap-3 cursor-pointer select-none',
        disabled && 'opacity-50 cursor-not-allowed',
        className
      )}
    >
      {labelLeft && (
        <div className="flex-1 flex flex-col gap-1">
          {labelLeft && (
            <span className="text-sm font-medium text-dark-muted leading-tight">
              {labelLeft}
            </span>
          )}
          {description && (
            <span className="text-xs text-muted leading-tight">
              {description}
            </span>
          )}
        </div>
      )}
      <RadixCheckbox.Root
        checked={checked}
        onCheckedChange={onChange}
        disabled={disabled}
        className={cn(
          'size-7 rounded-lg border-2 transition-all duration-200',
          'flex items-center justify-center flex-shrink-0 mt-0.5',
          'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-accent/50 focus-visible:ring-offset-2',
          checked
            ? 'bg-[#00D567] border-[#00D567]'
            : 'bg-white border-[#E8F3F7]'
        )}
      >
        <RadixCheckbox.Indicator className="flex items-center justify-center">
          <svg
            className="w-3.5 h-3.5 text-white"
            viewBox="0 0 12 10"
            fill="none"
            xmlns="http://www.w3.org/2000/svg"
          >
            <path
              d="M1 5L4.5 8.5L11 1.5"
              stroke="currentColor"
              strokeWidth="2"
              strokeLinecap="round"
              strokeLinejoin="round"
            />
          </svg>
        </RadixCheckbox.Indicator>
      </RadixCheckbox.Root>
      {labelRight && (
        <div className="flex-1 flex flex-col gap-1">
          {labelRight && (
            <span className="text-sm font-medium text-dark-muted leading-tight">
              {labelRight}
            </span>
          )}
          {description && (
            <span className="text-xs text-muted leading-tight">
              {description}
            </span>
          )}
        </div>
      )}
    </label>
  );
};
