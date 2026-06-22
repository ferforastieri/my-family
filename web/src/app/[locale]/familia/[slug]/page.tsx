import { notFound } from 'next/navigation';
import type { Metadata } from 'next';
import { fetchPublicSite } from '@/lib/api';
import { isLocale } from '@/lib/i18n';
import { PublicSiteView } from '@/components/public-site';

export async function generateMetadata({ params }: { params: Promise<{ locale: string; slug: string }> }): Promise<Metadata> {
  const { slug } = await params;
  try { const site = await fetchPublicSite(slug); return { title: site.tenant.name, description: `Memórias e história de ${site.tenant.name}.` }; }
  catch { return { title: 'Site não encontrado' }; }
}

export default async function FamilyPage({ params }: { params: Promise<{ locale: string; slug: string }> }) {
  const { locale, slug } = await params;
  if (!isLocale(locale)) notFound();
  try { return <PublicSiteView site={await fetchPublicSite(slug)} locale={locale}/>; }
  catch { notFound(); }
}

