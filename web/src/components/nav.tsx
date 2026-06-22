import Link from 'next/link';
import { copy, locales, type Locale } from '@/lib/i18n';

export function Nav({ locale }: { locale: Locale }) {
  const t = copy[locale];
  return <header className="nav"><div className="shell nav-inner">
    <Link href={`/${locale}`} className="brand"><span className="brand-mark">🌸</span><span>{t.brand}</span></Link>
    <div className="nav-actions">
      <div className="locale-switch">{locales.map(item => <Link className={item === locale ? 'active' : ''} href={`/${item}`} key={item}>{item}</Link>)}</div>
      <Link className="button ghost hide-mobile" href={`/${locale}/demo`}>{t.navDemo}</Link>
      <Link className="button ghost hide-mobile" href="/app">{t.navLogin}</Link>
      <Link className="button primary" href={`/${locale}/signup`}>{t.navStart}</Link>
    </div>
  </div></header>;
}

