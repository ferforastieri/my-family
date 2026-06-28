import type { MetadataRoute } from 'next';
import { siteOrigin } from '@/lib/api';

export default function robots(): MetadataRoute.Robots {
  return {
    rules: [
      { userAgent: '*', allow: '/', disallow: ['/api/', '/app/'] },
    ],
    sitemap: `${siteOrigin}/sitemap.xml`,
  };
}
