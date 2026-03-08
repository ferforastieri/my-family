import { createContext, useContext, useEffect, useState, ReactNode } from 'react';

const THEME_KEY = 'lovepage_theme';

export type ThemeColor = 'rosa' | 'azul' | 'vermelho';
export type ThemeMode = 'light' | 'dark';

interface ThemeState {
  color: ThemeColor;
  mode: ThemeMode;
}

interface ThemeContextType extends ThemeState {
  setColor: (color: ThemeColor) => void;
  setMode: (mode: ThemeMode) => void;
}

const defaultTheme: ThemeState = { color: 'rosa', mode: 'light' };

function loadTheme(): ThemeState {
  try {
    const raw = localStorage.getItem(THEME_KEY);
    if (!raw) return defaultTheme;
    const parsed = JSON.parse(raw) as ThemeState;
    if (['rosa', 'azul', 'vermelho'].includes(parsed.color) && ['light', 'dark'].includes(parsed.mode)) {
      return parsed;
    }
  } catch {
    return defaultTheme;
  }
  return defaultTheme;
}

function saveTheme(theme: ThemeState) {
  try {
    localStorage.setItem(THEME_KEY, JSON.stringify(theme));
  } catch {
  }
}

const ThemeContext = createContext<ThemeContextType | undefined>(undefined);

export function ThemeProvider({ children }: { children: ReactNode }) {
  const [theme, setTheme] = useState<ThemeState>(() => loadTheme());

  useEffect(() => {
    saveTheme(theme);
    document.documentElement.setAttribute('data-color', theme.color);
    document.documentElement.classList.toggle('dark', theme.mode === 'dark');
  }, [theme]);

  const setColor = (color: ThemeColor) => setTheme((t) => ({ ...t, color }));
  const setMode = (mode: ThemeMode) => setTheme((t) => ({ ...t, mode }));

  return (
    <ThemeContext.Provider value={{ ...theme, setColor, setMode }}>
      {children}
    </ThemeContext.Provider>
  );
}

export function useTheme() {
  const ctx = useContext(ThemeContext);
  if (!ctx) throw new Error('useTheme must be used within ThemeProvider');
  return ctx;
}
