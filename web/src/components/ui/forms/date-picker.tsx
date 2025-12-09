import { CalendarIcon, ChevronLeftIcon, ChevronRightIcon } from '@heroicons/react/24/outline'
import { forwardRef, useState, useEffect, useRef } from 'react'
import { cn } from '../../lib'
import { Button } from './button'

export interface DatePickerProps
  extends Omit<React.InputHTMLAttributes<HTMLInputElement>, 'type' | 'value' | 'onChange'> {
  label?: string
  error?: string
  value?: string
  onChange?: (value: string) => void
}

const DatePicker = forwardRef<HTMLInputElement, DatePickerProps>(
  ({ className, label, error, id, value, onChange, ...props }, ref) => {
    const dateId = id || label?.toLowerCase().replace(/\s+/g, '-')
    const [displayValue, setDisplayValue] = useState('')
    const [inputValue, setInputValue] = useState('')
    const [isOpen, setIsOpen] = useState(false)
    const [currentMonth, setCurrentMonth] = useState(new Date())
    const containerRef = useRef<HTMLDivElement>(null)

    useEffect(() => {
      if (value) {
        const [year, month, day] = value.split('-')
        if (year && month && day) {
          setDisplayValue(`${day}/${month}/${year}`)
          setInputValue(value)
        }
      } else {
        setDisplayValue('')
        setInputValue('')
      }
    }, [value])

    useEffect(() => {
      const handleClickOutside = (event: MouseEvent) => {
        if (containerRef.current && !containerRef.current.contains(event.target as Node)) {
          setIsOpen(false)
        }
      }

      if (isOpen) {
        document.addEventListener('mousedown', handleClickOutside)
        return () => document.removeEventListener('mousedown', handleClickOutside)
      }
    }, [isOpen])

    const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
      const input = e.target.value.replace(/\D/g, '')
      
      let formatted = ''
      if (input.length >= 1) formatted += input.slice(0, 2)
      if (input.length >= 3) formatted += '/' + input.slice(2, 4)
      if (input.length >= 5) formatted += '/' + input.slice(4, 8)
      
      setDisplayValue(formatted)
      
      if (formatted.length === 10) {
        const [day, month, year] = formatted.split('/')
        if (day && month && year) {
          const isoDate = `${year}-${month}-${day}`
          setInputValue(isoDate)
          onChange?.(isoDate)
        }
      } else if (formatted.length === 0) {
        setInputValue('')
        onChange?.('')
      }
    }

    const handleDateSelect = (date: Date) => {
      const year = date.getFullYear()
      const month = String(date.getMonth() + 1).padStart(2, '0')
      const day = String(date.getDate()).padStart(2, '0')
      const isoDate = `${year}-${month}-${day}`
      
      setDisplayValue(`${day}/${month}/${year}`)
      setInputValue(isoDate)
      onChange?.(isoDate)
      setIsOpen(false)
    }

    const renderCalendar = () => {
      const today = new Date()
      const firstDay = new Date(currentMonth.getFullYear(), currentMonth.getMonth(), 1)
      const startDate = new Date(firstDay)
      startDate.setDate(startDate.getDate() - firstDay.getDay())
      
      const days = []
      const currentDate = new Date(startDate)
      
      for (let i = 0; i < 42; i++) {
        const buttonDate = new Date(currentDate)
        const isCurrentMonth = buttonDate.getMonth() === currentMonth.getMonth()
        const isToday = buttonDate.toDateString() === today.toDateString()
        const isSelected = inputValue && buttonDate.toISOString().split('T')[0] === inputValue
        
        days.push(
          <button
            key={i}
            type="button"
            className={cn(
              'w-7 h-7 text-xs rounded-xl transition-colors',
              'hover:bg-accent hover:text-accent-foreground',
              isCurrentMonth ? 'text-popover-foreground' : 'text-muted-foreground',
              isToday && 'bg-accent text-accent-foreground font-semibold',
              isSelected && 'bg-foreground text-background font-semibold hover:bg-foreground/90'
            )}
            onClick={() => handleDateSelect(buttonDate)}
          >
            {buttonDate.getDate()}
          </button>
        )
        
        currentDate.setDate(currentDate.getDate() + 1)
      }
      
      return days
    }

    return (
      <div className="space-y-2" ref={containerRef}>
        {label && (
          <label
            htmlFor={dateId}
            className="text-sm font-medium text-foreground"
          >
            {label}
          </label>
        )}
        <div className="relative">
          <input
            type="text"
            id={dateId}
            placeholder="dd/mm/aaaa"
            value={displayValue}
            onChange={handleInputChange}
            className={cn(
              'flex h-10 w-full rounded-xl border border-border bg-background px-3 py-2 text-sm text-foreground',
              'focus:outline-none focus:ring-2 focus:ring-foreground focus:border-transparent',
              'disabled:cursor-not-allowed disabled:opacity-50',
              'transition-all duration-200',
              'hover:border-foreground/50',
              error && 'border-destructive focus:ring-destructive',
              className
            )}
            ref={ref}
            {...props}
          />
          <button
            type="button"
            onClick={() => setIsOpen(!isOpen)}
            className="absolute right-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground hover:text-foreground transition-colors"
          >
            <CalendarIcon className="h-4 w-4" />
          </button>
        </div>
        
        {isOpen && (
          <div className="absolute z-50 mt-1 w-64 rounded-xl border border-border bg-popover shadow-lg right-0">
            <div className="flex items-center justify-between border-b border-border p-2">
              <Button
                variant="ghost"
                size="sm"
                onClick={() => {
                  const newMonth = new Date(currentMonth.getFullYear(), currentMonth.getMonth() - 1, 1)
                  setCurrentMonth(newMonth)
                }}
                className="h-6 w-6 p-0 hover:bg-accent"
              >
                <ChevronLeftIcon className="h-3 w-3" />
              </Button>
              
              <span className="text-sm font-medium text-popover-foreground capitalize">
                {currentMonth.toLocaleDateString('pt-BR', { month: 'long', year: 'numeric' })}
              </span>
              
              <Button
                variant="ghost"
                size="sm"
                onClick={() => {
                  const newMonth = new Date(currentMonth.getFullYear(), currentMonth.getMonth() + 1, 1)
                  setCurrentMonth(newMonth)
                }}
                className="h-6 w-6 p-0 hover:bg-accent"
              >
                <ChevronRightIcon className="h-3 w-3" />
              </Button>
            </div>
            
            <div className="p-2">
              <div className="mb-1 grid grid-cols-7 gap-1">
                {['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'].map((day) => (
                  <div key={day} className="text-center text-xs font-medium text-muted-foreground">
                    {day}
                  </div>
                ))}
              </div>
              
              <div className="grid grid-cols-7 gap-1">
                {renderCalendar()}
              </div>
            </div>
          </div>
        )}
        
        {error && (
          <p className="text-sm text-destructive">{error}</p>
        )}
      </div>
    )
  }
)

DatePicker.displayName = 'DatePicker'

export { DatePicker }

