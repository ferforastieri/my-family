import { notFound } from 'next/navigation';
import type { Metadata } from 'next';
import { fetchPublicSite } from '@/lib/api';
import { isLocale } from '@/lib/i18n';
import { PublicSiteView } from '@/components/public-site';

export const metadata: Metadata = { title: 'Demonstração' };

export default async function DemoPage({ params }: { params: Promise<{ locale: string }> }) {
  const { locale } = await params;
  if (!isLocale(locale)) notFound();
  try { return <PublicSiteView site={await fetchPublicSite()} locale={locale} demo/>; }
  catch { notFound(); }
}

