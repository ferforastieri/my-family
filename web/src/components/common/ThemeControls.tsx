import { useTheme } from '../../contexts/ThemeContext';
import type { ThemeColor } from '../../contexts/ThemeContext';
import { ThemeToggle } from '../ui/feedback/theme-toggle';
import { cn } from '../lib';

const colors: { value: ThemeColor; label: string; bg: string }[] = [
  { value: 'rosa', label: 'Rosa', bg: 'bg-pink-500' },
  { value: 'azul', label: 'Azul', bg: 'bg-blue-500' },
  { value: 'vermelho', label: 'Vermelho', bg: 'bg-red-500' },
];

export default function ThemeControls() {
  const { color, mode, setColor, setMode } = useTheme();

  return (
    <div className="flex items-center gap-2 sm:gap-3">
      <div className="flex items-center gap-1" role="group" aria-label="Cor do tema">
        {colors.map((c) => (
          <button
            key={c.value}
            type="button"
            onClick={() => setColor(c.value)}
            title={c.label}
            className={cn(
              'w-8 h-8 sm:w-9 sm:h-9 rounded-full border-2 transition-all',
              c.bg,
              color === c.value
                ? 'border-foreground scale-110 ring-2 ring-offset-2 ring-offset-background ring-foreground/30'
                : 'border-transparent opacity-70 hover:opacity-100'
            )}
            aria-pressed={color === c.value}
            aria-label={`Cor ${c.label}`}
          />
        ))}
      </div>
      <ThemeToggle
        theme={mode}
        onToggle={() => setMode(mode === 'dark' ? 'light' : 'dark')}
        size="sm"
        variant="ghost"
        className="shrink-0"
      />
    </div>
  );
}
