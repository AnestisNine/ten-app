# Εγκατάσταση & λειτουργία (server, Cloudflare Tunnel, backups)

Οδηγός για να τρέξει το TBN Manager στον δικό σας server, προσβάσιμο από το internet μόνο μέσω
Cloudflare Tunnel (χωρίς ανοιχτά ports στο router).

```
 κινητό / laptop ──HTTPS──▶ Cloudflare (Access + TLS) ──tunnel──▶ cloudflared ──▶ app:8080 ──▶ db (Postgres)
                                                                   (όλα στον server, σε Docker)
```

## 1. Τι χρειάζεται ο server

- Linux (π.χ. Ubuntu 24.04 / Debian 12) ή macOS, ≥ 2 GB RAM, ~10 GB δίσκο.
- Docker Engine + Docker Compose plugin: <https://docs.docker.com/engine/install/>
- Κρυπτογράφηση δίσκου (LUKS / FileVault) — εκεί μένει η βάση.
- Αυτόματες ενημερώσεις ασφαλείας του λειτουργικού (π.χ. `unattended-upgrades`).

## 2. GitHub & image

1. Δημιουργήστε ένα **private** repository (π.χ. `tbn-platform`) και ανεβάστε τον κώδικα.
2. Σε κάθε push στο `main`, το GitHub Actions τρέχει τα tests και φτιάχνει το image
   `ghcr.io/<owner>/tbn-manager:latest` (και `:sha-xxxxxxx`).
3. Στον server, συνδεθείτε στο GHCR με ένα Personal Access Token που έχει μόνο `read:packages`:
   ```bash
   echo <TOKEN> | docker login ghcr.io -u <github-user> --password-stdin
   ```

## 3. Ρύθμιση

```bash
git clone https://github.com/<owner>/tbn-platform.git && cd tbn-platform
cp .env.example .env
```

Συμπληρώστε στο `.env`:

| Μεταβλητή | Τιμή |
|---|---|
| `APP_URL` | η δημόσια διεύθυνση, π.χ. `https://app.thebonnienettles.com` |
| `POSTGRES_PASSWORD` | τυχαίο: `openssl rand -base64 24` |
| `AUTH_SECRET` | `openssl rand -base64 48` |
| `DATA_ENCRYPTION_KEY` | `openssl rand -base64 32` — **κρατήστε αντίγραφο εκτός server** (password manager). Χωρίς αυτό τα κρυπτογραφημένα στοιχεία μελών χάνονται. |
| `SMTP_URL`, `MAIL_FROM` | λογαριασμός αποστολής email (για προσκλήσεις / επαναφορά κωδικού) |
| `CLOUDFLARE_TUNNEL_TOKEN` | από το βήμα 4 |
| `TBN_IMAGE` | `ghcr.io/<owner>/tbn-manager:latest` |

`TRUSTED_ORIGINS` αφήστε το κενό στην παραγωγή.

## 4. Cloudflare Tunnel

Στο Cloudflare dashboard → **Zero Trust → Networks → Tunnels → Create a tunnel** (τύπος *Cloudflared*):

1. Όνομα π.χ. `tbn-server`. Στο βήμα εγκατάστασης επιλέξτε **Docker** και αντιγράψτε μόνο το token
   (το μεγάλο κείμενο μετά το `--token`) στο `CLOUDFLARE_TUNNEL_TOKEN` του `.env`.
2. Προσθέστε hostname: `app.<domain>` → Service `HTTP` → URL `app:8080`.

(Οι ονομασίες των μενού του Cloudflare αλλάζουν κατά καιρούς· η λογική μένει ίδια.)

## 5. Cloudflare Access (δεύτερο επίπεδο πρόσβασης)

**Zero Trust → Access → Applications → Add an application → Self-hosted**

1. Εφαρμογή «TBN Manager», domain `app.<domain>`, policy **Allow** με **Emails**: τα email των εγκεκριμένων χρηστών.
   Μόνο αυτοί βλέπουν καν τη σελίδα σύνδεσης (Access στέλνει κωδικό στο email τους).
2. Δεύτερη εφαρμογή για το `app.<domain>/ical` με policy **Bypass** (Everyone): τα ημερολόγια
   (Google/Apple) δεν μπορούν να περάσουν από Access. Τα feeds προστατεύονται από το μυστικό token τους.
3. Αν χρησιμοποιηθεί το native iOS app: τρίτη εφαρμογή **Bypass** για `app.<domain>/api`. Τότε το API
   προστατεύεται μόνο από το δικό μας login + 2FA + rate limiting (το web app συνεχίζει να περνά από Access).

## 6. Εκκίνηση

```bash
docker compose pull
docker compose --profile tunnel up -d
docker compose logs -f app        # "TBN API listening on :8080"
```

Οι migrations της βάσης τρέχουν αυτόματα σε κάθε εκκίνηση.

Πρώτος admin (στέλνει email πρόσκλησης· χωρίς SMTP το link εμφανίζεται στα logs):

```bash
docker compose exec app node dist/tools/create-user.js --email you@example.com --name "Το όνομά σου" --roles admin
```

Ο admin ορίζει κωδικό από το link, μπαίνει, ενεργοποιεί 2FA (υποχρεωτικό) και προσκαλεί τους υπόλοιπους από
**Menu → Χρήστες**.

## 7. Backups

Το service `backup` κρατά κάθε 24 ώρες dump της βάσης + τα ανεβασμένα αρχεία στο `./backups` (14 μέρες).
**Αυτό δεν αρκεί**: αντιγράψτε το `./backups` εκτός server, κρυπτογραφημένο. Παράδειγμα με
[rclone](https://rclone.org) σε cloud storage με crypt remote, σε cron του host:

```cron
30 4 * * *  rclone sync /opt/tbn-platform/backups tbn-crypt:backups
```

Επαναφορά (δοκιμάστε την μία φορά τώρα, όχι την ημέρα που θα τη χρειαστείτε):

```bash
docker compose stop app
docker compose exec -T db pg_restore -U tbn -d tbn --clean --if-exists < backups/db-YYYYMMDD-HHMMSS.dump
docker compose run --rm -v ./backups:/b app sh -c 'tar -xzf /b/files-YYYYMMDD-HHMMSS.tar.gz -C /data/files'
docker compose start app
```

Μαζί με τα backups χρειάζεται και το `DATA_ENCRYPTION_KEY` (βήμα 3).

## 8. Ενημερώσεις

```bash
docker compose pull && docker compose --profile tunnel up -d
```

Για επιστροφή σε προηγούμενη έκδοση: `TBN_IMAGE=ghcr.io/<owner>/tbn-manager:sha-xxxxxxx` στο `.env` και ξανά `up -d`.
(Οι migrations δεν αναιρούνται αυτόματα — πριν από μεγάλες ενημερώσεις κρατήστε ένα πρόσφατο backup.)

## 9. Έλεγχος ασφαλείας (checklist)

- [ ] Κανένα port του server ανοιχτό προς το internet (το app ακούει μόνο στο `127.0.0.1:8080`).
- [ ] Cloudflare Access ενεργό για `app.<domain>`, με λίστα εγκεκριμένων email.
- [ ] `.env` με δικαιώματα `600`, εκτός git· αντίγραφο του `DATA_ENCRYPTION_KEY` σε password manager.
- [ ] Backups εκτός server + δοκιμασμένη επαναφορά.
- [ ] Κρυπτογραφημένος δίσκος, αυτόματες ενημερώσεις λειτουργικού.
- [ ] 2FA ενεργό σε admin / manager / λογιστή / social (το app το επιβάλλει).
- [ ] Όταν φεύγει κάποιος: **Menu → Χρήστες → Απενεργοποίηση** (κόβει αμέσως όλες τις συσκευές του) και αφαίρεση
      από τη λίστα του Cloudflare Access.
- [ ] Dependabot PRs (εβδομαδιαία) ελέγχονται και γίνονται merge.
