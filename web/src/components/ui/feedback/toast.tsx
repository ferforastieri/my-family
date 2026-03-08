import { forwardRef } from 'react'
import { XMarkIcon, CheckCircleIcon, ExclamationCircleIcon, InformationCircleIcon, XCircleIcon } from '@heroicons/react/24/outline'
import { cn } from '../../lib'

export interface ToastProps extends React.HTMLAttributes<HTMLDivElement> {
  title?: string
  description?: string
  variant?: 'default' | 'success' | 'error' | 'warning' | 'info'
  onClose?: () => void
}

const Toast = forwardRef<HTMLDivElement, ToastProps>(
  ({ className, title, description, variant = 'default', onClose, ...props }, ref) => {
    const variants = {
      default: 'bg-card border-border text-foreground shadow-lg',
      success: 'bg-card border-primary/50 text-foreground shadow-lg',
      error: 'bg-card border-destructive text-foreground shadow-lg',
      warning: 'bg-card border-border text-foreground shadow-lg',
      info: 'bg-card border-primary/50 text-foreground shadow-lg',
    }

    const iconClasses = {
      default: 'text-primary',
      success: 'text-primary',
      error: 'text-destructive',
      warning: 'text-primary',
      info: 'text-primary',
    }

    const icons = {
      default: null,
      success: CheckCircleIcon,
      error: XCircleIcon,
      warning: ExclamationCircleIcon,
      info: InformationCircleIcon,
    }

    const Icon = icons[variant]

    return (
      <div
        ref={ref}
        className={cn(
          'flex items-start gap-3 rounded-xl border-2 p-4 transition-all duration-200',
          variants[variant],
          className
        )}
        {...props}
      >
        {Icon && (
          <Icon className={cn('h-5 w-5 flex-shrink-0 mt-0.5', iconClasses[variant])} />
        )}
        <div className="flex-1 min-w-0">
          {title && (
            <div className="font-semibold text-sm mb-0.5">{title}</div>
          )}
          {description && (
            <div className="text-sm text-pink-800/90">{description}</div>
          )}
        </div>
        {onClose && (
          <button
            onClick={onClose}
            className="flex-shrink-0 rounded-lg p-1 hover:bg-accent text-muted-foreground hover:text-foreground transition-colors"
            aria-label="Fechar"
          >
            <XMarkIcon className="h-4 w-4" />
          </button>
        )}
      </div>
    )
  }
)

Toast.displayName = 'Toast'

export { Toast }

