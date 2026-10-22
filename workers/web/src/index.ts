import api, { TenantRealtime, RateLimiter } from '../../api/src/index';
import type { Env as ApiEnv } from '../../api/src/env';

export { TenantRealtime, RateLimiter };

interface Env extends ApiEnv {
  ASSETS: Fetcher;
}

const crawlerPattern =
  /(googlebot|google-inspectiontool|bingbot|duckduckbot|yandex|baiduspider|applebot|facebookexternalhit|twitterbot|linkedinbot|slackbot|discordbot|telegrambot|whatsapp)/i;

function isCrawler(request: Request): boolean {
  return crawlerPattern.test(request.headers.get('user-agent') ?? '');
}

function dynamicRoot(response: Response): Response {
  const headers = new Headers(response.headers);
  headers.set('vary', 'User-Agent');
  headers.set('cache-control', 'no-store');
  return new Response(response.body, {
    status: response.status,
    statusText: response.statusText,
    headers,
  });
}

export default {
  async fetch(request: Request, env: Env, ctx: ExecutionContext): Promise<Response> {
    const url = new URL(request.url);
    if (
      url.pathname === '/api' ||
      url.pathname.startsWith('/api/') ||
      url.pathname === '/ws'
    ) {
      return api.fetch(request, env, ctx);
    }

    // The landing is Flutter for people and a pre-rendered HTML equivalent for
    // crawlers. Both are served from the same public URL and contain the same
    // content; the HTML file is never exposed as a separate public page.
    if (url.pathname === '/') {
      if (isCrawler(request)) {
        return dynamicRoot(
          await env.ASSETS.fetch(
            new Request(new URL('/seo/', request.url), request),
          ),
        );
      }
      return dynamicRoot(await env.ASSETS.fetch(request));
    }
    if (url.pathname === '/termos' || url.pathname === '/termos/') {
      return Response.redirect(new URL('/#/termos', url).toString(), 308);
    }
    if (
      url.pathname === '/privacidade' ||
      url.pathname === '/privacidade/'
    ) {
      return Response.redirect(new URL('/#/privacidade', url).toString(), 308);
    }
    if (url.pathname === '/seo' || url.pathname.startsWith('/seo/')) {
      return new Response('Not found', { status: 404 });
    }

    // The authenticated app used to live under /app. Keep old links working
    // without maintaining a second copy.
    if (url.pathname === '/app' || url.pathname.startsWith('/app/')) {
      return Response.redirect(new URL('/', url).toString(), 308);
    }

    return env.ASSETS.fetch(request);
  },
  async queue(batch: MessageBatch<unknown>, env: Env): Promise<void> {
    return api.queue(batch, env);
  },
  async scheduled(
    controller: ScheduledController,
    env: Env,
    ctx: ExecutionContext,
  ): Promise<void> {
    return api.scheduled(controller, env, ctx);
  },
} satisfies ExportedHandler<Env>;
