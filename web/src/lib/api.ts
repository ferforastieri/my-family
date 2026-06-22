const internalApi =
  process.env.API_INTERNAL_URL ||
  process.env.NEXT_PUBLIC_API_BASE_URL ||
  'http://localhost:3001/api';

export const publicApi =
  process.env.NEXT_PUBLIC_API_BASE_URL || 'http://localhost:3001/api';

export type PublicSite = {
  tenant: { name: string; slug: string; locale: string; theme: Record<string, unknown>; isDemo: boolean };
  home: { events: Array<{ title: string; icon: string; date: string; message: string; hidden?: boolean }>; galleryImages: string[]; galleryOrder?: number | null };
  photos: Array<Record<string, unknown> & { id: string; url?: string; texto?: string; album?: string }>;
  songs: Array<Record<string, unknown> & { id: string; titulo?: string; artista?: string; descricao?: string }>;
  letters: Array<Record<string, unknown> & { id: string; titulo?: string; conteudo?: string }>;
  journey: Array<Record<string, unknown> & { id: string; titulo?: string; conteudo?: string }>;
};

export async function fetchPublicSite(slug?: string): Promise<PublicSite> {
  const route = slug ? `/public/sites/${encodeURIComponent(slug)}` : '/public/sites/demo';
  const response = await fetch(`${internalApi}${route}`, { next: { revalidate: 60 } });
  if (!response.ok) throw new Error('SITE_NOT_FOUND');
  const payload = await response.json();
  return (payload.data ?? payload) as PublicSite;
}

export function mediaUrl(slug: string, path: string) {
  return `${publicApi}/public/sites/${encodeURIComponent(slug)}/media?path=${encodeURIComponent(path)}`;
}

