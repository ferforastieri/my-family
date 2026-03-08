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
      default: 'bg-pink-50 border-pink-300 text-pink-900 shadow-lg shadow-pink-300/40',
      success: 'bg-pink-50 border-pink-400 text-pink-900 shadow-lg shadow-pink-300/40',
      error: 'bg-pink-50 border-rose-400 text-rose-800 shadow-lg shadow-rose-300/40',
      warning: 'bg-pink-50 border-pink-400 text-pink-900 shadow-lg shadow-pink-300/40',
      info: 'bg-pink-50 border-pink-300 text-pink-900 shadow-lg shadow-pink-300/40',
    }

    const iconClasses = {
      default: 'text-pink-600',
      success: 'text-pink-600',
      error: 'text-rose-600',
      warning: 'text-pink-600',
      info: 'text-pink-600',
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
            className="flex-shrink-0 rounded-lg p-1 hover:bg-pink-100 text-gray-500 hover:text-gray-700 transition-colors"
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

