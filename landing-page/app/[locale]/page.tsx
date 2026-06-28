import type { Metadata } from 'next';
import Link from 'next/link';
import { HeroScene } from '@/components/HeroScene';
import { appOrigin, getLandingData, siteOrigin } from '@/lib/api';
import { Locale, copy, localePath, locales, resolveLocale } from '@/lib/i18n';

type PageProps = {
  params: Promise<{ locale: string }>;
};

export const dynamic = 'force-dynamic';

export async function generateMetadata({
  params,
}: PageProps): Promise<Metadata> {
  const locale = resolveLocale((await params).locale);
  const t = copy[locale];
  const path = localePath(locale);
  return {
    title: t.seo.title,
    description: t.seo.description,
    alternates: {
      canonical: `${siteOrigin}${path}`,
      languages: Object.fromEntries(
        locales.map((item) => [copy[item].htmlLang, `${siteOrigin}/${item}`]),
      ),
    },
    openGraph: {
      title: t.seo.title,
      description: t.seo.description,
      url: `${siteOrigin}${path}`,
      siteName: t.brand,
      locale: t.htmlLang,
      type: 'website',
    },
    twitter: {
      card: 'summary_large_image',
      title: t.seo.title,
      description: t.seo.description,
    },
  };
}

export default async function LandingPage({ params }: PageProps) {
  const locale = resolveLocale((await params).locale);
  const t = copy[locale];
  const data = await getLandingData(locale);
  const signupUrl = `${appOrigin}/signup?locale=${locale}`;
  const loginUrl = `${appOrigin}/login/cliente?locale=${locale}`;
  const demoUrl = `${appOrigin}/demo?locale=${locale}`;

  return (
    <main>
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{
          __html: JSON.stringify(buildJsonLd(locale, data.plans)),
        }}
      />
      <section className="hero">
        <HeroScene />
        <div className="hero-grid-layer" />
        <header className="site-header" aria-label="Principal">
          <Link href={localePath(locale)} className="brand">
            <span className="brand-mark">NF</span>
            <span>{t.brand}</span>
          </Link>
          <nav className="top-nav" aria-label="Navegação">
            <a href="#produto">{t.navProduct}</a>
            <a href="#planos">{t.navPlans}</a>
            <Link href={localePath(locale, '/privacidade')}>
              {t.navPrivacy}
            </Link>
            <a href={loginUrl}>{t.navLogin}</a>
            <a className="nav-action" href={signupUrl}>
              {t.navSignup}
            </a>
          </nav>
        </header>
        <div className="hero-content">
          <p className="eyebrow">{t.eyebrow}</p>
          <h1>{t.title}</h1>
          <p className="hero-copy">{t.description}</p>
          <div className="hero-actions">
            <a className="button primary" href={signupUrl}>
              {t.primaryCta}
            </a>
            <a className="button secondary" href={demoUrl}>
              {t.secondaryCta}
            </a>
          </div>
          <p className="trust-line">{t.trustLine}</p>
        </div>
      </section>

      <section className="proof-band" aria-label="Destaques">
        <div className="proof-grid">
          {t.proofItems.map((item) => (
            <span key={item}>{item}</span>
          ))}
        </div>
      </section>

      <section className="section product-section" id="produto">
        <div className="section-heading">
          <p className="eyebrow">{t.featureTitle}</p>
          <h2>{t.featureDescription}</h2>
        </div>
        <div className="feature-grid">
          {t.features.map((item) => (
            <article className="feature-card" key={item.title}>
              <h3>{item.title}</h3>
              <p>{item.body}</p>
            </article>
          ))}
        </div>
      </section>

      <section className="section plans-section" id="planos">
        <div className="section-heading">
          <p className="eyebrow">{t.plansEyebrow}</p>
          <h2>{t.plansTitle}</h2>
          <p>{t.plansDescription}</p>
        </div>
        {data.plans.length ? (
          <div className="plans-grid">
            {data.plans.map((plan) => (
              <article
                className={`plan-card${plan.highlighted ? ' highlighted' : ''}`}
                key={plan.id}
              >
                {plan.highlighted ? (
                  <span className="plan-badge">{t.highlighted}</span>
                ) : null}
                <h3>{plan.name}</h3>
                <p>{plan.description}</p>
                <div className="price-row">
                  <strong>
                    {formatPrice(plan.priceCents, plan.currency, locale)}
                  </strong>
                  <span>{t.interval[plan.interval] ?? plan.interval}</span>
                </div>
                <a
                  className="button plan-button"
                  href={`${signupUrl}&plan=${plan.interval}`}
                >
                  {t.choosePlan}
                </a>
              </article>
            ))}
          </div>
        ) : (
          <p className="empty-state">{t.plansEmpty}</p>
        )}
      </section>

      <section className="section privacy-section" id="privacidade">
        <div className="privacy-copy">
          <p className="eyebrow">{t.privacyEyebrow}</p>
          <h2>{t.privacyTitle}</h2>
          <p>{t.privacyDescription}</p>
          {data.privacyPolicy ? (
            <p className="document-date">
              {t.privacyUpdated}{' '}
              {formatDate(data.privacyPolicy.updatedAt, locale)}
            </p>
          ) : (
            <p className="document-date">{t.privacyMissing}</p>
          )}
        </div>
        <Link className="button secondary" href={localePath(locale, '/privacidade')}>
          {t.privacyOpen}
        </Link>
      </section>
    </main>
  );
}

function formatPrice(priceCents: number, currency: string, locale: Locale) {
  return new Intl.NumberFormat(copy[locale].htmlLang, {
    style: 'currency',
    currency,
  }).format(priceCents / 100);
}

function formatDate(value: string, locale: Locale) {
  return new Intl.DateTimeFormat(copy[locale].htmlLang, {
    dateStyle: 'medium',
  }).format(new Date(value));
}

function buildJsonLd(
  locale: Locale,
  plans: Awaited<ReturnType<typeof getLandingData>>['plans'],
) {
  return {
    '@context': 'https://schema.org',
    '@type': 'SoftwareApplication',
    name: copy[locale].brand,
    applicationCategory: 'LifestyleApplication',
    operatingSystem: 'Android, iOS, Web',
    url: `${siteOrigin}/${locale}`,
    description: copy[locale].seo.description,
    offers: plans.map((plan) => ({
      '@type': 'Offer',
      name: plan.name,
      price: (plan.priceCents / 100).toFixed(2),
      priceCurrency: plan.currency,
      url: `${siteOrigin}/${locale}#planos`,
    })),
  };
}
