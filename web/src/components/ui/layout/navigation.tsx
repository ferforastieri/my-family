import { forwardRef, Fragment, useState } from 'react'
import { Dialog, Transition } from '@headlessui/react'
import { XMarkIcon, Bars3Icon } from '@heroicons/react/24/outline'
import { cn } from '../../lib'

export interface NavigationItem {
  name: string
  href: string
  icon?: React.ElementType
  hasDropdown?: boolean
  dropdownContent?: React.ReactNode
}

export interface NavigationProps extends React.HTMLAttributes<HTMLElement> {
  items: NavigationItem[]
  logo?: React.ReactNode
  rightContent?: React.ReactNode
  currentPath?: string
  LinkComponent?: React.ComponentType<{ to: string; className?: string; children: React.ReactNode; onClick?: () => void }>
  mobileMenuOpen?: boolean
  setMobileMenuOpen?: (open: boolean) => void
  showMobileMenu?: boolean
  onTouchStart?: (e: React.TouchEvent) => void
  onTouchMove?: (e: React.TouchEvent) => void
  onTouchEnd?: () => void
}

const Navigation = forwardRef<HTMLElement, NavigationProps>(
  ({ 
    className, 
    items, 
    logo, 
    rightContent, 
    currentPath, 
    LinkComponent, 
    mobileMenuOpen = false,
    setMobileMenuOpen,
    showMobileMenu = true,
    onTouchStart,
    onTouchMove,
    onTouchEnd,
    ...props 
  }, ref) => {
    const [internalMobileMenuOpen, setInternalMobileMenuOpen] = useState(false)
    const isMobileMenuControlled = setMobileMenuOpen !== undefined
    const mobileOpen = isMobileMenuControlled ? mobileMenuOpen : internalMobileMenuOpen
    const setMobileOpen = isMobileMenuControlled ? setMobileMenuOpen! : setInternalMobileMenuOpen
    
    const Link = LinkComponent || 'a'
    
    const renderNavItem = (item: NavigationItem, isMobile = false) => {
      const isActive = currentPath === item.href || (item.href !== '/' && currentPath?.startsWith(item.href))
      const Icon = item.icon
      
      const baseClasses = cn(
        'flex items-center gap-3 px-4 py-3 rounded-xl transition-all duration-200',
        isActive
          ? 'text-foreground bg-accent shadow-sm'
          : 'text-muted-foreground hover:text-foreground hover:bg-accent/50'
      )
      
      const iconClasses = cn(
        'h-5 w-5 flex-shrink-0',
        isActive ? 'text-foreground' : 'text-muted-foreground'
      )
      
      if (item.hasDropdown && item.dropdownContent) {
        return (
          <div key={item.href} className="relative">
            {item.dropdownContent}
          </div>
        )
      }
      
      if (LinkComponent) {
        return (
          <LinkComponent
            key={item.href}
            to={item.href}
            onClick={() => isMobile && setMobileOpen(false)}
            className={baseClasses}
          >
            {Icon && <Icon className={iconClasses} />}
            <span className={cn('text-sm font-medium', isMobile ? '' : 'hidden md:inline')}>{item.name}</span>
            {isActive && (
              <div className="ml-auto w-1.5 h-1.5 rounded-full bg-foreground" />
            )}
          </LinkComponent>
        )
      }
      
      return (
        <a
          key={item.href}
          href={item.href}
          className={baseClasses}
        >
          {Icon && <Icon className={iconClasses} />}
          <span className={cn('text-sm font-medium', isMobile ? '' : 'hidden md:inline')}>{item.name}</span>
          {isActive && (
            <div className="ml-auto w-1.5 h-1.5 rounded-full bg-foreground" />
          )}
        </a>
      )
    }
    
    return (
      <>
        <nav
          ref={ref}
          className={cn(
            'sticky top-0 z-50 w-full border-b border-border bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60',
            className
          )}
          {...props}
        >
          <div className="flex h-14 items-center justify-between px-4 md:px-6">
            <div className="flex items-center gap-6 md:gap-8">
              {showMobileMenu && (
                <button
                  type="button"
                  className="md:hidden flex items-center justify-center w-9 h-9 rounded-md hover:bg-muted transition-colors"
                  onClick={() => setMobileOpen(true)}
                  aria-label="Open navigation menu"
                >
                  <Bars3Icon className="h-5 w-5 text-foreground" />
                </button>
              )}
              {logo && <div className="flex items-center">{logo}</div>}
              <div className="hidden md:flex items-center gap-2">
                {items.map((item) => renderNavItem(item, false))}
              </div>
            </div>
            {rightContent && (
              <div className="flex items-center">
                {rightContent}
              </div>
            )}
          </div>
        </nav>

        {showMobileMenu && (
          <Transition.Root show={mobileOpen} as={Fragment}>
            <Dialog as="div" className="relative z-50 md:hidden" onClose={setMobileOpen}>
              <Transition.Child
                as={Fragment}
                enter="transition-opacity ease-linear duration-300"
                enterFrom="opacity-0"
                enterTo="opacity-100"
                leave="transition-opacity ease-linear duration-300"
                leaveFrom="opacity-100"
                leaveTo="opacity-0"
              >
                <div className="fixed inset-0 bg-background/80 backdrop-blur-sm" />
              </Transition.Child>

              <div className="fixed inset-0 z-50 flex items-start justify-center pt-16">
                <Transition.Child
                  as={Fragment}
                  enter="transition ease-out duration-300 transform"
                  enterFrom="-translate-y-full opacity-0"
                  enterTo="translate-y-0 opacity-100"
                  leave="transition ease-in duration-200 transform"
                  leaveFrom="translate-y-0 opacity-100"
                  leaveTo="-translate-y-full opacity-0"
                >
                  <Dialog.Panel 
                    className="relative w-full max-w-md mx-4 bg-background border border-border rounded-2xl shadow-2xl overflow-hidden"
                    onTouchStart={onTouchStart}
                    onTouchMove={onTouchMove}
                    onTouchEnd={onTouchEnd}
                  >
                    <div className="flex items-center justify-center pt-3 pb-2 cursor-grab active:cursor-grabbing">
                      <div className="w-12 h-1.5 bg-muted-foreground/30 rounded-full" />
                    </div>

                    <div className="flex items-center justify-between px-6 pb-4 border-b border-border">
                      <div className="flex items-center gap-3">
                        {logo}
                      </div>
                      <button
                        type="button"
                        className="flex items-center justify-center w-9 h-9 rounded-lg hover:bg-muted transition-colors"
                        onClick={() => setMobileOpen(false)}
                        aria-label="Close navigation menu"
                      >
                        <XMarkIcon className="h-5 w-5 text-foreground" />
                      </button>
                    </div>

                    <nav className="px-4 py-4">
                      <div className="space-y-1">
                        {items.map((item) => renderNavItem(item, true))}
                      </div>
                    </nav>
                  </Dialog.Panel>
                </Transition.Child>
              </div>
            </Dialog>
          </Transition.Root>
        )}
      </>
    )
  }
)

Navigation.displayName = 'Navigation'

export { Navigation }
