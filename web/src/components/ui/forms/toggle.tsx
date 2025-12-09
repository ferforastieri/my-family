import { forwardRef, useState } from 'react'
import { cn } from '../../lib'

export interface ToggleProps
  extends Omit<React.InputHTMLAttributes<HTMLInputElement>, 'type' | 'size'> {
  label?: string
  description?: string
  size?: 'sm' | 'md' | 'lg'
}

const Toggle = forwardRef<HTMLInputElement, ToggleProps>(
  ({ className, label, description, size = 'md', id, checked, onChange, ...props }, ref) => {
    const toggleId = id || label?.toLowerCase().replace(/\s+/g, '-')
    const [isChecked, setIsChecked] = useState(checked || false)

    const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
      setIsChecked(e.target.checked)
      onChange?.(e)
    }

    const isActive = checked !== undefined ? checked : isChecked

    return (
      <div className="flex items-center space-x-3">
        <label
          htmlFor={toggleId}
          className={cn(
            'relative inline-flex items-center rounded-full border-2 transition-all duration-200 cursor-pointer',
            size === 'sm' && 'w-8 h-4',
            size === 'md' && 'w-11 h-6', 
            size === 'lg' && 'w-14 h-7',
            'border-border bg-muted',
            props.disabled && 'opacity-50 cursor-not-allowed',
            isActive && 'bg-foreground border-foreground',
            className
          )}
        >
          <input
            type="checkbox"
            id={toggleId}
            className="sr-only"
            ref={ref}
            checked={isActive}
            onChange={handleChange}
            {...props}
          />
          <div
            className={cn(
              'absolute bg-background rounded-full shadow-lg transition-transform duration-200',
              size === 'sm' && 'w-3 h-3',
              size === 'md' && 'w-5 h-5',
              size === 'lg' && 'w-6 h-6',
              'left-0.5',
              isActive && size === 'sm' && 'translate-x-4',
              isActive && size === 'md' && 'translate-x-5',
              isActive && size === 'lg' && 'translate-x-7'
            )}
          />
        </label>

        {(label || description) && (
          <div className="flex-1 min-w-0">
            {label && (
              <span
                className={cn(
                  'text-sm font-medium cursor-pointer select-none',
                  'text-foreground',
                  props.disabled && 'opacity-50 cursor-not-allowed'
                )}
              >
                {label}
              </span>
            )}
            {description && (
              <p
                className={cn(
                  'text-sm text-muted-foreground mt-1',
                  props.disabled && 'opacity-50'
                )}
              >
                {description}
              </p>
            )}
          </div>
        )}
      </div>
    )
  }
)

Toggle.displayName = 'Toggle'

export { Toggle }

