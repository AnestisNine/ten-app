#!/usr/bin/env python3
"""Patch the Flutter-generated web/ folder for TBN Manager.

Run from the project root, after `flutter create . --platforms=web,ios`.
Safe to run many times.

- viewport-fit=cover (notch / home-indicator safe areas on phones)
- theme-color + iOS "Add to Home Screen" (standalone) meta tags
- dark background before Flutter loads (no white flash)
- Open Graph / Twitter tags + 1200x630 image (link preview in Messenger,
  WhatsApp, iMessage, Viber, Slack...)
- manifest.json (name, colors, standalone display)
- TBN icons (incl. 180px apple-touch-icon)
"""
import json
import os
import pathlib
import re
import shutil
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
WEB = ROOT / "web"
ASSETS = pathlib.Path(__file__).resolve().parent / "web_assets"
MARK = "<!-- tbn-web-patch-v2 -->"
OLD_MARK = "<!-- tbn-web-patch -->"
BG = "#0F1115"
# Absolute URL is required by Facebook/Messenger for og:image.
SITE_URL = os.environ.get("TBN_SITE_URL", "https://tbn-manager.pages.dev").rstrip("/")
TITLE = "TBN Manager"
DESC = "The Bonnie Nettles · Touring · Merch · Finance"

if not (WEB / "index.html").exists():
    sys.exit("web/index.html not found. Run: flutter create . --platforms=web,ios")

# ---- index.html
path = WEB / "index.html"
html = path.read_text(encoding="utf-8")

# Remove a previous patch block (any version) so the script stays idempotent.
for mark in (MARK, OLD_MARK):
    if mark in html:
        start = html.index(mark)
        end = html.index("</style>", start) + len("</style>")
        html = html[:start] + html[end:]

html = re.sub(r"<meta[^>]*name=[\"']viewport[\"'][^>]*>\s*", "", html)
html = re.sub(r"<title>.*?</title>", f"<title>{TITLE}</title>", html, flags=re.S)
html = re.sub(r"<meta[^>]*name=[\"']apple-mobile-web-app-[^>]*>\s*", "", html)
html = re.sub(r"<meta[^>]*name=[\"']mobile-web-app-capable[\"'][^>]*>\s*", "", html)
html = re.sub(r"<meta[^>]*name=[\"']description[\"'][^>]*>\s*", "", html)
html = re.sub(r"<link[^>]*rel=[\"']apple-touch-icon[\"'][^>]*>\s*", "", html)

block = f"""{MARK}
  <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
  <meta name="description" content="{DESC}">
  <meta name="theme-color" content="{BG}">
  <meta name="color-scheme" content="dark light">
  <meta name="mobile-web-app-capable" content="yes">
  <meta name="apple-mobile-web-app-capable" content="yes">
  <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
  <meta name="apple-mobile-web-app-title" content="{TITLE}">
  <meta name="robots" content="noindex, nofollow">
  <link rel="apple-touch-icon" sizes="180x180" href="icons/apple-touch-icon.png">
  <meta property="og:type" content="website">
  <meta property="og:site_name" content="{TITLE}">
  <meta property="og:title" content="{TITLE}">
  <meta property="og:description" content="{DESC}">
  <meta property="og:url" content="{SITE_URL}/">
  <meta property="og:image" content="{SITE_URL}/og-image.jpg">
  <meta property="og:image:secure_url" content="{SITE_URL}/og-image.jpg">
  <meta property="og:image:type" content="image/jpeg">
  <meta property="og:image:width" content="1200">
  <meta property="og:image:height" content="630">
  <meta property="og:image:alt" content="The Bonnie Nettles">
  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:title" content="{TITLE}">
  <meta name="twitter:description" content="{DESC}">
  <meta name="twitter:image" content="{SITE_URL}/og-image.jpg">
  <style>
    html, body {{
      margin: 0;
      height: 100%;
      background: {BG};
      overscroll-behavior: none;
      -webkit-tap-highlight-color: transparent;
      -webkit-text-size-adjust: 100%;
    }}
  </style>
"""
html = html.replace("</head>", block + "</head>", 1)
path.write_text(html, encoding="utf-8")
print("patched web/index.html")

# ---- manifest.json
mpath = WEB / "manifest.json"
if mpath.exists():
    m = json.loads(mpath.read_text(encoding="utf-8"))
    m.update(
        {
            "name": TITLE,
            "short_name": "TBN",
            "description": DESC,
            "lang": "el",
            "display": "standalone",
            "background_color": BG,
            "theme_color": BG,
        }
    )
    mpath.write_text(json.dumps(m, indent=2, ensure_ascii=False), encoding="utf-8")
    print("patched web/manifest.json")

# ---- icons + preview image
icons = WEB / "icons"
icons.mkdir(exist_ok=True)
for name in [
    "Icon-192.png",
    "Icon-512.png",
    "Icon-maskable-192.png",
    "Icon-maskable-512.png",
    "apple-touch-icon.png",
]:
    shutil.copy(ASSETS / name, icons / name)
shutil.copy(ASSETS / "favicon.png", WEB / "favicon.png")
shutil.copy(ASSETS / "og-image.jpg", WEB / "og-image.jpg")
print("copied TBN icons and og-image.jpg")
