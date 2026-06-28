import { Locale } from './i18n';

export type PublicPlan = {
  id: string;
  interval: string;
  name: string;
  description: string;
  priceCents: number;
  currency: string;
  highlighted: boolean;
  sortOrder: number;
  updatedAt: string;
};

export type PublicLegalDocument = {
  id: string;
  kind: 'privacy-policy';
  locale: Locale;
  title: string;
  body: string;
  format: 'plain' | 'markdown';
  effectiveDate: string | null;
  updatedAt: string;
};

export type LandingData = {
  locale: Locale;
  plans: PublicPlan[];
  privacyPolicy: PublicLegalDocument | null;
};

export type PublicFamilySite = {
  tenant: {
    name: string;
    slug: string;
    locale: string;
    theme: Record<string, unknown>;
    isDemo: boolean;
  };
  site: {
    brand?: {
      headline?: string;
      subheadline?: string;
      logoPath?: string | null;
      coverPath?: string | null;
    };
    seo?: {
      title?: string;
      description?: string;
      socialImagePath?: string | null;
    };
  };
  publishedAt?: string | null;
  home?: { events?: Array<Record<string, unknown>> };
  photos?: Array<Record<string, unknown>>;
  songs?: Array<Record<string, unknown>>;
  letters?: Array<Record<string, unknown>>;
  journey?: Array<Record<string, unknown>>;
};

const backendOrigin =
  process.env.BACKEND_ORIGIN?.replace(/\/$/, '') ?? 'http://localhost:3000';

export const siteOrigin =
  process.env.NEXT_PUBLIC_SITE_ORIGIN?.replace(/\/$/, '') ??
  'http://localhost:3458';

export const appOrigin =
  process.env.NEXT_PUBLIC_APP_ORIGIN?.replace(/\/$/, '') ??
  `${backendOrigin}/app`;

export function mediaUrl(slug: string, relativePath: string) {
  const search = new URLSearchParams({ path: relativePath });
  return `${backendOrigin}/api/public/sites/${encodeURIComponent(slug)}/media?${search.toString()}`;
}

export async function getLandingData(locale: Locale): Promise<LandingData> {
  try {
    return await backendFetch<LandingData>(`/api/public/landing?locale=${locale}`);
  } catch {
    return { locale, plans: [], privacyPolicy: null };
  }
}

export async function getPrivacyPolicy(
  locale: Locale,
): Promise<PublicLegalDocument | null> {
  try {
    return await backendFetch<PublicLegalDocument | null>(
      `/api/public/landing/privacy-policy?locale=${locale}`,
    );
  } catch {
    return null;
  }
}

export async function getPublishedFamilySlugs(): Promise<string[]> {
  try {
    const data = await backendFetch<{ slugs: string[] }>(
      '/api/public/sites/published-slugs',
    );
    return data.slugs ?? [];
  } catch {
    return [];
  }
}

export async function getFamilySite(
  slug: string,
): Promise<PublicFamilySite | null> {
  try {
    return await backendFetch<PublicFamilySite>(
      `/api/public/sites/${encodeURIComponent(slug)}`,
    );
  } catch {
    return null;
  }
}

async function backendFetch<T>(path: string): Promise<T> {
  const response = await fetch(`${backendOrigin}${path}`, {
    next: { revalidate: 300 },
    headers: { accept: 'application/json' },
  });
  if (!response.ok) {
    throw new Error(`Backend request failed: ${response.status}`);
  }
  const payload = (await response.json()) as unknown;
  return unwrapApiResponse<T>(payload);
}

function unwrapApiResponse<T>(payload: unknown): T {
  if (
    payload &&
    typeof payload === 'object' &&
    'ok' in payload &&
    'data' in payload
  ) {
    return (payload as { data: T }).data;
  }
  return payload as T;
}
