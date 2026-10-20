import type { APIRoute } from 'astro';
import { site } from '../site.config';

/** Blocks crawlers until the site is launched (site.launched). */
export const GET: APIRoute = () =>
  new Response(site.launched ? 'User-agent: *\nAllow: /\n' : 'User-agent: *\nDisallow: /\n', {
    headers: { 'Content-Type': 'text/plain; charset=utf-8' },
  });
