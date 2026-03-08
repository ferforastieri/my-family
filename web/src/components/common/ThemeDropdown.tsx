import { useTheme } from '../../contexts/ThemeContext';
import type { ThemeColor } from '../../contexts/ThemeContext';
import { DropdownMenu, DropdownMenuItem } from '../ui/feedback';
import { SwatchIcon, SunIcon, MoonIcon } from '@heroicons/react/24/outline';
import { cn } from '../lib';

const colors: { value: ThemeColor; label: string; bg: string }[] = [
  { value: 'rosa', label: 'Rosa', bg: 'bg-pink-500' },
  { value: 'azul', label: 'Azul', bg: 'bg-blue-500' },
  { value: 'vermelho', label: 'Vermelho', bg: 'bg-red-500' },
];

export default function ThemeDropdown() {
  const { color, mode, setColor, setMode } = useTheme();

  return (
    <DropdownMenu
      align="right"
      side="bottom"
      trigger={
        <button
          type="button"
          className="flex items-center justify-center w-9 h-9 rounded-full bg-muted hover:bg-accent text-foreground transition-colors border border-border"
          aria-label="Cor e tema"
        >
          <SwatchIcon className="h-5 w-5" />
        </button>
      }
    >
      <div className="p-2 border-b border-border">
        <p className="text-xs font-medium text-muted-foreground px-2 pb-1">Cor</p>
        <div className="flex gap-1">
          {colors.map((c) => (
            <button
              key={c.value}
              type="button"
              onClick={() => setColor(c.value)}
              title={c.label}
              className={cn(
                'w-8 h-8 rounded-full border-2 transition-all',
                c.bg,
                color === c.value ? 'border-foreground scale-110 ring-2 ring-offset-2 ring-offset-background ring-foreground/30' : 'border-transparent opacity-70 hover:opacity-100'
              )}
              aria-label={c.label}
            />
          ))}
        </div>
      </div>
      <div className="p-2">
        <p className="text-xs font-medium text-muted-foreground px-2 pb-1">Tema</p>
        <DropdownMenuItem
          onClick={() => setMode('light')}
          className={cn('flex items-center gap-2', mode === 'light' && 'bg-accent')}
        >
          <SunIcon className="h-4 w-4" />
          Claro
        </DropdownMenuItem>
        <DropdownMenuItem
          onClick={() => setMode('dark')}
          className={cn('flex items-center gap-2', mode === 'dark' && 'bg-accent')}
        >
          <MoonIcon className="h-4 w-4" />
          Escuro
        </DropdownMenuItem>
      </div>
    </DropdownMenu>
  );
}
