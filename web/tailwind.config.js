/** @type {import('tailwindcss').Config} */
export default {
  darkMode: ['class'],
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
    "./src/components/ui/**/*.{js,ts,jsx,tsx}",
  ],
  prefix: '',
  theme: {
    keyframes: {
      float: {
        '0%, 100%': { transform: 'translateY(0)' },
        '50%': { transform: 'translateY(-10px)' },
      },
      glow: {
        '0%, 100%': { textShadow: '2px 2px 4px rgba(255, 105, 180, 0.3)' },
        '50%': { textShadow: '2px 2px 12px rgba(255, 105, 180, 0.6)' },
      },
      'title-glow': {
        from: { filter: 'drop-shadow(0 0 2px rgba(255, 105, 180, 0.3))' },
        to: { filter: 'drop-shadow(0 0 5px rgba(255, 105, 180, 0.6))' },
      },
      fadeIn: {
        from: { opacity: '0' },
        to: { opacity: '1' },
      },
      slideIn: {
        from: { transform: 'translateY(-20px)', opacity: '0' },
        to: { transform: 'translateY(0)', opacity: '1' },
      },
      sway: {
        '0%, 100%': { transform: 'rotate(-8deg)' },
        '50%': { transform: 'rotate(8deg)' },
      },
      'grow-flower': {
        '0%': { transform: 'scale(0) translateY(100%)' },
        '100%': { transform: 'scale(1) translateY(0)' },
      },
    },
    animation: {
      float: 'float 3s ease-in-out infinite',
      glow: 'glow 2s ease-in-out infinite',
      'title-glow': 'title-glow 2s ease-in-out infinite alternate',
      'fade-in': 'fadeIn 0.5s ease',
      'slide-in': 'slideIn 0.3s ease-out',
      sway: 'sway 4s ease-in-out infinite',
      'sway-fast': 'sway 2s ease-in-out infinite',
      'grow-flower': 'grow-flower 2s backwards',
    },
    container: {
      center: true,
      padding: '2rem',
      screens: {
        '2xl': '1400px',
      },
    },
    extend: {
      colors: {
        border: 'hsl(var(--border))',
        input: 'hsl(var(--input))',
        ring: 'hsl(var(--ring))',
        background: 'hsl(var(--background))',
        foreground: 'hsl(var(--foreground))',
        primary: {
          DEFAULT: 'hsl(var(--primary))',
          foreground: 'hsl(var(--primary-foreground))',
        },
        secondary: {
          DEFAULT: 'hsl(var(--secondary))',
          foreground: 'hsl(var(--secondary-foreground))',
        },
        destructive: {
          DEFAULT: 'hsl(var(--destructive))',
          foreground: 'hsl(var(--destructive-foreground))',
        },
        muted: {
          DEFAULT: 'hsl(var(--muted))',
          foreground: 'hsl(var(--muted-foreground))',
        },
        accent: {
          DEFAULT: 'hsl(var(--accent))',
          foreground: 'hsl(var(--accent-foreground))',
        },
        popover: {
          DEFAULT: 'hsl(var(--popover))',
          foreground: 'hsl(var(--popover-foreground))',
        },
        card: {
          DEFAULT: 'hsl(var(--card))',
          foreground: 'hsl(var(--card-foreground))',
        },
        'love-primary': 'var(--love-primary)',
        'love-primary-dark': 'var(--love-primary-dark)',
        'love-primary-light': 'var(--love-primary-light)',
        'love-bg-start': 'var(--love-bg-start)',
        'love-bg-end': 'var(--love-bg-end)',
      },
      borderRadius: {
        lg: 'var(--radius)',
        md: 'calc(var(--radius) - 2px)',
        sm: 'calc(var(--radius) - 4px)',
      },
    },
  },
  plugins: [],
}

