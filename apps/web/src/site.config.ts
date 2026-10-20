/**
 * Band content that is not (yet) managed in the app. Empty links are hidden on the site.
 * Fill in the real URLs; nothing else needs to change.
 */
export const site = {
  name: 'The Bonnie Nettles',
  /** Internal app / API, reached through Cloudflare Tunnel. Override with PUBLIC_API_URL at build time. */
  apiUrl: import.meta.env.PUBLIC_API_URL ?? 'https://app.thebonnienettles.com',
  email: 'info@thebonnienettles.com',
  bookingEmail: 'booking@thebonnienettles.com',
  /** Merch is sold on Bandcamp until online payments are switched on. */
  bandcampUrl: '',
  social: {
    instagram: '',
    facebook: '',
    tiktok: '',
    youtube: '',
    spotify: '',
    bandcamp: '',
    appleMusic: '',
  },
  /** Newest first. `cover` is a file in public/images/ (optional). */
  releases: [] as { title: string; year: number; type: string; cover?: string; links: Record<string, string> }[],
};
