#!/usr/bin/env bash
set -euo pipefail

# Assembles the single deployable site:
#   /     -> Flutter landing for people, SEO HTML for crawlers
#   /termos, /privacidade -> legal pages
#   /api  -> separate API Worker through service binding
# The API remains a separate Worker and is reached through /api and /ws.
ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
APP="$ROOT/frontend/app"
LANDING="$ROOT/frontend/landing"
SITE="$APP/build/site"

if [[ ! -f "$APP/build/web/index.html" ]]; then
  echo "Missing $APP/build/web/index.html. Run the Flutter web build first." >&2
  exit 1
fi
if [[ ! -f "$LANDING/build/jaspr/index.html" ]]; then
  echo "Missing $LANDING/build/jaspr/index.html. Run the Jaspr build first." >&2
  exit 1
fi

rm -rf "$SITE"
mkdir -p "$SITE/seo"

# Flutter app at the public root.
cp -R "$APP/build/web/." "$SITE/"

# The same landing content, pre-rendered as HTML for crawlers.
cp "$LANDING/build/jaspr/index.html" "$SITE/seo/index.html"

# Legal pages stay public; the other marketing pages no longer exist.
rm -rf "$SITE/termos" "$SITE/privacidade"
cp -R "$LANDING/build/jaspr/termos" "$SITE/termos"
cp -R "$LANDING/build/jaspr/privacidade" "$SITE/privacidade"

# Landing styles, scripts and images required by the SEO snapshot and legal pages.
mkdir -p "$SITE/assets"
cp -R "$LANDING/build/jaspr/assets/." "$SITE/assets/"
cp "$LANDING/build/jaspr/styles.css" "$SITE/styles.css"
cp "$LANDING/build/jaspr/design-system.css" "$SITE/design-system.css"
cp "$LANDING/build/jaspr"/main.client.dart.js* "$SITE/"
if [ -d "$LANDING/build/jaspr/packages" ]; then
  cp -R "$LANDING/build/jaspr/packages" "$SITE/packages"
fi
cp "$LANDING/build/jaspr/sitemap.xml" "$SITE/sitemap.xml"
cp "$LANDING/build/jaspr/robots.txt" "$SITE/robots.txt"

# One shared policy for the Flutter app, SEO snapshot and legal pages.
cp "$APP/tool/site_headers.txt" "$SITE/_headers"
echo "Site assembled at $SITE"
