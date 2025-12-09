import { createContext, useContext, useState, useCallback, ReactNode } from 'react'
import { Toast, ToastProps } from './toast'

export interface ToastItem extends Omit<ToastProps, 'onClose'> {
  id: string
  duration?: number
}

interface ToastContextType {
  toasts: ToastItem[]
  showToast: (toast: Omit<ToastItem, 'id'>) => void
  removeToast: (id: string) => void
}

const ToastContext = createContext<ToastContextType | undefined>(undefined)

export function ToastProvider({ children }: { children: ReactNode }) {
  const [toasts, setToasts] = useState<ToastItem[]>([])

  const showToast = useCallback((toast: Omit<ToastItem, 'id'>) => {
    const id = Math.random().toString(36).substring(2, 9)
    const newToast: ToastItem = { ...toast, id, duration: toast.duration ?? 3000 }

    setToasts((prev) => [...prev, newToast])

    if (newToast.duration && newToast.duration > 0) {
      setTimeout(() => {
        setToasts((prev) => prev.filter((t) => t.id !== id))
      }, newToast.duration)
    }
  }, [])

  const removeToast = useCallback((id: string) => {
    setToasts((prev) => prev.filter((t) => t.id !== id))
  }, [])

  return (
    <ToastContext.Provider value={{ toasts, showToast, removeToast }}>
      {children}
      <div className="fixed bottom-4 left-1/2 -translate-x-1/2 z-50 flex flex-col gap-2 max-w-md w-full px-4 pointer-events-none">
        {toasts.map((toast) => (
          <div 
            key={toast.id} 
            className="pointer-events-auto transition-all duration-300 ease-in-out"
            style={{
              animation: 'slideInUp 0.3s ease-out',
            }}
          >
            <Toast
              {...toast}
              onClose={() => removeToast(toast.id)}
            />
          </div>
        ))}
      </div>
      <style>{`
        @keyframes slideInUp {
          from {
            opacity: 0;
            transform: translateY(20px);
          }
          to {
            opacity: 1;
            transform: translateY(0);
          }
        }
      `}</style>
    </ToastContext.Provider>
  )
}

export function useToast() {
  const context = useContext(ToastContext)
  if (!context) {
    throw new Error('useToast must be used within a ToastProvider')
  }
  return context
}

