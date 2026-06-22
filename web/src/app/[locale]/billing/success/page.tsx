import Link from 'next/link';
import { notFound } from 'next/navigation';
import { Nav } from '@/components/nav';
import { copy, isLocale } from '@/lib/i18n';

export default async function BillingSuccess({ params }: { params: Promise<{ locale: string }> }) {
  const { locale } = await params; if (!isLocale(locale)) notFound(); const t = copy[locale];
  return <><Nav locale={locale}/><main className="form-wrap"><div className="shell"><section className="card form-card"><div className="feature-icon">✓</div><h1>{t.successTitle}</h1><p className="lead">{t.successBody}</p><Link className="button primary" href="/app">{t.openPanel}</Link></section></div></main></>;
}

