import { forwardRef } from 'react'
import { cn } from '../../lib'

export interface StatusBadgeProps
  extends React.HTMLAttributes<HTMLSpanElement> {
  status: 'active' | 'inactive' | 'pending' | 'completed' | 'error' | 'warning'
  children: React.ReactNode
  size?: 'sm' | 'md' | 'lg'
}

const StatusBadge = forwardRef<HTMLSpanElement, StatusBadgeProps>(
  ({ className, status, children, size = 'md', ...props }, ref) => {
    const variants = {
      active: 'bg-green-500/10 text-green-600 border-green-500/20',
      inactive: 'bg-muted text-muted-foreground border-border',
      pending: 'bg-yellow-500/10 text-yellow-600 border-yellow-500/20',
      completed: 'bg-primary/10 text-primary border-primary/20',
      error: 'bg-destructive/10 text-destructive border-destructive/20',
      warning: 'bg-orange-500/10 text-orange-600 border-orange-500/20',
    }

    const sizes = {
      sm: 'px-2 py-1 text-xs',
      md: 'px-3 py-1.5 text-sm',
      lg: 'px-4 py-2 text-base',
    }

    return (
      <span
        ref={ref}
        className={cn(
          'inline-flex items-center rounded-full border font-medium',
          variants[status],
          sizes[size],
          className
        )}
        {...props}
      >
        {children}
      </span>
    )
  }
)

StatusBadge.displayName = 'StatusBadge'

export { StatusBadge }

