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
      default: 'bg-popover border-border text-popover-foreground',
      success: 'bg-green-500/10 border-green-500/20 text-green-600',
      error: 'bg-destructive/10 border-destructive/20 text-destructive',
      warning: 'bg-yellow-500/10 border-yellow-500/20 text-yellow-600',
      info: 'bg-foreground/10 border-border text-foreground',
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
          'flex items-start gap-3 rounded-xl border p-4 shadow-lg transition-all duration-200',
          variants[variant],
          className
        )}
        {...props}
      >
        {Icon && (
          <Icon className="h-5 w-5 flex-shrink-0 mt-0.5" />
        )}
        <div className="flex-1 min-w-0">
          {title && (
            <div className="font-semibold text-sm mb-1">{title}</div>
          )}
          {description && (
            <div className="text-sm opacity-90">{description}</div>
          )}
        </div>
        {onClose && (
          <button
            onClick={onClose}
            className="flex-shrink-0 rounded-xl p-1 hover:bg-accent transition-colors"
            aria-label="Close"
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

