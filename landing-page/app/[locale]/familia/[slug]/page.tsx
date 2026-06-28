import type { Metadata } from 'next';
import Link from 'next/link';
import { notFound } from 'next/navigation';
import { appOrigin, getFamilySite, mediaUrl, siteOrigin } from '@/lib/api';
import { copy, localePath, resolveLocale } from '@/lib/i18n';

type PageProps = {
  params: Promise<{ locale: string; slug: string }>;
};

export const revalidate = 300;

export async function generateMetadata({
  params,
}: PageProps): Promise<Metadata> {
  const { locale: rawLocale, slug } = await params;
  const locale = resolveLocale(rawLocale);
  const site = await getFamilySite(slug);
  if (!site) return {};
  const title =
    site.site?.seo?.title ||
    site.site?.brand?.headline ||
    site.tenant.name;
  const description =
    site.site?.seo?.description ||
    site.site?.brand?.subheadline ||
    copy[locale].seo.description;
  const imagePath =
    site.site?.seo?.socialImagePath ||
    site.site?.brand?.coverPath ||
    firstString(site.photos?.[0]?.url);
  const image = imagePath ? mediaUrl(site.tenant.slug, imagePath) : undefined;
  const path = localePath(locale, `/familia/${encodeURIComponent(slug)}`);
  return {
    title,
    description,
    alternates: { canonical: `${siteOrigin}${path}` },
    openGraph: {
      title,
      description,
      url: `${siteOrigin}${path}`,
      type: 'website',
      images: image ? [{ url: image }] : undefined,
    },
  };
}

export default async function FamilyPage({ params }: PageProps) {
  const { locale: rawLocale, slug } = await params;
  const locale = resolveLocale(rawLocale);
  const t = copy[locale];
  const site = await getFamilySite(slug);
  if (!site) notFound();

  const brand = site.site?.brand ?? {};
  const headline = brand.headline || site.tenant.name;
  const subheadline = brand.subheadline || t.familyPage.empty;
  const cover = brand.coverPath ? mediaUrl(site.tenant.slug, brand.coverPath) : null;
  const loginUrl = `${appOrigin}/familia/${encodeURIComponent(site.tenant.slug)}/login?locale=${locale}`;
  const photos = (site.photos ?? []).slice(0, 12);
  const songs = (site.songs ?? []).slice(0, 8);
  const journey = (site.journey ?? []).slice(0, 8);
  const letters = (site.letters ?? []).slice(0, 8);
  const events = ((site.home?.events ?? []) as Array<Record<string, unknown>>)
    .filter((event) => event.hidden !== true)
    .slice(0, 8);
  const hasContent =
    photos.length || songs.length || journey.length || letters.length || events.length;

  return (
    <main className="family-page">
      <section className="family-hero">
        {cover ? (
          <img className="family-cover" src={cover} alt="" />
        ) : (
          <div className="family-cover generated" />
        )}
        <div className="family-overlay" />
        <header className="site-header family-header" aria-label="Principal">
          <Link href={localePath(locale)} className="brand light">
            <span className="brand-mark">NF</span>
            <span>{t.brand}</span>
          </Link>
          <a className="button light-button" href={loginUrl}>
            {t.familyPage.login}
          </a>
        </header>
        <div className="family-hero-content">
          <p className="eyebrow light-text">{site.tenant.name}</p>
          <h1>{headline}</h1>
          <p>{subheadline}</p>
        </div>
      </section>

      {hasContent ? (
        <section className="section family-content">
          <ContentSection title={t.familyPage.events} items={events} kind="event" slug={site.tenant.slug} />
          <ContentSection title={t.familyPage.memories} items={photos} kind="photo" slug={site.tenant.slug} />
          <ContentSection title={t.familyPage.playlist} items={songs} kind="song" slug={site.tenant.slug} />
          <ContentSection title={t.familyPage.journey} items={journey} kind="text" slug={site.tenant.slug} />
          <ContentSection title={t.familyPage.letters} items={letters} kind="text" slug={site.tenant.slug} />
        </section>
      ) : (
        <section className="section">
          <p className="empty-state">{t.familyPage.empty}</p>
        </section>
      )}
    </main>
  );
}

function ContentSection({
  title,
  items,
  kind,
  slug,
}: {
  title: string;
  items: Array<Record<string, unknown>>;
  kind: 'photo' | 'song' | 'event' | 'text';
  slug: string;
}) {
  if (!items.length) return null;
  return (
    <section className="family-section">
      <h2>{title}</h2>
      <div className={`family-grid ${kind}`}>
        {items.map((item, index) => (
          <article className="family-card" key={`${title}-${index}`}>
            {kind === 'photo' && firstString(item.url) ? (
              <img
                src={mediaUrl(slug, firstString(item.url) ?? '')}
                alt={firstString(item.texto) || firstString(item.album) || title}
                loading="lazy"
              />
            ) : null}
            <div>
              <h3>{itemTitle(item, title)}</h3>
              <p>{itemBody(item)}</p>
            </div>
          </article>
        ))}
      </div>
    </section>
  );
}

function itemTitle(item: Record<string, unknown>, fallback: string) {
  return (
    firstString(item.title) ||
    firstString(item.titulo) ||
    firstString(item.album) ||
    fallback
  );
}

function itemBody(item: Record<string, unknown>) {
  return (
    firstString(item.body) ||
    firstString(item.message) ||
    firstString(item.conteudo) ||
    firstString(item.texto) ||
    [firstString(item.artista), firstString(item.descricao)]
      .filter(Boolean)
      .join(' · ')
  );
}

function firstString(value: unknown) {
  return typeof value === 'string' && value.trim() ? value.trim() : null;
}
