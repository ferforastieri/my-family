#!/usr/bin/env bash
set -euo pipefail

# Assembles the single deployable site:
#   /     -> Jaspr landing (static, indexable)
#   /app  -> Flutter web app (base href /app/)
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
mkdir -p "$SITE/app"
cp -R "$LANDING/build/jaspr/." "$SITE/"
cp -R "$APP/build/web/." "$SITE/app/"
cp "$APP/tool/site_headers.txt" "$SITE/_headers"
echo "Site assembled at $SITE"
