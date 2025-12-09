import { CheckIcon } from '@heroicons/react/24/outline'
import { forwardRef, useState } from 'react'
import { cn } from '../../lib'

export interface CheckboxProps
  extends Omit<React.InputHTMLAttributes<HTMLInputElement>, 'type'> {
  label?: string
  description?: string
  error?: string
  labelClassName?: string
}

const Checkbox = forwardRef<HTMLInputElement, CheckboxProps>(
  (
    {
      className,
      label,
      description,
      error,
      labelClassName,
      id,
      checked: controlledChecked,
      onChange,
      ...props
    },
    ref
  ) => {
    const checkboxId = id || label?.toLowerCase().replace(/\s+/g, '-')
    const [internalChecked, setInternalChecked] = useState(
      props.defaultChecked || false
    )

    const isChecked =
      controlledChecked !== undefined ? controlledChecked : internalChecked

    const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
      if (controlledChecked === undefined) {
        setInternalChecked(e.target.checked)
      }
      onChange?.(e)
    }

    return (
      <div className="space-y-2">
        <div className="flex items-start space-x-3">
          <label
            htmlFor={checkboxId || undefined}
            className="relative flex items-center cursor-pointer"
          >
            <input
              type="checkbox"
              id={checkboxId}
              className="sr-only"
              ref={ref}
              checked={isChecked}
              onChange={handleChange}
              {...props}
            />
            <div
              className={cn(
                'w-5 h-5 rounded border-2 transition-all duration-200 flex items-center justify-center pointer-events-none',
                !isChecked && 'border-border bg-background',
                isChecked && 'bg-primary border-primary',
                'focus-within:ring-2 focus-within:ring-primary focus-within:ring-offset-2',
                props.disabled && 'opacity-50',
                error && !isChecked && 'border-destructive',
                error && isChecked && 'bg-destructive border-destructive',
                className
              )}
            >
              <CheckIcon
                className={cn(
                  'w-3 h-3 text-primary-foreground transition-opacity duration-200',
                  isChecked ? 'opacity-100' : 'opacity-0'
                )}
              />
            </div>
          </label>

          {(label || description) && (
            <div className="flex-1 min-w-0">
              {label && (
                <label
                  htmlFor={checkboxId || undefined}
                  className={cn(
                    'text-sm font-medium cursor-pointer select-none',
                    'text-foreground',
                    props.disabled && 'opacity-50 cursor-not-allowed',
                    error && 'text-destructive',
                    labelClassName
                  )}
                >
                  {label}
                </label>
              )}
              {description && (
                <p
                  className={cn(
                    'text-sm text-muted-foreground mt-1',
                    props.disabled && 'opacity-50',
                    error && 'text-destructive'
                  )}
                >
                  {description}
                </p>
              )}
            </div>
          )}
        </div>

        {error && (
          <p className="text-sm text-destructive ml-8">{error}</p>
        )}
      </div>
    )
  }
)

Checkbox.displayName = 'Checkbox'

export { Checkbox }

