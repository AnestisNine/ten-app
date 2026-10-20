#!/usr/bin/env bash
# Build Flutter web and deploy to Cloudflare Pages (production).
set -euo pipefail

PROJECT="${1:-tbn-manager}"
URL="https://${PROJECT}.pages.dev"
cd "$(dirname "$0")/.."

# First run (or missing web/index.html): generate platform folders without touching our code
if [ ! -f web/index.html ]; then
  echo "Δημιουργία web/ ..."
  BK="$(mktemp -d)"
  cp -R lib "$BK/lib"
  [ -d test ] && cp -R test "$BK/test" || true
  flutter create . --platforms=web,ios
  rm -rf lib && cp -R "$BK/lib" lib
  if [ -d "$BK/test" ]; then rm -rf test && cp -R "$BK/test" test; fi
fi

python3 scripts/patch_web.py
flutter pub get
flutter build web --release --no-web-resources-cdn --pwa-strategy=none

LOCAL="$(tr -d ' \n' < build/web/version.json)"

for BRANCH in production main master; do
  npx wrangler pages deploy build/web \
    --project-name "$PROJECT" --branch "$BRANCH" --commit-dirty=true
  sleep 4
  LIVE="$(curl -s -H 'Cache-Control: no-cache' "$URL/version.json?t=$(date +%s)" | tr -d ' \n')"
  if [ "$LIVE" = "$LOCAL" ]; then
    echo ""
    echo "✅ Live: $URL  (κάνε refresh στο κινητό)"
    exit 0
  fi
done

echo "⚠️  Το deploy έγινε αλλά το $URL δεν δείχνει ακόμα τη νέα έκδοση."
echo "    Δες Cloudflare → Workers & Pages → $PROJECT → Settings → Production branch."
exit 1
