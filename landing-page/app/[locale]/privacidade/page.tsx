import type { Metadata } from 'next';
import Link from 'next/link';
import { getPrivacyPolicy, siteOrigin } from '@/lib/api';
import { copy, localePath, locales, resolveLocale } from '@/lib/i18n';

type PageProps = {
  params: Promise<{ locale: string }>;
};

export const revalidate = 300;

export function generateStaticParams() {
  return locales.map((locale) => ({ locale }));
}

export async function generateMetadata({
  params,
}: PageProps): Promise<Metadata> {
  const locale = resolveLocale((await params).locale);
  const t = copy[locale];
  const policy = await getPrivacyPolicy(locale);
  const title = policy?.title ?? t.privacyPage.title;
  const path = localePath(locale, '/privacidade');
  return {
    title,
    description: t.privacyPage.description,
    robots: policy ? undefined : { index: false, follow: false },
    alternates: {
      canonical: `${siteOrigin}${path}`,
      languages: Object.fromEntries(
        locales.map((item) => [
          copy[item].htmlLang,
          `${siteOrigin}/${item}/privacidade`,
        ]),
      ),
    },
    openGraph: {
      title,
      description: t.privacyPage.description,
      url: `${siteOrigin}${path}`,
      type: 'article',
    },
  };
}

export default async function PrivacyPage({ params }: PageProps) {
  const locale = resolveLocale((await params).locale);
  const t = copy[locale];
  const policy = await getPrivacyPolicy(locale);

  return (
    <main className="legal-page">
      <header className="legal-header">
        <Link href={localePath(locale)} className="brand">
          <span className="brand-mark">NF</span>
          <span>{t.brand}</span>
        </Link>
      </header>
      <article className="legal-document">
        <Link className="legal-back" href={localePath(locale)}>
          {t.privacyPage.back}
        </Link>
        {policy ? (
          <>
            <p className="eyebrow">
              {formatDate(policy.updatedAt, copy[locale].htmlLang)}
            </p>
            <h1>{policy.title}</h1>
            <DocumentBody body={policy.body} format={policy.format} />
          </>
        ) : (
          <>
            <p className="eyebrow">{t.privacyPage.title}</p>
            <h1>{t.privacyPage.missingTitle}</h1>
            <p className="legal-empty">{t.privacyPage.missingBody}</p>
          </>
        )}
      </article>
    </main>
  );
}

function DocumentBody({
  body,
  format,
}: {
  body: string;
  format: 'plain' | 'markdown';
}) {
  if (format === 'markdown') {
    return (
      <div className="document-body">
        {body.split('\n').map((line, index) => {
          const trimmed = line.trim();
          if (!trimmed) return <div className="document-gap" key={index} />;
          if (trimmed.startsWith('### ')) {
            return <h3 key={index}>{trimmed.slice(4)}</h3>;
          }
          if (trimmed.startsWith('## ')) {
            return <h2 key={index}>{trimmed.slice(3)}</h2>;
          }
          if (trimmed.startsWith('# ')) {
            return <h2 key={index}>{trimmed.slice(2)}</h2>;
          }
          if (trimmed.startsWith('- ')) {
            return <p key={index}>- {trimmed.slice(2)}</p>;
          }
          return <p key={index}>{trimmed}</p>;
        })}
      </div>
    );
  }

  return (
    <div className="document-body">
      {body.split(/\n{2,}/).map((paragraph, index) => (
        <p key={index}>{paragraph.trim()}</p>
      ))}
    </div>
  );
}

function formatDate(value: string, locale: string) {
  return new Intl.DateTimeFormat(locale, { dateStyle: 'long' }).format(
    new Date(value),
  );
}
