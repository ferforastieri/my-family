import { Fragment, ReactNode } from 'react'
import { XMarkIcon } from '@heroicons/react/24/outline'

export interface SheetProps {
  isOpen: boolean
  onClose: () => void
  children: ReactNode
  side?: 'top' | 'right' | 'bottom' | 'left'
  size?: 'sm' | 'md' | 'lg' | 'xl' | 'full'
}

const sideClasses = {
  top: 'top-0 left-0 right-0',
  right: 'top-0 right-0 bottom-0',
  bottom: 'bottom-0 left-0 right-0',
  left: 'top-0 left-0 bottom-0',
}

const sizeClasses = {
  sm: 'w-64',
  md: 'w-80',
  lg: 'w-96',
  xl: 'w-[28rem]',
  full: 'w-full',
}

export function Sheet({
  isOpen,
  onClose,
  children,
  side = 'right',
  size = 'md',
}: SheetProps) {
  if (!isOpen) return null

  return (
    <div className="fixed inset-0 z-50">
      <div 
        className="fixed inset-0 bg-black bg-opacity-25 transition-opacity"
        onClick={onClose}
      />
      <div 
        className={`
          fixed ${sideClasses[side]} 
          ${size === 'full' ? '' : sizeClasses[size]}
          bg-white dark:bg-gray-800 
          shadow-xl 
          transition-transform duration-300 ease-in-out
          ${side === 'right' ? 'translate-x-0' : ''}
          ${side === 'left' ? 'translate-x-0' : ''}
          ${side === 'top' ? 'translate-y-0' : ''}
          ${side === 'bottom' ? 'translate-y-0' : ''}
        `}
      >
        <div className="relative h-full flex flex-col">
          <button
            type="button"
            className="absolute top-4 right-4 z-10 rounded-md p-2 text-gray-400 hover:text-gray-500 hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors"
            onClick={onClose}
          >
            <span className="sr-only">Fechar</span>
            <XMarkIcon className="h-5 w-5" />
          </button>
          {children}
        </div>
      </div>
    </div>
  )
}

