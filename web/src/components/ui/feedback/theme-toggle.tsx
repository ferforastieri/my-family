import { MoonIcon, SunIcon } from '@heroicons/react/24/outline'
import { cn } from '../../lib'

export interface ThemeToggleProps {
  theme?: 'light' | 'dark'
  onToggle?: () => void
  className?: string
  size?: 'sm' | 'md' | 'lg'
  variant?: 'default' | 'ghost' | 'outline'
}

export function ThemeToggle({
  theme = 'light',
  onToggle,
  className,
  size = 'md',
  variant = 'default',
}: ThemeToggleProps) {
  const isDark = theme === 'dark'

  const sizeClasses = {
    sm: 'h-7 px-2 text-xs',
    md: 'h-8 px-3 text-sm',
    lg: 'h-10 px-4 text-base',
  }

  const variantClasses = {
    default: 'border border-white/20 bg-white/10 hover:bg-white/20 text-white dark:border-gray-600 dark:bg-gray-700/50 dark:hover:bg-gray-600/50',
    ghost: 'hover:bg-gray-100 dark:hover:bg-gray-800 text-gray-700 dark:text-gray-300',
    outline: 'border border-gray-300 dark:border-gray-600 bg-transparent hover:bg-gray-50 dark:hover:bg-gray-800 text-gray-700 dark:text-gray-300',
  }

  const iconSizes = {
    sm: 'h-3 w-3',
    md: 'h-4 w-4',
    lg: 'h-5 w-5',
  }

  return (
    <button
      onClick={onToggle}
      className={cn(
        'inline-flex items-center justify-center gap-2 rounded-md font-medium transition-colors',
        'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2',
        'disabled:pointer-events-none disabled:opacity-50',
        sizeClasses[size],
        variantClasses[variant],
        className
      )}
      title={isDark ? 'Tema: Escuro' : 'Tema: Claro'}
      type="button"
    >
      {isDark ? (
        <SunIcon className={iconSizes[size]} aria-hidden="true" />
      ) : (
        <MoonIcon className={iconSizes[size]} aria-hidden="true" />
      )}
      <span className="sr-only">Tema: {isDark ? 'Escuro' : 'Claro'}</span>
    </button>
  )
}

