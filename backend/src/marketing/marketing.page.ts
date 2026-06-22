export type MarketingLocale = 'pt' | 'en' | 'es';

type Copy = {
  brand: string;
  title: string;
  description: string;
  eyebrow: string;
  primary: string;
  demo: string;
  login: string;
  sectionTitle: string;
  sectionBody: string;
  features: Array<[string, string, string]>;
  howTitle: string;
  steps: Array<[string, string]>;
  priceTitle: string;
  priceBody: string;
  finalTitle: string;
  finalBody: string;
  footer: string;
  memories: string;
  playlist: string;
  journey: string;
  letters: string;
  privateSite: string;
};

const copy: Record<MarketingLocale, Copy> = {
  pt: {
    brand: 'Nossa Família',
    title: 'A história da sua família merece um cantinho especial.',
    description:
      'Memórias, cartas, músicas, datas importantes e pequenos momentos reunidos em um espaço bonito, privado e feito para durar.',
    eyebrow: 'Um lugar só de vocês',
    primary: 'Criar meu espaço',
    demo: 'Explorar demonstração',
    login: 'Entrar',
    sectionTitle: 'Tudo que aproxima, sem complicar.',
    sectionBody:
      'Um espaço preparado para cada família guardar, compartilhar e contar sua própria história.',
    features: [
      ['📷', 'Memórias em fotos', 'Organize fotos, vídeos e álbuns especiais.'],
      [
        '♫',
        'A trilha sonora de vocês',
        'Guarde as músicas que marcaram cada fase.',
      ],
      ['💌', 'Cartas e declarações', 'Escreva aquilo que merece permanecer.'],
      [
        '🌿',
        'Uma linha do tempo viva',
        'Conte a história da família capítulo por capítulo.',
      ],
      [
        '💬',
        'Momentos compartilhados',
        'Chat, listas, jogos e pequenos combinados.',
      ],
      [
        '🔐',
        'Privado de verdade',
        'Você decide quem entra e o que cada pessoa acessa.',
      ],
    ],
    howTitle: 'Do cadastro ao espaço publicado',
    steps: [
      ['Crie sua conta', 'Escolha o nome e o endereço da sua família.'],
      ['Ative a assinatura', 'Faça o pagamento com confirmação automática.'],
      ['Conte sua história', 'Personalize, convide sua família e publique.'],
    ],
    priceTitle: 'Um plano simples para guardar o que importa.',
    priceBody:
      'Web, aplicativo e atualizações contínuas em uma única assinatura.',
    finalTitle: 'Tem coisas que não cabem apenas na galeria do celular.',
    finalBody: 'Dê às suas memórias um lugar para florescer.',
    footer: 'Feito com carinho para histórias reais.',
    memories: 'Memórias',
    playlist: 'Playlist',
    journey: 'Nossa jornada',
    letters: 'Cartas',
    privateSite: 'Espaço familiar compartilhado por link.',
  },
  en: {
    brand: 'Our Family',
    title: 'Your family story deserves a special home.',
    description:
      'Memories, letters, music, meaningful dates and everyday moments gathered in a beautiful, private space built to last.',
    eyebrow: 'A place that belongs to you',
    primary: 'Create my space',
    demo: 'Explore the demo',
    login: 'Sign in',
    sectionTitle: 'Everything that brings you closer, without the fuss.',
    sectionBody:
      'A space made for every family to save, share and tell its own story.',
    features: [
      [
        '📷',
        'Photo memories',
        'Organize photos, videos and meaningful albums.',
      ],
      [
        '♫',
        'Your shared soundtrack',
        'Save the music that shaped every chapter.',
      ],
      ['💌', 'Letters and declarations', 'Write down what deserves to remain.'],
      ['🌿', 'A living timeline', 'Tell your family story chapter by chapter.'],
      ['💬', 'Shared moments', 'Chat, lists, games and everyday plans.'],
      [
        '🔐',
        'Truly private',
        'You decide who joins and what each person can access.',
      ],
    ],
    howTitle: 'From signup to a published space',
    steps: [
      ['Create your account', 'Choose a name and address for your family.'],
      ['Activate your plan', 'Pay securely with automatic confirmation.'],
      ['Tell your story', 'Customize, invite your family and publish.'],
    ],
    priceTitle: 'One simple plan for what matters.',
    priceBody: 'Web, mobile app and continuous updates in one subscription.',
    finalTitle: 'Some things deserve more than a phone gallery.',
    finalBody: 'Give your memories a place to bloom.',
    footer: 'Made with care for real stories.',
    memories: 'Memories',
    playlist: 'Playlist',
    journey: 'Our journey',
    letters: 'Letters',
    privateSite: 'A family space shared by link.',
  },
  es: {
    brand: 'Nuestra Familia',
    title: 'La historia de tu familia merece un rincón especial.',
    description:
      'Recuerdos, cartas, música, fechas importantes y momentos cotidianos reunidos en un espacio hermoso, privado y hecho para durar.',
    eyebrow: 'Un lugar solo para ustedes',
    primary: 'Crear mi espacio',
    demo: 'Explorar demostración',
    login: 'Entrar',
    sectionTitle: 'Todo lo que acerca, sin complicaciones.',
    sectionBody:
      'Un espacio preparado para que cada familia guarde, comparta y cuente su historia.',
    features: [
      [
        '📷',
        'Recuerdos en fotos',
        'Organiza fotos, videos y álbumes especiales.',
      ],
      [
        '♫',
        'La banda sonora de ustedes',
        'Guarda la música que marcó cada etapa.',
      ],
      [
        '💌',
        'Cartas y declaraciones',
        'Escribe aquello que merece permanecer.',
      ],
      [
        '🌿',
        'Una línea de tiempo viva',
        'Cuenta la historia familiar capítulo a capítulo.',
      ],
      [
        '💬',
        'Momentos compartidos',
        'Chat, listas, juegos y planes cotidianos.',
      ],
      [
        '🔐',
        'Realmente privado',
        'Tú decides quién entra y qué puede ver cada persona.',
      ],
    ],
    howTitle: 'Del registro al espacio publicado',
    steps: [
      ['Crea tu cuenta', 'Elige el nombre y la dirección de tu familia.'],
      [
        'Activa la suscripción',
        'Paga de forma segura con confirmación automática.',
      ],
      ['Cuenta tu historia', 'Personaliza, invita a tu familia y publica.'],
    ],
    priceTitle: 'Un plan sencillo para guardar lo importante.',
    priceBody:
      'Web, aplicación y actualizaciones continuas en una suscripción.',
    finalTitle: 'Hay cosas que no caben solo en la galería del móvil.',
    finalBody: 'Dale a tus recuerdos un lugar donde florecer.',
    footer: 'Hecho con cariño para historias reales.',
    memories: 'Recuerdos',
    playlist: 'Playlist',
    journey: 'Nuestro camino',
    letters: 'Cartas',
    privateSite: 'Un espacio familiar compartido por enlace.',
  },
};

export function isMarketingLocale(value: string): value is MarketingLocale {
  return value === 'pt' || value === 'en' || value === 'es';
}

export function renderLanding(locale: MarketingLocale, origin: string): string {
  const t = copy[locale];
  const canonical = `${origin}/${locale}`;
  const featureCards = t.features
    .map(
      ([icon, title, body]) =>
        `<article class="card"><div class="feature-icon">${icon}</div><h3>${escapeHtml(title)}</h3><p>${escapeHtml(body)}</p></article>`,
    )
    .join('');
  const steps = t.steps
    .map(
      ([title, body], index) =>
        `<article class="card"><div class="step-number">${index + 1}</div><h3>${escapeHtml(title)}</h3><p>${escapeHtml(body)}</p></article>`,
    )
    .join('');

  return document({
    locale,
    title: `${t.brand} — ${t.title}`,
    description: t.description,
    canonical,
    origin,
    body: `
      ${nav(locale, t, origin)}
      <main>
        <section class="hero"><div class="shell hero-grid">
          <div><span class="eyebrow">♥ ${escapeHtml(t.eyebrow)}</span><h1>${escapeHtml(t.title)}</h1><p class="lead">${escapeHtml(t.description)}</p>
            <div class="hero-actions"><a class="button primary" href="/app/signup?locale=${locale}">${escapeHtml(t.primary)} →</a><a class="button ghost" href="/app/demo?locale=${locale}">${escapeHtml(t.demo)}</a></div>
          </div>
          <div class="preview"><div class="preview-head"><small>${escapeHtml(t.brand)}</small><h3>${escapeHtml(t.eyebrow)}</h3></div><div class="preview-cards">${t.features
            .slice(0, 4)
            .map(
              ([icon, title]) =>
                `<div class="mini-card"><span>${icon}</span><strong>${escapeHtml(title)}</strong></div>`,
            )
            .join('')}</div></div>
        </div><div class="flower-field"></div></section>
        <section class="section"><div class="shell"><div class="section-heading"><h2>${escapeHtml(t.sectionTitle)}</h2><p>${escapeHtml(t.sectionBody)}</p></div><div class="features">${featureCards}</div></div></section>
        <section class="section soft"><div class="shell"><div class="section-heading"><h2>${escapeHtml(t.howTitle)}</h2></div><div class="steps">${steps}</div></div></section>
        <section class="section"><div class="shell"><div class="price"><div><h2>${escapeHtml(t.priceTitle)}</h2><p>${escapeHtml(t.priceBody)}</p></div><a class="button" href="/app/signup?locale=${locale}">${escapeHtml(t.primary)} →</a></div></div></section>
        <section class="final-cta"><div class="shell"><h2>${escapeHtml(t.finalTitle)}</h2><p>${escapeHtml(t.finalBody)}</p><a class="button primary" href="/app/signup?locale=${locale}">${escapeHtml(t.primary)}</a></div></section>
      </main>
      <footer class="footer"><div class="shell footer-inner"><span>🌸 ${escapeHtml(t.brand)}</span><span>${escapeHtml(t.footer)}</span></div></footer>`,
    structuredData: {
      '@context': 'https://schema.org',
      '@type': 'SoftwareApplication',
      name: t.brand,
      applicationCategory: 'LifestyleApplication',
      operatingSystem: 'Web, Android, iOS',
      description: t.description,
      url: canonical,
    },
  });
}

export function renderFamilySite(
  locale: MarketingLocale,
  origin: string,
  site: any,
): string {
  const t = copy[locale];
  const tenant = site.tenant ?? {};
  const name = String(tenant.name || t.brand);
  const slug = String(tenant.slug || '');
  const canonical = `${origin}/${locale}/familia/${encodeURIComponent(slug)}`;
  const events = Array.isArray(site.home?.events)
    ? site.home.events.filter((event: any) => !event?.hidden)
    : [];
  const photos = Array.isArray(site.photos) ? site.photos : [];
  const songs = Array.isArray(site.songs) ? site.songs : [];
  const journey = Array.isArray(site.journey) ? site.journey : [];
  const letters = Array.isArray(site.letters) ? site.letters : [];
  const firstImage = photos.find((photo: any) => photo?.url)?.url;
  const socialImage = firstImage
    ? mediaUrl(origin, slug, firstImage)
    : undefined;

  return document({
    locale,
    title: `${name} — ${t.brand}`,
    description: t.privateSite,
    canonical,
    origin,
    robots: 'noindex, nofollow, noarchive',
    socialImage,
    body: `
      <header class="nav"><div class="shell nav-inner"><a class="brand" href="/${locale}"><span class="brand-mark">🌸</span><span>${escapeHtml(name)}</span></a><a class="button ghost" href="/${locale}">← ${escapeHtml(t.brand)}</a></div></header>
      <main>
        <section class="site-hero shell"><span class="eyebrow">♥ ${escapeHtml(t.eyebrow)}</span><h1>${escapeHtml(name)}</h1><p>${escapeHtml(t.privateSite)}</p></section>
        ${section(events.length > 0, `<div class="event-grid">${events.map((event: any) => `<article class="card"><div class="feature-icon">${escapeHtml(String(event.icon || '♥'))}</div><h3>${escapeHtml(String(event.title || ''))}</h3><div class="event-date">${formatDate(event.date, locale)}</div><p>${escapeHtml(String(event.message || ''))}</p></article>`).join('')}</div>`)}
        ${contentSection(t.memories, photos.map((photo: any) => `<article class="card memory">${photo.url ? `<img loading="lazy" alt="${escapeHtml(String(photo.texto || photo.album || t.memories))}" src="${escapeHtml(mediaUrl(origin, slug, photo.url))}">` : ''}<div class="memory-body"><h3>${escapeHtml(String(photo.album || t.memories))}</h3>${photo.texto ? `<p>${escapeHtml(String(photo.texto))}</p>` : ''}</div></article>`).join(''), 'memory-grid')}
        ${contentSection(t.playlist, songs.map((song: any) => `<article class="card"><div class="feature-icon">♫</div><h3>${escapeHtml(String(song.titulo || ''))}</h3><p>${escapeHtml([song.artista, song.descricao].filter(Boolean).join(' · '))}</p></article>`).join(''))}
        ${contentSection(t.journey, journey.map((item: any) => `<article class="card"><div class="feature-icon">🌿</div><h3>${escapeHtml(String(item.titulo || ''))}</h3><p>${escapeHtml(String(item.conteudo || ''))}</p></article>`).join(''))}
        ${contentSection(t.letters, letters.map((item: any) => `<article class="card"><div class="feature-icon">💌</div><h3>${escapeHtml(String(item.titulo || ''))}</h3><p>${escapeHtml(String(item.conteudo || ''))}</p></article>`).join(''))}
      </main>`,
  });
}

function nav(locale: MarketingLocale, t: Copy, origin: string) {
  return `<header class="nav"><div class="shell nav-inner"><a href="/${locale}" class="brand"><span class="brand-mark">🌸</span><span>${escapeHtml(t.brand)}</span></a><div class="nav-actions"><div class="locale-switch">${(
    ['pt', 'en', 'es'] as const
  )
    .map(
      (value) =>
        `<a class="${value === locale ? 'active' : ''}" href="${origin}/${value}" hreflang="${value}">${value}</a>`,
    )
    .join(
      '',
    )}</div><a class="button ghost hide-mobile" href="/app/demo?locale=${locale}">${escapeHtml(t.demo)}</a><a class="button ghost" href="/app/login?locale=${locale}">${escapeHtml(t.login)}</a><a class="button primary hide-mobile" href="/app/signup?locale=${locale}">${escapeHtml(t.primary)}</a></div></div></header>`;
}

function document(data: {
  locale: MarketingLocale;
  title: string;
  description: string;
  canonical: string;
  origin: string;
  body: string;
  robots?: string;
  socialImage?: string;
  structuredData?: Record<string, unknown>;
}) {
  const alternates = (['pt', 'en', 'es'] as const)
    .map(
      (locale) =>
        `<link rel="alternate" hreflang="${locale}" href="${data.origin}/${locale}">`,
    )
    .join('');
  return `<!doctype html><html lang="${data.locale}"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>${escapeHtml(data.title)}</title><meta name="description" content="${escapeHtml(data.description)}"><meta name="robots" content="${data.robots ?? 'index, follow'}"><link rel="canonical" href="${escapeHtml(data.canonical)}">${alternates}<link rel="stylesheet" href="/marketing.css"><meta name="theme-color" content="#fff8fa"><meta property="og:type" content="website"><meta property="og:title" content="${escapeHtml(data.title)}"><meta property="og:description" content="${escapeHtml(data.description)}"><meta property="og:url" content="${escapeHtml(data.canonical)}">${data.socialImage ? `<meta property="og:image" content="${escapeHtml(data.socialImage)}">` : ''}<meta name="twitter:card" content="${data.socialImage ? 'summary_large_image' : 'summary'}">${data.structuredData ? `<script type="application/ld+json">${safeJson(data.structuredData)}</script>` : ''}</head><body>${data.body}</body></html>`;
}

function contentSection(
  title: string,
  cards: string,
  className = 'content-grid',
) {
  return section(
    Boolean(cards),
    `<div class="section-heading"><h2>${escapeHtml(title)}</h2></div><div class="${className}">${cards}</div>`,
  );
}

function section(visible: boolean, content: string) {
  return visible
    ? `<section class="section"><div class="shell">${content}</div></section>`
    : '';
}

function mediaUrl(origin: string, slug: string, path: unknown) {
  return `${origin}/api/public/sites/${encodeURIComponent(slug)}/media?path=${encodeURIComponent(String(path))}`;
}

function formatDate(value: unknown, locale: MarketingLocale) {
  const date = new Date(String(value || ''));
  if (Number.isNaN(date.getTime())) return '';
  return new Intl.DateTimeFormat(locale === 'pt' ? 'pt-BR' : locale, {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
  }).format(date);
}

function safeJson(value: Record<string, unknown>) {
  return JSON.stringify(value).replace(/</g, '\\u003c');
}

function escapeHtml(value: unknown) {
  return String(value ?? '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;');
}

export const marketingCss = `
:root{--pink:#ff69b4;--pink-dark:#d4488e;--ink:#26131d;--muted:#775b6b;--line:#ffdce9;--bg:#fff8fa;--bg-end:#fff0f5}*{box-sizing:border-box}html{scroll-behavior:smooth}body{margin:0;color:var(--ink);background:linear-gradient(180deg,var(--bg),var(--bg-end));font-family:Inter,ui-sans-serif,system-ui,-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif;min-height:100vh}a{color:inherit;text-decoration:none}.shell{width:min(1180px,calc(100% - 36px));margin:0 auto}.nav{position:sticky;top:0;z-index:20;backdrop-filter:blur(18px);background:rgba(255,248,250,.88);border-bottom:1px solid rgba(255,105,180,.13)}.nav-inner{height:76px;display:flex;align-items:center;justify-content:space-between;gap:22px}.brand{display:flex;align-items:center;gap:11px;font-family:Georgia,serif;font-weight:800;font-size:1.22rem}.brand-mark{display:grid;place-items:center;width:42px;height:42px;border:1px solid var(--line);border-radius:50%;background:#fff;box-shadow:0 8px 25px rgba(212,72,142,.13)}.nav-actions,.hero-actions{display:flex;gap:10px;align-items:center}.locale-switch{display:flex;border:1px solid var(--line);border-radius:999px;padding:3px;background:rgba(255,255,255,.7)}.locale-switch a{padding:6px 9px;border-radius:999px;font-size:.78rem;font-weight:800;text-transform:uppercase;color:var(--muted)}.locale-switch a.active{background:#fff;color:var(--pink-dark);box-shadow:0 2px 8px rgba(212,72,142,.12)}.button{border:0;cursor:pointer;display:inline-flex;align-items:center;justify-content:center;gap:8px;min-height:46px;padding:0 19px;border-radius:14px;font-weight:850;transition:.2s ease}.button:hover{transform:translateY(-2px)}.button.primary{color:#fff;background:linear-gradient(135deg,var(--pink),var(--pink-dark));box-shadow:0 12px 28px rgba(212,72,142,.23)}.button.ghost{color:var(--pink-dark);background:rgba(255,255,255,.72);border:1px solid var(--line)}.hero{position:relative;min-height:690px;display:grid;place-items:center;overflow:hidden;padding:84px 0 120px}.hero-grid{position:relative;z-index:2;display:grid;grid-template-columns:1.05fr .95fr;align-items:center;gap:70px}.eyebrow{display:inline-flex;color:var(--pink-dark);background:rgba(255,255,255,.78);border:1px solid var(--line);border-radius:999px;padding:8px 13px;font-weight:850;font-size:.82rem;text-transform:uppercase;letter-spacing:.08em}h1,h2,h3{font-family:Georgia,"Times New Roman",serif;margin:0}h1{margin-top:22px;font-size:clamp(2.8rem,6vw,5.25rem);line-height:.98;letter-spacing:-.045em;max-width:760px}.lead{max-width:670px;color:var(--muted);line-height:1.75;font-size:1.12rem;margin:25px 0 31px}.hero-actions{flex-wrap:wrap}.preview{background:rgba(255,255,255,.9);border:1px solid var(--line);border-radius:28px;padding:18px;box-shadow:0 30px 80px rgba(148,48,100,.18);transform:rotate(1.5deg)}.preview-head{border-radius:18px;padding:24px;color:#fff;background:linear-gradient(135deg,#ff8bc5,#cf3b83)}.preview-head h3{font-size:2rem;margin-top:6px}.preview-cards{display:grid;grid-template-columns:1fr 1fr;gap:11px;margin-top:12px}.mini-card,.card{background:rgba(255,255,255,.91);border:1px solid var(--line);border-radius:17px;box-shadow:0 8px 25px rgba(212,72,142,.08)}.mini-card{padding:18px;min-height:110px}.mini-card span{font-size:1.65rem}.mini-card strong{display:block;margin-top:13px;font-size:.9rem}.flower-field{position:absolute;inset:auto 0 0;height:170px;background:radial-gradient(circle at 10% 95%,#ff87bd 0 7px,transparent 8px),radial-gradient(circle at 28% 82%,#ffd15c 0 6px,transparent 7px),radial-gradient(circle at 52% 93%,#ff6fae 0 8px,transparent 9px),radial-gradient(circle at 76% 84%,#b88cff 0 7px,transparent 8px),linear-gradient(transparent 40%,rgba(105,180,95,.15))}.section{padding:105px 0}.section.soft{background:rgba(255,255,255,.35)}.section-heading{max-width:720px;margin:0 auto 45px;text-align:center}.section-heading h2{font-size:clamp(2.2rem,4vw,3.7rem)}.section-heading p,.card p,.site-hero p{color:var(--muted);line-height:1.7}.features{display:grid;grid-template-columns:repeat(3,1fr);gap:16px}.card{padding:24px}.feature-icon{display:grid;place-items:center;width:52px;height:52px;border-radius:15px;color:var(--pink-dark);background:rgba(255,105,180,.12);font-size:1.5rem}.card h3{margin-top:18px;font-size:1.25rem}.steps{display:grid;grid-template-columns:repeat(3,1fr);gap:17px}.step-number{color:#fff;background:var(--pink);width:42px;height:42px;display:grid;place-items:center;border-radius:50%;font-weight:900}.price{display:grid;grid-template-columns:1fr auto;align-items:center;gap:35px;padding:38px;border-radius:25px;color:#fff;background:linear-gradient(135deg,#b82c73,#ff69b4);box-shadow:0 25px 60px rgba(184,44,115,.25)}.price h2{font-size:clamp(2rem,4vw,3.25rem)}.price p{color:rgba(255,255,255,.86)}.price .button{background:#fff;color:var(--pink-dark)}.final-cta{text-align:center;padding:120px 0}.final-cta h2{font-size:clamp(2.3rem,5vw,4.2rem);max-width:820px;margin:auto}.final-cta p{color:var(--muted);font-size:1.1rem}.footer{padding:30px 0 50px;color:var(--muted);border-top:1px solid var(--line)}.footer-inner{display:flex;justify-content:space-between;gap:20px}.site-hero{text-align:center;padding:70px 0 45px}.site-hero h1{margin:14px auto 0}.memory-grid,.event-grid{display:grid;grid-template-columns:repeat(3,1fr);gap:15px}.content-grid{display:grid;grid-template-columns:repeat(2,1fr);gap:15px}.memory{overflow:hidden;padding:0}.memory img{width:100%;aspect-ratio:4/3;object-fit:cover;display:block;background:#ffe6f0}.memory-body{padding:18px}.event-date{color:var(--pink-dark);font-size:1.4rem;font-weight:900;margin-top:12px}@media(max-width:900px){.hero-grid{grid-template-columns:1fr}.preview{max-width:570px;margin:auto}.features,.steps,.memory-grid,.event-grid{grid-template-columns:1fr 1fr}.hide-mobile{display:none}}@media(max-width:620px){.shell{width:min(100% - 26px,1180px)}.nav-inner{height:68px}.brand span:last-child,.locale-switch{display:none}.hero{padding-top:55px}.features,.steps,.memory-grid,.event-grid,.content-grid{grid-template-columns:1fr}.price{grid-template-columns:1fr;padding:28px}.section{padding:76px 0}.footer-inner{flex-direction:column}.nav-actions{gap:6px}.button{padding:0 14px}}
`;
