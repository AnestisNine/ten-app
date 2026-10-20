# Δημόσιο site — thebonnienettles.com

Στατικό site (Astro) στο Cloudflare Pages, ελληνικά στη ρίζα (`/`) και αγγλικά στο `/en`.
Οι συναυλίες (μόνο τα **επιβεβαιωμένα** lives) και το merch έρχονται αυτόματα από το app μέσω
`https://app.thebonnienettles.com/api/public/...`. Μέχρι να στηθεί ο server, το site δείχνει «δεν υπάρχουν
ανακοινωμένες συναυλίες» / «νέο merch σύντομα».

## Ανάρτηση (Cloudflare Worker «ten-app»)

Το site ανεβαίνει ως Cloudflare Worker με static assets. Όλες οι ρυθμίσεις βρίσκονται στο `wrangler.jsonc`
(build command, φάκελος `apps/web/dist`, σελίδα 404) και στο `.node-version`.

1. Cloudflare → **Workers & Pages** → **Create application** → **Import a repository** → GitHub → **ten-app**.
   Τα πεδία build αφήνονται στις προεπιλογές (deploy command: `npx wrangler deploy`).
2. Κάθε push στο `main` ανανεώνει αυτόματα το site. Δοκιμαστική διεύθυνση: `https://ten-app.<subdomain>.workers.dev`.
3. Δικό σου domain: Worker **ten-app** → **Settings** → **Domains & Routes** → **Add** → **Custom domain** →
   `thebonnienettles.com`, και ξανά για `www.thebonnienettles.com`. Το Cloudflare φτιάχνει μόνο του το DNS.

Το API που διαβάζει το site είναι το `https://app.thebonnienettles.com` (`apps/web/src/site.config.ts`).

## Αλλαγές περιεχομένου

- Κείμενα (ελληνικά/αγγλικά): `apps/web/src/i18n.ts`
- Links (Instagram, Spotify, Bandcamp…), email, δισκογραφία: `apps/web/src/site.config.ts`
- Φωτογραφία κεντρικής εικόνας: βάλε `apps/web/public/images/hero.jpg` και ενεργοποίησε τη γραμμή στο
  `apps/web/src/pages/[...lang]/index.astro`
- Συναυλίες: από το app (status «Επιβεβαιωμένο» + «Link εισιτηρίων» στη σελίδα του live)
- Merch: από το app (Merch → Products). Το κουμπί «Αγορά στο Bandcamp» εμφανίζεται όταν συμπληρωθεί το `bandcampUrl`.

## Φόρμες

- **Επικοινωνία / booking**: αποθηκεύεται στο app και εμφανίζεται ως ειδοποίηση στους admin/manager.
- **Newsletter**: αποθηκεύεται με το κείμενο και την ώρα της συγκατάθεσης (GDPR). Επιβεβαίωση με email
  (double opt-in) και αποστολές θα ενεργοποιηθούν όταν ρυθμιστεί πάροχος email.

## Τοπική ανάπτυξη

```bash
pnpm --filter @tbn/web dev     # http://localhost:4321, με PUBLIC_API_URL=http://localhost:8080 για τοπικό API
```
Το API πρέπει να έχει `PUBLIC_SITE_ORIGINS=http://localhost:4321`.
