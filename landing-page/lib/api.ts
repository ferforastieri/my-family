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

export function getApiBaseUrl(): string {
  const value = requiredEnv('API_BASE_URL');
  if (!value.endsWith('/api')) {
    throw new Error('API_BASE_URL deve terminar com /api.');
  }
  return value;
}

export function getSiteOrigin(): string {
  return getApiBaseUrl().slice(0, -4);
}

export function getAppOrigin(): string {
  return `${getSiteOrigin()}/app`;
}

export function mediaUrl(slug: string, relativePath: string) {
  const search = new URLSearchParams({ path: relativePath });
  return `${getApiBaseUrl()}/public/sites/${encodeURIComponent(slug)}/media?${search.toString()}`;
}

export async function getLandingData(locale: Locale): Promise<LandingData> {
  return backendFetch<LandingData>(`/public/landing?locale=${locale}`);
}

export async function getPrivacyPolicy(
  locale: Locale,
): Promise<PublicLegalDocument | null> {
  return backendFetch<PublicLegalDocument | null>(
    `/public/landing/privacy-policy?locale=${locale}`,
  );
}

export async function getPublishedFamilySlugs(): Promise<string[]> {
  const data = await backendFetch<{ slugs: string[] }>(
    '/public/sites/published-slugs',
  );
  return data.slugs;
}

export async function getFamilySite(
  slug: string,
): Promise<PublicFamilySite | null> {
  return backendFetch<PublicFamilySite | null>(
    `/public/sites/${encodeURIComponent(slug)}`,
  );
}

async function backendFetch<T>(path: string): Promise<T> {
  const response = await fetch(`${getApiBaseUrl()}${path}`, {
    cache: 'no-store',
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

function requiredEnv(name: string): string {
  const value = process.env[name]?.trim().replace(/\/+$/, '');
  if (!value) throw new Error(`${name} não foi configurada.`);
  return value;
}
