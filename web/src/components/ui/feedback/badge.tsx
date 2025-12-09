import { forwardRef } from 'react'
import { cn } from '../../lib'

export interface BadgeProps extends React.HTMLAttributes<HTMLSpanElement> {
  variant?: 'default' | 'secondary' | 'destructive' | 'outline' | 'primary' | 'high' | 'medium' | 'low'
}

const Badge = forwardRef<HTMLSpanElement, BadgeProps>(
  ({ className, variant = 'default', ...props }, ref) => {
    const variants = {
      default: 'bg-foreground text-background border-foreground',
      secondary: 'bg-muted text-foreground border-border',
      destructive: 'bg-destructive text-destructive-foreground border-destructive',
      outline: 'text-foreground border-border',
      primary: 'bg-transparent text-primary border-primary',
      high: 'bg-red-500/10 text-red-600 border-red-500/20',
      medium: 'bg-yellow-500/10 text-yellow-600 border-yellow-500/20',
      low: 'bg-green-500/10 text-green-600 border-green-500/20',
    }

    return (
      <span
        ref={ref}
        className={cn(
          'inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-semibold transition-colors',
          variants[variant],
          className
        )}
        {...props}
      />
    )
  }
)

Badge.displayName = 'Badge'

export { Badge }

