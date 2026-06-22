import { notFound } from 'next/navigation';
import { Nav } from '@/components/nav';
import { SignupForm } from '@/components/signup-form';
import { copy, isLocale } from '@/lib/i18n';

export default async function SignupPage({ params }: { params: Promise<{ locale: string }> }) {
  const { locale } = await params; if (!isLocale(locale)) notFound(); const t = copy[locale];
  return <><Nav locale={locale}/><main className="form-wrap"><div className="shell"><section className="card form-card"><span className="eyebrow">♥ {t.eyebrow}</span><h1>{t.signupTitle}</h1><p className="lead">{t.signupBody}</p><SignupForm locale={locale}/></section></div></main></>;
}

