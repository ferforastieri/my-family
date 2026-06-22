import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: { default: 'Nossa Família', template: '%s · Nossa Família' },
  description: 'Um espaço bonito para memórias, histórias e momentos da sua família.',
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return <html lang="pt-BR"><body>{children}</body></html>;
}

