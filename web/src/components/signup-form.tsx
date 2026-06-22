'use client';

import { FormEvent, useMemo, useState } from 'react';
import { copy, type Locale } from '@/lib/i18n';
import { publicApi } from '@/lib/api';

export function SignupForm({ locale }: { locale: Locale }) {
  const t = copy[locale];
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const apiLocale = useMemo(() => locale === 'pt' ? 'pt-BR' : locale, [locale]);

  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault(); setLoading(true); setError('');
    const form = new FormData(event.currentTarget);
    const body = {
      name: form.get('name'), email: form.get('email'), password: form.get('password'),
      familyName: form.get('familyName'), slug: form.get('slug') || undefined, locale: apiLocale,
    };
    try {
      const registerResponse = await fetch(`${publicApi}/auth/register`, { method:'POST', headers:{'content-type':'application/json'}, body:JSON.stringify(body) });
      const registerPayload = await registerResponse.json();
      if (!registerResponse.ok) throw new Error(registerPayload.message || t.signupError);
      const registration = registerPayload.data ?? registerPayload;
      localStorage.setItem('access_token', registration.accessToken);
      localStorage.setItem('refresh_token', registration.refreshToken);
      const checkoutResponse = await fetch(`${publicApi}/billing/checkout`, { method:'POST', headers:{authorization:`Bearer ${registration.accessToken}`} });
      const checkoutPayload = await checkoutResponse.json();
      if (!checkoutResponse.ok) throw new Error(checkoutPayload.message || t.signupError);
      const checkout = checkoutPayload.data ?? checkoutPayload;
      if (!checkout.checkoutUrl) throw new Error(t.signupError);
      window.location.assign(checkout.checkoutUrl);
    } catch (reason) { setError(reason instanceof Error ? reason.message : t.signupError); setLoading(false); }
  }

  return <form onSubmit={submit} className="form-grid">
    <div className="field"><label htmlFor="name">{t.name}</label><input id="name" name="name" required autoComplete="name"/></div>
    <div className="field"><label htmlFor="email">{t.email}</label><input id="email" name="email" required type="email" autoComplete="email"/></div>
    <div className="field full"><label htmlFor="password">{t.password}</label><input id="password" name="password" required minLength={8} type="password" autoComplete="new-password"/></div>
    <div className="field"><label htmlFor="familyName">{t.familyName}</label><input id="familyName" name="familyName" required minLength={2}/></div>
    <div className="field"><label htmlFor="slug">{t.slug}</label><input id="slug" name="slug" minLength={3} pattern="[a-zA-Z0-9-]+" placeholder="familia-silva"/></div>
    <div className="field full"><button className="button primary" type="submit" disabled={loading}>{loading ? t.processing : t.signupButton}</button>{error && <div className="error">{error}</div>}</div>
  </form>;
}

