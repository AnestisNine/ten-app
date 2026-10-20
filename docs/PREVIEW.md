# Γρήγορη δοκιμή (preview) σε δικό σου υπολογιστή

Τρέχει όλη την εφαρμογή (app + βάση) με δεδομένα επίδειξης. Χρειάζεται μόνο Docker.

## 1. Εγκατάσταση Docker

- macOS / Windows: [Docker Desktop](https://www.docker.com/products/docker-desktop/) → εγκατάσταση → άνοιγμα.
- Linux: <https://docs.docker.com/engine/install/>

## 2. Πρόσβαση στο image (μία φορά)

Το image είναι private στο GitHub. Φτιάξε token: GitHub → Settings → Developer settings → Personal access tokens →
**Tokens (classic)** → Generate new token → μόνο το scope **`read:packages`**. Μετά, σε terminal:

```bash
docker login ghcr.io -u AnestisNine      # ως password βάλε το token
```

## 3. Αρχεία

Από το GitHub: **Code → Download ZIP**, αποσυμπίεσε, και άνοιξε terminal μέσα στον φάκελο. Έπειτα:

```bash
docker run --rm node:22-alpine node -e "
const r=(n)=>require('crypto').randomBytes(n).toString('base64');
console.log('APP_URL=http://localhost:8080');
console.log('POSTGRES_PASSWORD='+r(18).replace(/[^A-Za-z0-9]/g,''));
console.log('AUTH_SECRET='+r(48));
console.log('DATA_ENCRYPTION_KEY='+r(32));
console.log('SEED_PASSWORD=demo-'+r(9).replace(/[^A-Za-z0-9]/g,''));
console.log('ALLOW_DEMO_SEED=1');" > .env
```

## 4. Εκκίνηση + δεδομένα επίδειξης

```bash
docker compose up -d app
docker compose exec app node dist/db/seed.js
```

Άνοιξε το <http://localhost:8080>. Χρήστες: `member@tbn.local`, `admin@tbn.local`, `manager@tbn.local`,
`accountant@tbn.local`, `merch@tbn.local`, `pos@tbn.local`, `social@tbn.local`, με κωδικό την τιμή `SEED_PASSWORD`
του `.env`. Ο admin, ο manager, ο λογιστής και ο social θα σου ζητήσουν 2FA (θέλει Google Authenticator ή παρόμοιο).

## 5. (Προαιρετικά) Link για να το δουν κι άλλοι, χωρίς domain

```bash
docker run --rm --network tbn_default cloudflare/cloudflared:2026.10.0 tunnel --no-autoupdate --url http://app:8080
```

Θα εμφανίσει μια διεύθυνση `https://....trycloudflare.com`. Βάλ' την στο `APP_URL=` του `.env`, μετά τρέξε
`docker compose up -d app` (σε άλλο terminal, ενώ το tunnel μένει ανοιχτό) και άνοιξε το link.
Το link ισχύει όσο τρέχει η εντολή. Είναι για δοκιμή μόνο: για μόνιμη χρήση ακολουθεί το `OPERATIONS.md`
(domain + Cloudflare Tunnel + Access).

## Τέλος δοκιμής

```bash
docker compose down -v      # σβήνει και τα δεδομένα επίδειξης
```
