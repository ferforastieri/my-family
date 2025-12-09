import { Fragment, ReactNode } from 'react'
import { XMarkIcon } from '@heroicons/react/24/outline'

interface ModalProps {
  isOpen: boolean
  onClose: () => void
  title: string
  children: ReactNode
  size?: 'sm' | 'md' | 'lg' | 'xl'
  showCloseButton?: boolean
}

const sizeClasses = {
  sm: 'max-w-md',
  md: 'max-w-lg',
  lg: 'max-w-2xl',
  xl: 'max-w-4xl',
}

export function Modal({
  isOpen,
  onClose,
  title,
  children,
  size = 'md',
  showCloseButton = true,
}: ModalProps) {
  if (!isOpen) return null

  return (
    <div className="fixed inset-0 z-50 overflow-y-auto">
      <div className="flex min-h-full items-center justify-center p-4">
        <div 
          className="fixed inset-0 bg-background/80 backdrop-blur-sm transition-opacity"
          onClick={onClose}
        />
        
        <div className={`relative transform overflow-hidden rounded-2xl bg-popover border border-border p-6 text-left align-middle shadow-xl transition-all w-full ${sizeClasses[size]}`}>
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-lg font-medium leading-6 text-popover-foreground">
              {title}
            </h3>
            {showCloseButton && (
              <button
                type="button"
                className="rounded-xl p-2 text-muted-foreground hover:text-foreground hover:bg-accent transition-colors"
                onClick={onClose}
              >
                <span className="sr-only">Fechar</span>
                <XMarkIcon className="h-5 w-5" />
              </button>
            )}
          </div>
          {children}
        </div>
      </div>
    </div>
  )
}

