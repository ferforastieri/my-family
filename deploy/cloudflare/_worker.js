function backendUrl(env) {
  if (!env.RAILWAY_BACKEND_URL) {
    throw new Error('RAILWAY_BACKEND_URL não configurada no Cloudflare Pages');
  }
  const url = new URL(env.RAILWAY_BACKEND_URL);
  if (url.protocol !== 'https:') {
    throw new Error('RAILWAY_BACKEND_URL deve usar HTTPS');
  }
  return url;
}

function isAppNavigation(request, url) {
  if (request.method !== 'GET' && request.method !== 'HEAD') return false;
  if (url.pathname === '/app/') return true;
  const lastSegment = url.pathname.split('/').pop() || '';
  return !lastSegment.includes('.');
}

export default {
  async fetch(request, env) {
    const publicUrl = new URL(request.url);

    if (publicUrl.pathname === '/app') {
      return Response.redirect(`${publicUrl.origin}/app/`, 308);
    }

    if (publicUrl.pathname.startsWith('/app/')) {
      if (isAppNavigation(request, publicUrl)) {
        const indexUrl = new URL('/app/index.html', publicUrl.origin);
        return env.ASSETS.fetch(new Request(indexUrl, request));
      }
      return env.ASSETS.fetch(request);
    }

    try {
      const origin = backendUrl(env);
      const target = new URL(`${publicUrl.pathname}${publicUrl.search}`, origin);
      const proxyRequest = new Request(target, request);
      const clientIp = request.headers.get('cf-connecting-ip');

      proxyRequest.headers.set('x-forwarded-host', publicUrl.host);
      proxyRequest.headers.set(
        'x-forwarded-proto',
        publicUrl.protocol.replace(':', ''),
      );
      if (clientIp) {
        proxyRequest.headers.set('x-forwarded-for', clientIp);
        proxyRequest.headers.set('x-real-ip', clientIp);
      }

      return fetch(proxyRequest);
    } catch (error) {
      console.error('Falha ao encaminhar requisição para o Railway', error);
      return new Response('Serviço temporariamente indisponível.', {
        status: 502,
        headers: { 'content-type': 'text/plain; charset=utf-8' },
      });
    }
  },
};
