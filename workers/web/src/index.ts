interface Env {
  ASSETS: Fetcher;
  API: Fetcher;
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);
    if (
      url.pathname === '/api' ||
      url.pathname.startsWith('/api/') ||
      url.pathname === '/ws'
    ) {
      return env.API.fetch(request);
    }

    // The Flutter app lives under /app/. Its hash router never needs a
    // server-side route, but a direct /app or /app/foo should still boot it.
    if (url.pathname === '/app') {
      return Response.redirect(new URL('/app/', url).toString(), 308);
    }
    if (url.pathname.startsWith('/app/')) {
      const asset = await env.ASSETS.fetch(request);
      if (asset.status !== 404) return asset;
      return env.ASSETS.fetch(
        new Request(new URL('/app/index.html', request.url), request),
      );
    }

    // Everything else is the public, indexable landing page.
    return env.ASSETS.fetch(request);
  },
} satisfies ExportedHandler<Env>;
