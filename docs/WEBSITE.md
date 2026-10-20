# Δημόσιο site — thebonnienettles.com

Στατικό site (Astro) στο Cloudflare Pages, ελληνικά στη ρίζα (`/`) και αγγλικά στο `/en`.
Οι συναυλίες (μόνο τα **επιβεβαιωμένα** lives) και το merch έρχονται αυτόματα από το app μέσω
`https://app.thebonnienettles.com/api/public/...`. Μέχρι να στηθεί ο server, το site δείχνει «δεν υπάρχουν
ανακοινωμένες συναυλίες» / «νέο merch σύντομα».

## Ανάρτηση (μία φορά, ~5 λεπτά)

1. Cloudflare dashboard → **Workers & Pages** → **Create** → καρτέλα **Pages** → **Connect to Git**.
2. Σύνδεσε το GitHub και διάλεξε το repository **ten-app**.
3. Ρυθμίσεις build:
   | Πεδίο | Τιμή |
   |---|---|
   | Project name | `thebonnienettles` |
   | Production branch | `main` |
   | Framework preset | `None` |
   | Build command | `npx pnpm@10.18.0 install --frozen-lockfile && npx pnpm@10.18.0 --filter @tbn/web build` |
   | Build output directory | `apps/web/dist` |
   | Root directory | *(κενό)* |
4. **Environment variables** → πρόσθεσε:
   - `NODE_VERSION` = `22`
   - `PUBLIC_API_URL` = `https://app.thebonnienettles.com`
5. **Save and Deploy**. Σε 1–2 λεπτά θα πάρεις μια διεύθυνση `https://thebonnienettles.pages.dev`.
6. Στο project → **Custom domains** → **Set up a custom domain** → `thebonnienettles.com` → Activate.
   Ξανά για `www.thebonnienettles.com`. Το Cloudflare φτιάχνει μόνο του τις εγγραφές DNS.

Από εκεί και πέρα, κάθε push στο `main` ανανεώνει αυτόματα το site.

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
