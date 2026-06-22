import Link from 'next/link';
import { copy, type Locale } from '@/lib/i18n';
import { mediaUrl, type PublicSite } from '@/lib/api';

export function PublicSiteView({ site, locale, demo = false }: { site: PublicSite; locale: Locale; demo?: boolean }) {
  const t = copy[locale];
  const visibleEvents = site.home.events.filter(event => !event.hidden);
  return <>
    {demo && <div className="demo-banner">{t.demoBadge}</div>}
    <header className="nav"><div className="shell nav-inner">
      <Link href={`/${locale}`} className="brand"><span className="brand-mark">🌸</span><span>{site.tenant.name}</span></Link>
      <div className="nav-actions"><Link className="button ghost" href={`/${locale}`}>{t.back}</Link>{demo && <Link className="button primary" href={`/${locale}/signup`}>{t.primaryCta}</Link>}</div>
    </div></header>
    <main>
      <section className="site-hero shell"><span className="eyebrow">♥ {t.eyebrow}</span><h1>{site.tenant.name}</h1><p>{t.heroBody}</p></section>
      {visibleEvents.length > 0 && <section className="section"><div className="shell"><div className="event-grid">{visibleEvents.map((event,index)=><article className="card" key={`${event.title}-${index}`}><div className="feature-icon">{event.icon || '♥'}</div><h3>{event.title}</h3><div className="event-date">{formatDate(event.date, locale)}</div><p>{event.message}</p></article>)}</div></div></section>}
      {site.photos.length > 0 && <section className="section"><div className="shell"><div className="section-heading"><h2>{t.photos}</h2><p>{t.memories}</p></div><div className="memory-grid">{site.photos.map(photo=><article className="card memory" key={photo.id}>
        {photo.url && <img alt={photo.texto || photo.album || t.photos} src={mediaUrl(site.tenant.slug, photo.url)}/>}<div className="memory-body"><h3>{photo.album || t.photos}</h3>{photo.texto && <p>{photo.texto}</p>}</div>
      </article>)}</div></div></section>}
      {site.songs.length > 0 && <section className="section"><div className="shell"><div className="section-heading"><h2>{t.songs}</h2><p>{t.playlist}</p></div><div className="content-grid">{site.songs.map(song=><article className="card" key={song.id}><div className="feature-icon">♫</div><h3>{song.titulo}</h3><p>{song.artista}{song.descricao ? ` · ${song.descricao}` : ''}</p></article>)}</div></div></section>}
      {site.journey.length > 0 && <section className="section"><div className="shell"><div className="section-heading"><h2>{t.story}</h2><p>{t.journey}</p></div><div className="content-grid">{site.journey.map(item=><article className="card" key={item.id}><div className="feature-icon">🌿</div><h3>{item.titulo}</h3><p>{item.conteudo}</p></article>)}</div></div></section>}
      {site.letters.length > 0 && <section className="section"><div className="shell"><div className="section-heading"><h2>{t.letters}</h2></div><div className="content-grid">{site.letters.map(item=><article className="card" key={item.id}><div className="feature-icon">💌</div><h3>{item.titulo}</h3><p>{item.conteudo}</p></article>)}</div></div></section>}
      {demo && <section className="final-cta"><div className="shell"><h2>{t.finalTitle}</h2><p>{t.finalBody}</p><Link className="button primary" href={`/${locale}/signup`}>{t.primaryCta}</Link></div></section>}
    </main>
  </>;
}

function formatDate(value: string, locale: Locale) {
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return '';
  const language = locale === 'pt' ? 'pt-BR' : locale;
  return new Intl.DateTimeFormat(language, { day: '2-digit', month: 'short', year: 'numeric' }).format(date);
}

