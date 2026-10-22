#!/usr/bin/env bash
set -euo pipefail

# Cloudflare Workers Builds entrypoint.
# Release build marker: 0.0.1
# Root directory in Workers Builds: frontend/app
# Deploy command in Workers Builds: npx wrangler deploy
ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
APP="$ROOT/frontend/app"
LANDING="$ROOT/frontend/landing"

SITE_URL="${SITE_URL:-https://siao.vira-ia-br.workers.dev}"
API_URL="${API_URL:-$SITE_URL/api}"
APP_URL="${APP_URL:-$SITE_URL/}"

API_BASE_URL="${API_BASE_URL:-$SITE_URL/api}"
SOCKET_URL="${SOCKET_URL:-$SITE_URL}"
LANDING_URL="${LANDING_URL:-$SITE_URL}"

export PATH="$HOME/.local/bin:$PATH"

# The Worker imports shared API source from workers/api. Install its runtime
# and type dependencies so Wrangler can bundle the API in this build.
if [[ -f "$ROOT/workers/api/package-lock.json" ]]; then
  (cd "$ROOT/workers/api" && npm ci)
fi

# Flutter is not part of the Workers Builds image.
FLUTTER_HOME="${FLUTTER_HOME:-$HOME/flutter}"
if [[ ! -x "$FLUTTER_HOME/bin/flutter" ]]; then
  git clone --depth 1 --branch stable https://github.com/flutter/flutter.git "$FLUTTER_HOME"
fi
export PATH="$FLUTTER_HOME/bin:$PATH"
flutter config --no-analytics >/dev/null

# Jaspr needs Dart 3.13+; install a pinned SDK for the landing build.
DART_HOME="${DART_HOME:-$HOME/dart-sdk}"
if [[ ! -x "$DART_HOME/bin/dart" ]]; then
  DART_VERSION="${DART_VERSION:-3.13.6}"
  curl -fsSL "https://storage.googleapis.com/dart-archive/channels/stable/release/${DART_VERSION}/sdk/dartsdk-linux-x64-release.zip" -o /tmp/dart-sdk.zip
  unzip -q /tmp/dart-sdk.zip -d "$HOME"
  mv "$HOME/dart-sdk" "$DART_HOME" 2>/dev/null || true
fi
export PATH="$DART_HOME/bin:$PATH"

cd "$APP"
flutter pub get
flutter build web --release --base-href / \
  --no-wasm-dry-run \
  --dart-define=API_BASE_URL="$API_BASE_URL" \
  --dart-define=SOCKET_URL="$SOCKET_URL" \
  --dart-define=LANDING_URL="$LANDING_URL" \
  --dart-define=FIREBASE_API_KEY="${FIREBASE_API_KEY:-AIzaSyDvQAQeTB2ujsAOmVKkYMXB5yN-xWG_-5o}" \
  --dart-define=FIREBASE_APP_ID="${FIREBASE_APP_ID:-1:54228332324:web:b55dcde4c4781fe4dc4db1}" \
  --dart-define=FIREBASE_ANDROID_API_KEY="${FIREBASE_ANDROID_API_KEY:-}" \
  --dart-define=FIREBASE_ANDROID_APP_ID="${FIREBASE_ANDROID_APP_ID:-}" \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID="${FIREBASE_MESSAGING_SENDER_ID:-54228332324}" \
  --dart-define=FIREBASE_PROJECT_ID="${FIREBASE_PROJECT_ID:-siao-app}" \
  --dart-define=FIREBASE_AUTH_DOMAIN="${FIREBASE_AUTH_DOMAIN:-siao-app.firebaseapp.com}" \
  --dart-define=FIREBASE_STORAGE_BUCKET="${FIREBASE_STORAGE_BUCKET:-siao-app.firebasestorage.app}" \
  --dart-define=FIREBASE_WEB_PUSH_CERTIFICATE_KEY="${FIREBASE_WEB_PUSH_CERTIFICATE_KEY:-}"

dart pub global activate jaspr_cli 0.23.4 >/dev/null
export PATH="$HOME/.pub-cache/bin:$PATH"

cd "$LANDING"
dart pub get
rm -rf build/jaspr
jaspr build \
  --port 8099 \
  --sitemap-domain "$SITE_URL" \
  --sitemap-exclude '^/cadastro' \
  --dart-define SITE_URL="$SITE_URL" \
  --dart-define API_URL="$API_URL" \
  --dart-define APP_URL="$APP_URL"
dart run tool/finalize.dart "$SITE_URL" "$API_URL"

cd "$APP"
bash tool/build_site.sh
