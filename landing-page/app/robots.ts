import type { MetadataRoute } from 'next';
import { getSiteOrigin } from '@/lib/api';

export const dynamic = 'force-dynamic';

export default function robots(): MetadataRoute.Robots {
  const siteOrigin = getSiteOrigin();
  return {
    rules: [
      { userAgent: '*', allow: '/', disallow: ['/api/', '/app/'] },
    ],
    sitemap: `${siteOrigin}/sitemap.xml`,
  };
}
