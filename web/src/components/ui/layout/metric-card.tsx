import { forwardRef } from 'react'
import { cn } from '../../lib'

export interface MetricCardProps
  extends React.HTMLAttributes<HTMLDivElement> {
  title: string
  value: string | number
  subtitle?: string
  secondaryValue?: string | number
  icon?: React.ElementType
  trend?: {
    value: number
    label: string
    isPositive?: boolean
  }
  variant?: 'default' | 'success' | 'warning' | 'danger' | 'blue' | 'blue-light' | 'dark'
}

const MetricCard = forwardRef<HTMLDivElement, MetricCardProps>(
  ({ className, title, value, subtitle, secondaryValue, icon: Icon, trend, variant = 'default', ...props }, ref) => {
    const variants = {
      default: 'border-border bg-popover',
      success: 'border-green-500/20 bg-green-500/10',
      warning: 'border-yellow-500/20 bg-yellow-500/10',
      danger: 'border-destructive/20 bg-destructive/10',
      blue: 'border-foreground bg-foreground text-background',
      'blue-light': 'border-border bg-accent',
      dark: 'border-border bg-muted',
    }

    return (
      <div
        ref={ref}
        className={cn(
          'rounded-2xl border-2 p-4 sm:p-5 lg:p-6 shadow-sm transition-all hover:shadow-md flex flex-col',
          variants[variant],
          className
        )}
        {...props}
      >
        <div className="flex items-center justify-between gap-2 sm:gap-3">
          <div className="flex-1 flex flex-col justify-start min-w-0">
            <div className="min-w-0">
              <p 
                className={`font-medium leading-tight truncate sm:break-words text-sm ${variant === 'blue' ? 'text-background/80' : 'text-muted-foreground'}`}
                title={title}
              >
                {title}
              </p>
              <p 
                className={`font-bold mt-1 leading-tight truncate sm:break-all text-lg sm:text-xl ${variant === 'blue' ? 'text-background' : 'text-foreground'}`}
                title={value.toString()}
              >
                {value}
              </p>
            </div>
            <div className="mt-1">
              {secondaryValue && (
                <p className={`text-xs sm:text-sm leading-tight ${variant === 'blue' ? 'text-background/70' : 'text-muted-foreground'}`}>
                  {secondaryValue}
                </p>
              )}
              {subtitle && (
                <p className={`text-xs sm:text-sm leading-tight ${variant === 'blue' ? 'text-background/70' : 'text-muted-foreground'}`}>
                  {subtitle}
                </p>
              )}
            </div>
          </div>
          <div className="flex flex-col items-end justify-start gap-2">
            {Icon && (
              <div className="flex-shrink-0">
                <Icon className={`h-5 w-5 sm:h-6 sm:w-6 md:h-7 md:w-7 ${variant === 'blue' ? 'text-background/70' : 'text-muted-foreground'}`} />
              </div>
            )}
          </div>
        </div>
        
        {trend && (
          <div className="mt-2 flex items-center">
            <svg className={`w-3 h-3 sm:w-4 sm:h-4 mr-1 ${trend.isPositive !== false ? 'text-green-600' : 'text-red-600'}`} fill="currentColor" viewBox="0 0 20 20">
              {trend.isPositive !== false ? (
                <path fillRule="evenodd" d="M5.293 7.707a1 1 0 010-1.414l4-4a1 1 0 011.414 0l4 4a1 1 0 01-1.414 1.414L11 5.414V17a1 1 0 11-2 0V5.414L6.707 7.707a1 1 0 01-1.414 0z" clipRule="evenodd" />
              ) : (
                <path fillRule="evenodd" d="M14.707 12.293a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 111.414-1.414L9 14.586V3a1 1 0 012 0v11.586l2.293-2.293a1 1 0 011.414 0z" clipRule="evenodd" />
              )}
            </svg>
            <span className={`text-xs sm:text-sm font-medium ${trend.isPositive !== false ? 'text-green-600' : 'text-red-600'}`}>
              {trend.value > 0 ? '+' : ''}{trend.value} {trend.label}
            </span>
          </div>
        )}
      </div>
    )
  }
)

MetricCard.displayName = 'MetricCard'

export { MetricCard }

