import { notFound } from 'next/navigation';
import Link from 'next/link';
import { Nav } from '@/components/nav';
import { copy, isLocale } from '@/lib/i18n';

const features = ['memories','playlist','letters','journey','shared','safe'] as const;
const icons = ['📷','♫','💌','🌿','💬','🔐'];

export default async function Landing({ params }: { params: Promise<{ locale: string }> }) {
  const { locale: raw } = await params;
  if (!isLocale(raw)) notFound();
  const t = copy[raw];
  return <>
    <Nav locale={raw}/>
    <main>
      <section className="hero"><div className="shell hero-grid">
        <div><span className="eyebrow">♥ {t.eyebrow}</span><h1>{t.heroTitle}</h1><p className="lead">{t.heroBody}</p>
          <div className="hero-actions"><Link className="button primary" href={`/${raw}/signup`}>{t.primaryCta} →</Link><Link className="button ghost" href={`/${raw}/demo`}>{t.secondaryCta}</Link></div>
        </div>
        <div className="preview"><div className="preview-head"><small>{t.brand}</small><h3>Amor que floresce</h3></div><div className="preview-cards">
          {features.slice(0,4).map((key,index)=><div className="mini-card" key={key}><span>{icons[index]}</span><strong>{t[key]}</strong></div>)}
        </div></div>
      </div><div className="flower-field"/></section>
      <section className="section"><div className="shell"><div className="section-heading"><h2>{t.sectionTitle}</h2><p>{t.sectionBody}</p></div><div className="features">
        {features.map((key,index)=><article className="card" key={key}><div className="feature-icon">{icons[index]}</div><h3>{t[key]}</h3><p>{t.sectionBody}</p></article>)}
      </div></div></section>
      <section className="section"><div className="shell"><div className="section-heading"><h2>{t.howTitle}</h2></div><div className="steps">
        {t.steps.map(step=><article className="card" key={step[0]}><div className="step-number">{step[0]}</div><h3>{step[1]}</h3><p>{step[2]}</p></article>)}
      </div></div></section>
      <section className="section"><div className="shell"><div className="price"><div><h2>{t.priceTitle}</h2><p>{t.priceBody}</p></div><Link className="button" href={`/${raw}/signup`}>{t.priceCta} →</Link></div></div></section>
      <section className="final-cta"><div className="shell"><h2>{t.finalTitle}</h2><p>{t.finalBody}</p><Link className="button primary" href={`/${raw}/signup`}>{t.primaryCta}</Link></div></section>
    </main>
    <footer className="footer"><div className="shell footer-inner"><span>🌸 {t.brand}</span><span>{t.footer}</span></div></footer>
  </>;
}

