import React, { useState, useRef, useEffect, forwardRef } from 'react'
import { cn } from '../../lib'

export interface DropdownMenuProps extends React.HTMLAttributes<HTMLDivElement> {
  trigger: React.ReactNode
  children: React.ReactNode
  align?: 'left' | 'right' | 'center'
  side?: 'top' | 'bottom'
  onOpenChange?: (open: boolean) => void
}

const DropdownMenu = forwardRef<HTMLDivElement, DropdownMenuProps>(
  ({ className, trigger, children, align = 'left', side = 'bottom', onOpenChange, ...props }, ref) => {
    const [isOpen, setIsOpen] = useState(false)
    const menuRef = useRef<HTMLDivElement>(null)
    const triggerRef = useRef<HTMLDivElement>(null)

    const handleOpenChange = (open: boolean) => {
      setIsOpen(open)
      onOpenChange?.(open)
    }

    const triggerWithState = React.isValidElement(trigger)
      ? React.cloneElement(trigger, {
          className: cn(
            trigger.props.className,
            isOpen && 'bg-accent'
          )
        } as any)
      : trigger

    useEffect(() => {
      const handleClickOutside = (event: MouseEvent) => {
        if (
          menuRef.current &&
          triggerRef.current &&
          !menuRef.current.contains(event.target as Node) &&
          !triggerRef.current.contains(event.target as Node)
        ) {
          handleOpenChange(false)
        }
      }

      if (isOpen) {
        document.addEventListener('mousedown', handleClickOutside)
      }

      return () => {
        document.removeEventListener('mousedown', handleClickOutside)
      }
    }, [isOpen])

    const alignClasses = {
      left: 'left-0',
      right: 'right-0',
      center: 'left-1/2 -translate-x-1/2',
    }

    const sideClasses = {
      top: 'bottom-full mb-2',
      bottom: 'top-full mt-2',
    }

    const childrenWithClose = React.Children.map(children, (child) => {
      if (React.isValidElement(child)) {
        return React.cloneElement(child, {
          onClick: (e: React.MouseEvent) => {
            child.props.onClick?.(e)
            handleOpenChange(false)
          }
        } as any)
      }
      return child
    })

    return (
      <div ref={ref} className={cn('relative inline-block', className)} {...props}>
        <div ref={triggerRef} onClick={() => handleOpenChange(!isOpen)}>
          {triggerWithState}
        </div>
        {isOpen && (
          <div
            ref={menuRef}
            className={cn(
              'absolute z-50 min-w-[11rem] overflow-hidden rounded-md border bg-popover p-1 text-popover-foreground shadow-md',
              alignClasses[align],
              sideClasses[side]
            )}
          >
            {childrenWithClose}
          </div>
        )}
      </div>
    )
  }
)

DropdownMenu.displayName = 'DropdownMenu'

export interface DropdownMenuItemProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  asChild?: boolean
}

const DropdownMenuItem = forwardRef<HTMLButtonElement, DropdownMenuItemProps>(
  ({ className, asChild, children, ...props }, ref) => {
    const baseClasses = 'relative flex cursor-pointer select-none items-center rounded-sm px-2 py-1.5 text-sm outline-none transition-colors focus:bg-accent focus:text-accent-foreground data-[disabled]:pointer-events-none data-[disabled]:opacity-50 w-full text-left'
    
    if (asChild && React.isValidElement(children)) {
      return React.cloneElement(children, {
        className: cn(baseClasses, className),
        ref,
        ...props,
      } as any)
    }
    
    return (
      <button
        ref={ref}
        className={cn(baseClasses, className)}
        {...props}
      >
        {children}
      </button>
    )
  }
)

DropdownMenuItem.displayName = 'DropdownMenuItem'

export { DropdownMenu, DropdownMenuItem }
