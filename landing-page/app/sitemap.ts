import type { MetadataRoute } from 'next';
import { getPublishedFamilySlugs, getSiteOrigin } from '@/lib/api';
import { locales } from '@/lib/i18n';

export const dynamic = 'force-dynamic';

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const now = new Date();
  const slugs = await getPublishedFamilySlugs();
  const siteOrigin = getSiteOrigin();
  return [
    ...locales.flatMap((locale) => [
      {
        url: `${siteOrigin}/${locale}`,
        lastModified: now,
        changeFrequency: 'weekly' as const,
        priority: 1,
      },
      {
        url: `${siteOrigin}/${locale}/privacidade`,
        lastModified: now,
        changeFrequency: 'monthly' as const,
        priority: 0.7,
      },
    ]),
    ...slugs.flatMap((slug) =>
      locales.map((locale) => ({
        url: `${siteOrigin}/${locale}/familia/${encodeURIComponent(slug)}`,
        lastModified: now,
        changeFrequency: 'weekly' as const,
        priority: 0.6,
      })),
    ),
  ];
}
