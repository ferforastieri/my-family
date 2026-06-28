import Link from 'next/link';
import { copy, Locale, localePath } from '@/lib/i18n';

type SiteHeaderProps = {
  locale: Locale;
  loginHref?: string;
  primaryHref?: string;
  primaryLabel?: string;
  tone?: 'default' | 'light';
  sectionLinks?: boolean;
};

export function SiteHeader({
  locale,
  loginHref,
  primaryHref,
  primaryLabel,
  tone = 'default',
  sectionLinks = true,
}: SiteHeaderProps) {
  const t = copy[locale];
  return (
    <header className={`site-header ${tone === 'light' ? 'light' : ''}`} aria-label="Principal">
      <Link href={localePath(locale)} className={`brand ${tone === 'light' ? 'light' : ''}`}>
        <img className="brand-logo" src="/brand/family-logo.png" alt={t.brand} />
      </Link>
      <nav className="top-nav" aria-label="Navegação">
        {sectionLinks ? (
          <>
            <a href="#produto">{t.navProduct}</a>
            <a href="#planos">{t.navPlans}</a>
            <Link href={localePath(locale, '/privacidade')}>
              {t.navPrivacy}
            </Link>
          </>
        ) : null}
        {loginHref ? <a href={loginHref}>{t.navLogin}</a> : null}
        {primaryHref ? (
          <a className="nav-action" href={primaryHref}>
            {primaryLabel ?? t.navSignup}
          </a>
        ) : null}
      </nav>
    </header>
  );
}
