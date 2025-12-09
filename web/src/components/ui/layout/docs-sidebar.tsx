import { forwardRef } from 'react'
import { cn } from '../../lib'

export interface DocsSidebarItem {
  title: string
  href: string
  items?: DocsSidebarItem[]
}

export interface DocsSidebarSection {
  title?: string
  items: DocsSidebarItem[]
}

export interface DocsSidebarProps extends React.HTMLAttributes<HTMLElement> {
  sections: DocsSidebarSection[]
  currentPath?: string
  LinkComponent?: React.ComponentType<{ to?: string; href?: string; className?: string; children: React.ReactNode; onClick?: (e: React.MouseEvent) => void }>
}

const DocsSidebar = forwardRef<HTMLElement, DocsSidebarProps>(
  ({ className, sections, currentPath, LinkComponent, ...props }, ref) => {
    const renderItem = (item: DocsSidebarItem, level: number = 0) => {
      const isActive = currentPath === item.href || currentPath?.startsWith(item.href + '/')
      const hasChildren = item.items && item.items.length > 0

      const linkProps = LinkComponent 
        ? { to: item.href as string }
        : { href: item.href }

      return (
        <li key={item.href} className={cn(level > 0 && 'ml-4')}>
          {LinkComponent ? (
            <LinkComponent
              {...linkProps}
              className={cn(
                'block px-3 py-2 text-sm transition-colors rounded-md cursor-pointer relative',
                level === 0 ? 'font-medium' : 'font-normal',
                isActive
                  ? 'text-foreground bg-accent'
                  : 'text-muted-foreground hover:text-foreground hover:bg-accent/50'
              )}
            >
              {item.title}
              {isActive && (
                <div className="absolute left-0 top-1/2 -translate-y-1/2 w-1 h-5 bg-foreground rounded-r-full" />
              )}
            </LinkComponent>
          ) : (
            <a
              {...linkProps}
              className={cn(
                'block px-3 py-2 text-sm transition-colors rounded-md cursor-pointer relative',
                level === 0 ? 'font-medium' : 'font-normal',
                isActive
                  ? 'text-foreground bg-accent'
                  : 'text-muted-foreground hover:text-foreground hover:bg-accent/50'
              )}
            >
              {item.title}
              {isActive && (
                <div className="absolute left-0 top-1/2 -translate-y-1/2 w-1 h-5 bg-foreground rounded-r-full" />
              )}
            </a>
          )}
          {hasChildren && (
            <ul className="mt-1 space-y-0.5 ml-2 border-l border-border pl-2">
              {item.items?.map((child) => renderItem(child, level + 1))}
            </ul>
          )}
        </li>
      )
    }

    return (
      <aside
        ref={ref}
        className={cn(
          'hidden lg:flex flex-col w-64 border-r border-border bg-background shrink-0',
          className
        )}
        {...props}
      >
        <nav className="flex-1 overflow-y-auto">
          <div className="px-4 py-4">
            {sections.map((section, sectionIndex) => (
              <div key={sectionIndex} className={cn(sectionIndex > 0 && 'mt-8')}>
                {section.title && (
                  <div className="px-3 py-2 mb-2">
                    <h2 className="text-xs font-semibold text-muted-foreground uppercase tracking-wider">
                      {section.title}
                    </h2>
                  </div>
                )}
                <ul className="space-y-1">
                  {section.items.map((item) => renderItem(item))}
                </ul>
                {sectionIndex < sections.length - 1 && section.title && (
                  <div className="mt-4 border-t border-border" />
                )}
              </div>
            ))}
          </div>
        </nav>
      </aside>
    )
  }
)

DocsSidebar.displayName = 'DocsSidebar'

export { DocsSidebar }

