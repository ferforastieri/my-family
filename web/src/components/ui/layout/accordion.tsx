import { forwardRef, useState, ReactNode } from 'react'
import { ChevronDownIcon } from '@heroicons/react/24/outline'
import { cn } from '../../lib'

export interface AccordionItemProps {
  value: string
  trigger: ReactNode
  content: ReactNode
  defaultOpen?: boolean
}

export interface AccordionProps extends React.HTMLAttributes<HTMLDivElement> {
  items: AccordionItemProps[]
  type?: 'single' | 'multiple'
  defaultValue?: string | string[]
}

const Accordion = forwardRef<HTMLDivElement, AccordionProps>(
  ({ className, items, type = 'single', defaultValue, ...props }, ref) => {
    const [openItems, setOpenItems] = useState<string[]>(() => {
      if (defaultValue) {
        return Array.isArray(defaultValue) ? defaultValue : [defaultValue]
      }
      return items.filter(item => item.defaultOpen).map(item => item.value)
    })

    const toggleItem = (value: string) => {
      setOpenItems(prev => {
        if (type === 'single') {
          return prev.includes(value) ? [] : [value]
        }
        return prev.includes(value)
          ? prev.filter(item => item !== value)
          : [...prev, value]
      })
    }

    return (
      <div ref={ref} className={cn('space-y-2', className)} {...props}>
        {items.map((item) => {
          const isOpen = openItems.includes(item.value)
          return (
            <div
              key={item.value}
              className="rounded-xl border border-border bg-popover overflow-hidden shadow-sm transition-all duration-200"
            >
              <button
                type="button"
                onClick={() => toggleItem(item.value)}
                className="w-full flex items-center justify-between p-4 text-left hover:bg-accent transition-colors"
                aria-expanded={isOpen}
              >
                <span className="font-medium text-popover-foreground">
                  {item.trigger}
                </span>
                <ChevronDownIcon
                  className={cn(
                    'h-5 w-5 text-muted-foreground transition-transform duration-200',
                    isOpen && 'transform rotate-180'
                  )}
                />
              </button>
              {isOpen && (
                <div className="px-4 pb-4 pt-0 text-sm text-popover-foreground">
                  {item.content}
                </div>
              )}
            </div>
          )
        })}
      </div>
    )
  }
)

Accordion.displayName = 'Accordion'

export { Accordion }

