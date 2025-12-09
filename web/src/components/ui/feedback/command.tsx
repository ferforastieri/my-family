import { useState, useEffect, useRef, forwardRef } from 'react'
import { cn } from '../../lib'
import { MagnifyingGlassIcon } from '@heroicons/react/24/outline'

export interface CommandItem {
  id: string
  title: string
  description?: string
  icon?: React.ReactNode
  keywords?: string[]
  onSelect?: () => void
}

export interface CommandProps extends Omit<React.HTMLAttributes<HTMLDivElement>, 'onSelect'> {
  items: CommandItem[]
  placeholder?: string
  onSelect?: (item: CommandItem) => void
  emptyMessage?: string
}

const Command = forwardRef<HTMLDivElement, CommandProps>(
  ({ className, items, placeholder = 'Search...', onSelect, emptyMessage = 'No results found.', ...props }, ref) => {
    const [search, setSearch] = useState('')
    const [selectedIndex, setSelectedIndex] = useState(0)
    const inputRef = useRef<HTMLInputElement>(null)
    const listRef = useRef<HTMLDivElement>(null)

    const filteredItems = items.filter((item) => {
      if (!search) return true
      const searchLower = search.toLowerCase()
      return (
        item.title.toLowerCase().includes(searchLower) ||
        item.description?.toLowerCase().includes(searchLower) ||
        item.keywords?.some((keyword) => keyword.toLowerCase().includes(searchLower))
      )
    })

    useEffect(() => {
      if (filteredItems.length > 0 && selectedIndex >= filteredItems.length) {
        setSelectedIndex(0)
      }
    }, [filteredItems.length, selectedIndex])

    useEffect(() => {
      if (listRef.current) {
        const selectedElement = listRef.current.children[selectedIndex] as HTMLElement
        if (selectedElement) {
          selectedElement.scrollIntoView({ block: 'nearest' })
        }
      }
    }, [selectedIndex])

    const handleKeyDown = (e: React.KeyboardEvent) => {
      if (e.key === 'ArrowDown') {
        e.preventDefault()
        setSelectedIndex((prev) => (prev < filteredItems.length - 1 ? prev + 1 : 0))
      } else if (e.key === 'ArrowUp') {
        e.preventDefault()
        setSelectedIndex((prev) => (prev > 0 ? prev - 1 : filteredItems.length - 1))
      } else if (e.key === 'Enter' && filteredItems[selectedIndex]) {
        e.preventDefault()
        handleSelect(filteredItems[selectedIndex])
      } else if (e.key === 'Escape') {
        setSearch('')
        setSelectedIndex(0)
      }
    }

    const handleSelect = (item: CommandItem) => {
      item.onSelect?.()
      onSelect?.(item)
      setSearch('')
      setSelectedIndex(0)
    }

    return (
      <div
        ref={ref}
        className={cn(
          'flex h-full w-full flex-col overflow-hidden rounded-md border bg-popover text-popover-foreground',
          className
        )}
        {...props}
      >
        <div className="flex items-center border-b px-3">
          <MagnifyingGlassIcon className="mr-2 h-4 w-4 shrink-0 opacity-50" />
          <input
            ref={inputRef}
            type="text"
            value={search}
            onChange={(e) => {
              setSearch(e.target.value)
              setSelectedIndex(0)
            }}
            onKeyDown={handleKeyDown}
            placeholder={placeholder}
            className="flex h-11 w-full rounded-md bg-transparent py-3 text-sm outline-none placeholder:text-muted-foreground disabled:cursor-not-allowed disabled:opacity-50"
          />
        </div>
        <div
          ref={listRef}
          className="max-h-[300px] overflow-y-auto overflow-x-hidden p-1"
        >
          {filteredItems.length === 0 ? (
            <div className="py-6 text-center text-sm text-muted-foreground">
              {emptyMessage}
            </div>
          ) : (
            filteredItems.map((item, index) => (
              <div
                key={item.id}
                onClick={() => handleSelect(item)}
                className={cn(
                  'relative flex cursor-pointer select-none items-center rounded-sm px-2 py-1.5 text-sm outline-none transition-colors',
                  index === selectedIndex
                    ? 'bg-accent text-accent-foreground'
                    : 'hover:bg-accent hover:text-accent-foreground'
                )}
              >
                {item.icon && <span className="mr-2">{item.icon}</span>}
                <div className="flex flex-col">
                  <span>{item.title}</span>
                  {item.description && (
                    <span className="text-xs text-muted-foreground">{item.description}</span>
                  )}
                </div>
              </div>
            ))
          )}
        </div>
      </div>
    )
  }
)

Command.displayName = 'Command'

export { Command }

