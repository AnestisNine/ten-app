/**
 * Band content that is not (yet) managed in the app. Empty links are hidden on the site.
 * Fill in the real URLs; nothing else needs to change.
 */
export const site = {
  name: 'The Bonnie Nettles',
  /** false = pre-launch: search engines are told not to index the site. Set to true when going live. */
  launched: false,
  /** Internal app / API, reached through Cloudflare Tunnel. Override with PUBLIC_API_URL at build time. */
  apiUrl: import.meta.env.PUBLIC_API_URL ?? 'https://app.thebonnienettles.com',
  email: 'info@thebonnienettles.com',
  bookingEmail: 'booking@thebonnienettles.com',
  /** Merch is sold on Bandcamp until online payments are switched on. */
  bandcampUrl: 'https://thebonnienettles.bandcamp.com/merch',
  social: {
    instagram: 'https://www.instagram.com/thebonnienettles/',
    facebook: '',
    tiktok: '',
    youtube: '',
    spotify: 'https://open.spotify.com/artist/6ljLzYBRit1D6m43dAOGC8',
    bandcamp: 'https://thebonnienettles.bandcamp.com',
    appleMusic: '',
  },
  /**
   * Shows listed on the site while the app's server is not online yet. As soon as the app answers,
   * its confirmed shows replace this list — from then on add shows in the app (with ticket link + poster).
   * `poster` is a file in public/images/posters/ (optional); `ticketUrl` is the ticket page (e.g. more.com).
   */
  shows: [
    {
      date: '2026-12-12',
      city: 'Athens',
      venue: 'Ilion Plus',
      country: 'Greece',
      support: '',
      ticketUrl: '',
      poster: '',
    },
  ] as { date: string; city: string; venue: string; country: string; support: string; ticketUrl: string; poster: string }[],
  /** Newest first. `cover` is a file in public/images/; year/type are shown when filled in. */
  releases: [
    {
      title: 'Drift Like Home',
      links: { Bandcamp: 'https://thebonnienettles.bandcamp.com/track/drift-like-home' },
    },
  ] as { title: string; year?: number; type?: string; cover?: string; links: Record<string, string> }[],
};
