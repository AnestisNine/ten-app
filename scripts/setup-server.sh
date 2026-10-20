#!/bin/sh
# Creates .env for a production server with fresh random secrets.
#   sh scripts/setup-server.sh
set -eu
cd "$(dirname "$0")/.."

if [ -f .env ]; then
  echo "Υπάρχει ήδη .env — δεν το αλλάζω (τα secrets του χρειάζονται για τα υπάρχοντα δεδομένα)."
  exit 1
fi

rand() { openssl rand -base64 "$1" | tr -d '\n'; }
KEY=$(rand 32)

cat > .env <<ENV
NODE_ENV=production
APP_URL=https://app.thebonnienettles.com
TBN_IMAGE=ghcr.io/anestisnine/tbn-manager:latest
PUBLIC_SITE_ORIGINS=https://thebonnienettles.com,https://www.thebonnienettles.com

POSTGRES_PASSWORD=$(rand 24 | tr -dc 'A-Za-z0-9')
AUTH_SECRET=$(rand 48)
DATA_ENCRYPTION_KEY=$KEY

# Βάλε εδώ το token από Cloudflare → Zero Trust → Networks → Tunnels
CLOUDFLARE_TUNNEL_TOKEN=

# Email αποστολής (προσκλήσεις / επαναφορά κωδικού). Κενό = τα links εμφανίζονται στα logs.
SMTP_URL=
MAIL_FROM=TBN Manager <no-reply@thebonnienettles.com>
ENV
chmod 600 .env
mkdir -p backups

echo ""
echo "✓ Δημιουργήθηκε το .env"
echo ""
echo "ΣΗΜΑΝΤΙΚΟ: αποθήκευσε αυτό το κλειδί σε password manager (χωρίς αυτό, τα ευαίσθητα"
echo "στοιχεία μελών δεν ανακτώνται ποτέ αν χαθεί ο server):"
echo ""
echo "  DATA_ENCRYPTION_KEY=$KEY"
echo ""
