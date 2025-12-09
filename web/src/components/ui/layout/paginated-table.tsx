import { forwardRef, useState, useEffect, useRef } from 'react'
import { cn } from '../../lib'
import { ChevronLeftIcon, ChevronRightIcon, MagnifyingGlassIcon, ArrowDownTrayIcon, XMarkIcon, ChevronUpIcon, ChevronDownIcon } from '@heroicons/react/24/outline'

export interface Column<T extends Record<string, string | number | boolean | null | undefined> = Record<string, string | number | boolean | null | undefined>> {
  key: string
  title: string
  dataIndex?: keyof T
  render?: (value: string | number | boolean | null | undefined, record: T, index: number) => React.ReactNode
  width?: string | number
  align?: 'left' | 'center' | 'right'
  sortable?: boolean
}

export interface PaginatedTableProps<T extends Record<string, string | number | boolean | null | undefined> = Record<string, string | number | boolean | null | undefined>>
  extends React.HTMLAttributes<HTMLDivElement> {
  columns: Column<T>[]
  data: T[]
  loading?: boolean
  emptyText?: string
  onRowClick?: (record: T, index: number) => void
  rowKey?: keyof T | ((record: T) => string | number)
  pageSize?: number
  totalItems?: number
  currentPage?: number
  onPageChange?: (page: number) => void
  onPageSizeChange?: (pageSize: number) => void
  searchable?: boolean
  searchPlaceholder?: string
  searchTerm?: string
  onSearch?: (searchTerm: string) => void
  onDownload?: () => void
  downloadFileName?: string
  isDownloading?: boolean
  currentSort?: { sortBy: string; sortOrder: 'asc' | 'desc' }
  onSortChange?: (sortBy: string, sortOrder: 'asc' | 'desc') => void
}

const PaginatedTable = forwardRef<HTMLDivElement, PaginatedTableProps>(
  ({ 
    className, 
    columns, 
    data, 
    loading = false, 
    emptyText = 'Nenhum dado encontrado',
    onRowClick,
    rowKey = 'id',
    pageSize = 10,
    totalItems = 0,
    currentPage = 1,
    onPageChange,
    onPageSizeChange,
    searchable = true,
    searchPlaceholder = 'Pesquisar...',
    searchTerm: externalSearchTerm,
    onSearch,
    onDownload,
    downloadFileName = 'dados',
    isDownloading = false,
    currentSort,
    onSortChange,
    ...props 
  }, ref) => {
    const [internalSearchTerm, setInternalSearchTerm] = useState(externalSearchTerm || '')
    const [debouncedSearchTerm, setDebouncedSearchTerm] = useState('')
    const lastSearchTerm = useRef('')

    useEffect(() => {
      setInternalSearchTerm(externalSearchTerm || '')
    }, [externalSearchTerm])

    useEffect(() => {
      const timer = setTimeout(() => {
        setDebouncedSearchTerm(internalSearchTerm)
      }, 300)

      return () => clearTimeout(timer)
    }, [internalSearchTerm])

    useEffect(() => {
      if (onSearch && debouncedSearchTerm !== lastSearchTerm.current) {
        lastSearchTerm.current = debouncedSearchTerm
        onSearch(debouncedSearchTerm)
      }
    }, [debouncedSearchTerm, onSearch])

    const handleDownload = () => {
      if (onDownload) {
        onDownload()
      }
    }
    const getRowKey = (record: Record<string, string | number | boolean | null | undefined>, index: number): string | number => {
      if (typeof rowKey === 'function') {
        return rowKey(record as never)
      }
      const r = record as Record<string, string | number>
      return (r[rowKey as string] as string | number | undefined) ?? index
    }

    const getValue = (record: Record<string, string | number | boolean | null | undefined>, column: Column): React.ReactNode => {
      const r = record as Record<string, string | number | boolean | null | undefined>
      const dataKey = (column.dataIndex as string | undefined) ?? column.key
      if (column.render) {
        return column.render(r[dataKey], record, data.indexOf(record))
      }
      return r[dataKey] as React.ReactNode
    }

    const totalPages = Math.ceil(totalItems / pageSize)
    const startItem = (currentPage - 1) * pageSize + 1
    const endItem = Math.min(currentPage * pageSize, totalItems)

    const showEmptyState = !loading && data.length === 0

    const isColumnSortable = (column: Column) => {
      return column.sortable !== false
    }

    const getNextSort = (key: string): { sortBy: string; sortOrder: 'asc' | 'desc' } => {
      if (currentSort && currentSort.sortBy === key) {
        return { sortBy: key, sortOrder: currentSort.sortOrder === 'asc' ? 'desc' : 'asc' }
      }
      return { sortBy: key, sortOrder: 'asc' }
    }

    return (
      <div
        ref={ref}
        className={cn(
          'overflow-hidden rounded-xl border border-border bg-popover relative',
          className
        )}
        {...props}
      >
        {searchable && (
          <div className="flex items-center justify-between p-4 border-b border-border">
            <div className="flex-1 max-w-md">
              <div className="relative">
                <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                  {loading ? (
                    <svg className="animate-spin h-5 w-5 text-muted-foreground" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                      <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                      <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                    </svg>
                  ) : (
                    <MagnifyingGlassIcon className="h-5 w-5 text-muted-foreground" />
                  )}
                </div>
                <input
                  type="text"
                  placeholder={searchPlaceholder}
                  value={internalSearchTerm}
                  onChange={(e) => setInternalSearchTerm(e.target.value)}
                  className="block w-full pl-10 pr-10 py-2 border border-border rounded-xl leading-5 bg-background placeholder-muted-foreground focus:outline-none focus:placeholder-muted-foreground focus:ring-2 focus:ring-foreground focus:border-transparent text-sm text-foreground transition-all duration-200"
                />
                {internalSearchTerm && !loading && (
                  <button
                    type="button"
                    onClick={() => setInternalSearchTerm('')}
                    className="absolute inset-y-0 right-0 pr-3 flex items-center text-muted-foreground hover:text-foreground transition-colors"
                  >
                    <XMarkIcon className="h-5 w-5" />
                  </button>
                )}
              </div>
            </div>
            
            {loading ? (
              <div className="ml-4 h-10 w-32 bg-muted rounded-xl animate-pulse" />
            ) : (
              onDownload && (
                <button
                  onClick={handleDownload}
                  disabled={isDownloading}
                  className="ml-4 inline-flex items-center px-4 py-2 border border-border rounded-xl shadow-sm text-sm font-medium text-foreground bg-background hover:bg-accent hover:text-accent-foreground focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-foreground disabled:opacity-50 disabled:cursor-not-allowed transition-all duration-200"
                >
                  {isDownloading ? (
                    <>
                      <svg className="animate-spin -ml-1 mr-2 h-4 w-4 text-muted-foreground" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                        <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                        <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                      </svg>
                      Baixando...
                    </>
                  ) : (
                    <>
                      <ArrowDownTrayIcon className="h-4 w-4 mr-2" />
                      Download
                    </>
                  )}
                </button>
              )
            )}
          </div>
        )}

        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="border-b bg-foreground">
              <tr>
                {columns.map((column) => {
                  const sortable = isColumnSortable(column)
                  const isActive = currentSort?.sortBy === (column.dataIndex || column.key)
                  const sortOrder = isActive ? currentSort?.sortOrder : undefined
                  return (
                    <th
                      key={column.key}
                      className={cn(
                        'px-6 py-3 text-left text-xs font-medium text-background select-none',
                        column.align === 'center' && 'text-center',
                        column.align === 'right' && 'text-right',
                        sortable && 'cursor-pointer hover:bg-foreground/90'
                      )}
                      style={{ width: column.width }}
                      onClick={() => {
                        if (!sortable) return
                        const key = String(column.dataIndex || column.key)
                        const next = getNextSort(key)
                        onSortChange?.(next.sortBy, next.sortOrder)
                      }}
                    >
                      <span className="inline-flex items-center gap-1.5">
                        {column.title}
                        {sortable && (
                          <span className="inline-flex flex-col ml-0.5">
                            {isActive ? (
                              sortOrder === 'asc' ? (
                                <ChevronUpIcon className="h-4 w-4 text-background transition-all" />
                              ) : (
                                <ChevronDownIcon className="h-4 w-4 text-background transition-all" />
                              )
                            ) : (
                              <div className="flex flex-col -space-y-1 opacity-50 hover:opacity-75 transition-opacity">
                                <ChevronUpIcon className="h-3 w-3 text-background" />
                                <ChevronDownIcon className="h-3 w-3 text-background" />
                              </div>
                            )}
                          </span>
                        )}
                      </span>
                    </th>
                  )
                })}
              </tr>
            </thead>
            <tbody className="divide-y divide-border">
              {loading ? (
                Array.from({ length: pageSize }).map((_, rowIndex) => (
                  <tr key={`skeleton-${rowIndex}`}>
                    {columns.map((column) => (
                      <td key={column.key} className="px-6 py-4">
                        <div className="h-4 bg-muted rounded animate-pulse" />
                      </td>
                    ))}
                  </tr>
                ))
              ) : showEmptyState ? (
                <tr>
                  <td colSpan={columns.length} className="px-6 py-8 text-center">
                    <p className="text-sm text-muted-foreground">
                      {emptyText}
                    </p>
                  </td>
                </tr>
              ) : (
                data.map((record, index) => (
                  <tr
                    key={getRowKey(record, index)}
                    className={cn(
                      "hover:bg-accent",
                      onRowClick && "cursor-pointer"
                    )}
                    onClick={() => onRowClick?.(record, index)}
                  >
                    {columns.map((column) => (
                      <td
                        key={column.key}
                        className={cn(
                          'px-6 py-4 text-sm text-foreground',
                          column.align === 'center' && 'text-center',
                          column.align === 'right' && 'text-right'
                        )}
                      >
                        {getValue(record, column)}
                      </td>
                    ))}
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>

        <div className="flex items-center justify-between px-6 py-4 border-t border-border">
          {loading ? (
            <div className="flex items-center justify-between w-full">
              <div className="flex items-center space-x-4">
                <div className="h-8 w-40 bg-muted rounded animate-pulse" />
                <div className="h-4 w-48 bg-muted rounded animate-pulse" />
              </div>
              <div className="flex items-center space-x-2">
                <div className="h-9 w-9 bg-muted rounded animate-pulse" />
                <div className="h-9 w-9 bg-muted rounded animate-pulse" />
                <div className="h-9 w-9 bg-muted rounded animate-pulse" />
                <div className="h-9 w-9 bg-muted rounded animate-pulse" />
              </div>
            </div>
          ) : (
            <>
              <div className="flex items-center space-x-4">
                <div className="flex items-center space-x-2">
                  <span className="text-sm text-foreground">Mostrar</span>
                  <select
                    value={pageSize}
                    onChange={(e) => onPageSizeChange?.(Number(e.target.value))}
                    className="rounded-xl border border-border bg-background px-2 py-1 text-sm text-foreground transition-all duration-200"
                  >
                    <option value={10}>10 por página</option>
                    <option value={25}>25 por página</option>
                    <option value={50}>50 por página</option>
                    <option value={100}>100 por página</option>
                  </select>
                </div>
                <span className="text-sm text-foreground">
                  {startItem}-{endItem}, de {totalItems} registros
                </span>
              </div>

              <div className="flex items-center space-x-2">
                <button
                  onClick={() => onPageChange?.(currentPage - 1)}
                  disabled={currentPage <= 1}
                  className="p-2 rounded-xl border border-border bg-background text-muted-foreground hover:bg-accent hover:text-accent-foreground disabled:opacity-50 disabled:cursor-not-allowed transition-all duration-200"
                >
                  <ChevronLeftIcon className="h-4 w-4" />
                </button>
                
                {(() => {
                  const maxVisiblePages = 5
                  const halfVisible = Math.floor(maxVisiblePages / 2)
                  
                  let startPage = Math.max(1, currentPage - halfVisible)
                  let endPage = Math.min(totalPages, startPage + maxVisiblePages - 1)
                  
                  if (endPage - startPage + 1 < maxVisiblePages) {
                    startPage = Math.max(1, endPage - maxVisiblePages + 1)
                  }
                  
                  const pages = []
                  
                  if (startPage > 1) {
                    pages.push(
                      <button
                        key={1}
                        onClick={() => onPageChange?.(1)}
                        className="px-3 py-2 text-sm rounded-xl border border-border bg-background text-foreground hover:bg-accent hover:text-accent-foreground transition-all duration-200"
                      >
                        1
                      </button>
                    )
                    if (startPage > 2) {
                      pages.push(
                        <span key="ellipsis-start" className="px-2 py-2 text-sm text-muted-foreground">
                          ...
                        </span>
                      )
                    }
                  }
                  
                  for (let i = startPage; i <= endPage; i++) {
                    pages.push(
                      <button
                        key={i}
                        onClick={() => onPageChange?.(i)}
                        className={cn(
                          'px-3 py-2 text-sm rounded-md border',
                          i === currentPage
                            ? 'border-foreground bg-foreground text-background'
                            : 'border-border bg-background text-foreground hover:bg-accent hover:text-accent-foreground'
                        )}
                      >
                        {i}
                      </button>
                    )
                  }
                  
                  if (endPage < totalPages) {
                    if (endPage < totalPages - 1) {
                      pages.push(
                        <span key="ellipsis-end" className="px-2 py-2 text-sm text-muted-foreground">
                          ...
                        </span>
                      )
                    }
                    pages.push(
                      <button
                        key={totalPages}
                        onClick={() => onPageChange?.(totalPages)}
                        className="px-3 py-2 text-sm rounded-xl border border-border bg-background text-foreground hover:bg-accent hover:text-accent-foreground transition-all duration-200"
                      >
                        {totalPages}
                      </button>
                    )
                  }
                  
                  return pages
                })()}
                
                <button
                  onClick={() => onPageChange?.(currentPage + 1)}
                  disabled={currentPage >= totalPages}
                  className="p-2 rounded-xl border border-border bg-background text-muted-foreground hover:bg-accent hover:text-accent-foreground disabled:opacity-50 disabled:cursor-not-allowed transition-all duration-200"
                >
                  <ChevronRightIcon className="h-4 w-4" />
                </button>
              </div>
            </>
          )}
        </div>
      </div>
    )
  }
)

PaginatedTable.displayName = 'PaginatedTable'

export { PaginatedTable }

