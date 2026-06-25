import { Controller, Get, Param, Req, Res } from '@nestjs/common';
import type { Request, Response } from 'express';
import { PublicSiteService } from '../public-site/public-site.service';
import { Public } from '@auth/decorators/public.decorator';
import {
  isMarketingLocale,
  marketingCss,
  renderFamilySite,
  renderLanding,
} from './marketing.page';

@Controller()
@Public()
export class MarketingController {
  constructor(private readonly publicSites: PublicSiteService) {}

  @Get()
  root(@Res() response: Response) {
    return response.redirect(308, '/pt');
  }

  @Get(['pt', 'en', 'es'])
  landing(@Req() request: Request, @Res() response: Response) {
    const locale = request.path.replace(/^\//, '');
    if (!isMarketingLocale(locale)) return response.redirect(308, '/pt');
    return response
      .type('html')
      .set('Cache-Control', 'public, max-age=300, stale-while-revalidate=86400')
      .send(renderLanding(locale, requestOrigin(request)));
  }

  @Get(['pt/familia/:slug', 'en/familia/:slug', 'es/familia/:slug'])
  async family(
    @Param('slug') slug: string,
    @Req() request: Request,
    @Res() response: Response,
  ) {
    const locale = request.path.split('/').filter(Boolean)[0];
    if (!isMarketingLocale(locale)) return response.redirect(308, '/pt');
    const site = await this.publicSites.bySlug(slug);
    return response
      .type('html')
      .set('Cache-Control', 'private, max-age=60')
      .send(renderFamilySite(locale, requestOrigin(request), site));
  }

  @Get('marketing.css')
  styles(@Res() response: Response) {
    return response
      .type('text/css')
      .set('Cache-Control', 'public, max-age=86400')
      .send(marketingCss);
  }

  @Get('robots.txt')
  robots(@Req() request: Request, @Res() response: Response) {
    return response
      .type('text/plain')
      .send(
        `User-agent: *\nAllow: /\nDisallow: /app/\nDisallow: /api/\nSitemap: ${requestOrigin(request)}/sitemap.xml\n`,
      );
  }

  @Get('sitemap.xml')
  async sitemap(@Req() request: Request, @Res() response: Response) {
    const origin = requestOrigin(request);
    const slugs = await this.publicSites.publishedSlugs();
    const paths = [
      ...['pt', 'en', 'es'],
      ...slugs.flatMap((slug) =>
        ['pt', 'en', 'es'].map(
          (locale) => `${locale}/familia/${encodeURIComponent(slug)}`,
        ),
      ),
    ];
    const urls = paths
      .map((path) => `<url><loc>${origin}/${path}</loc></url>`)
      .join('');
    return response
      .type('application/xml')
      .send(
        `<?xml version="1.0" encoding="UTF-8"?><urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">${urls}</urlset>`,
      );
  }
}

function requestOrigin(request: Request) {
  const forwarded = request.get('x-forwarded-proto')?.split(',')[0]?.trim();
  const forwardedHost = request.get('x-forwarded-host')?.split(',')[0]?.trim();
  const protocol = forwarded || request.protocol;
  return `${protocol}://${forwardedHost || request.get('host')}`;
}
