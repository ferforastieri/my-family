import Link from 'next/link';
import { copy, Locale, localePath } from '@/lib/i18n';

type SiteFooterProps = {
  locale: Locale;
  appHref: string;
  loginHref: string;
};

export function SiteFooter({ locale, appHref, loginHref }: SiteFooterProps) {
  const t = copy[locale];
  return (
    <footer className="site-footer">
      <div className="footer-inner">
        <div className="footer-brand">
          <img className="footer-logo" src="/brand/family-logo.png" alt={t.brand} />
          <div>
            <p>{t.footerTagline}</p>
          </div>
        </div>
        <nav className="footer-links" aria-label="Rodapé">
          <Link href={localePath(locale)}>{t.navProduct}</Link>
          <Link href={localePath(locale, '/privacidade')}>{t.navPrivacy}</Link>
          <a href={appHref}>{t.footerApp}</a>
          <a href={loginHref}>{t.navLogin}</a>
        </nav>
      </div>
      <div className="footer-bottom">
        <span>{t.footerRights}</span>
      </div>
    </footer>
  );
}
