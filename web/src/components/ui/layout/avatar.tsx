import { forwardRef } from 'react'
import { cn } from '../../lib'

export interface AvatarProps
  extends React.HTMLAttributes<HTMLDivElement> {
  src?: string
  alt?: string
  fallback?: string
  size?: 'sm' | 'md' | 'lg' | 'xl'
  shape?: 'circle' | 'square'
}

const Avatar = forwardRef<HTMLDivElement, AvatarProps>(
  ({ className, src, alt, fallback, size = 'md', shape = 'circle', ...props }, ref) => {
    const sizes = {
      sm: 'h-8 w-8 text-xs',
      md: 'h-10 w-10 text-sm',
      lg: 'h-12 w-12 text-base',
      xl: 'h-16 w-16 text-lg',
    }

    const shapes = {
      circle: 'rounded-full',
      square: 'rounded-lg',
    }

    const getInitials = (name: string) => {
      return name
        .split(' ')
        .map(word => word.charAt(0))
        .join('')
        .toUpperCase()
        .slice(0, 2)
    }

    return (
      <div
        ref={ref}
        className={cn(
          'relative flex items-center justify-center overflow-hidden bg-muted text-muted-foreground',
          sizes[size],
          shapes[shape],
          className
        )}
        {...props}
      >
        {src ? (
          <img
            src={src}
            alt={alt || 'Avatar'}
            className="h-full w-full object-cover"
          />
        ) : (
          <span className="font-medium">
            {fallback ? getInitials(fallback) : '?'}
          </span>
        )}
      </div>
    )
  }
)

Avatar.displayName = 'Avatar'

export { Avatar }

