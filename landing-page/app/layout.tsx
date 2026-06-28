import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  icons: {
    icon: '/favicon.png',
    apple: '/icon-192.png',
  },
  title: {
    default: 'Sua Família',
    template: '%s',
  },
};

export default function RootLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="pt-BR">
      <body>{children}</body>
    </html>
  );
}
