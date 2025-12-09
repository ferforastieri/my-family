import { forwardRef } from 'react'
import { cn } from '../../lib'

export interface ProgressBarProps
  extends React.HTMLAttributes<HTMLDivElement> {
  value: number
  max?: number
  color?: 'blue' | 'green' | 'purple' | 'orange' | 'red' | 'yellow'
  size?: 'sm' | 'md' | 'lg'
  showLabel?: boolean
}

const ProgressBar = forwardRef<HTMLDivElement, ProgressBarProps>(
  ({ className, value, max = 100, color = 'blue', size = 'md', showLabel = false, ...props }, ref) => {
    const percentage = Math.min(Math.max((value / max) * 100, 0), 100)

    const colors = {
      blue: 'bg-foreground',
      green: 'bg-green-500',
      purple: 'bg-purple-500',
      orange: 'bg-orange-500',
      red: 'bg-destructive',
      yellow: 'bg-yellow-500',
    }

    const sizes = {
      sm: 'h-2',
      md: 'h-3',
      lg: 'h-4',
    }

    return (
      <div
        ref={ref}
        className={cn('w-full', className)}
        {...props}
      >
        <div className={cn(
          'w-full bg-muted rounded-full overflow-hidden',
          sizes[size]
        )}>
          <div
            className={cn(
              'h-full transition-all duration-500 ease-out rounded-full',
              colors[color]
            )}
            style={{ width: `${percentage}%` }}
          />
        </div>
        {showLabel && (
          <div className="mt-1 text-xs text-muted-foreground text-center">
            {percentage.toFixed(1)}%
          </div>
        )}
      </div>
    )
  }
)

ProgressBar.displayName = 'ProgressBar'

export { ProgressBar }

