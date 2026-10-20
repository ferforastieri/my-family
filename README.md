# Nossa Família

SaaS privado multi-tenant para memórias e rotina familiar, 100% na Cloudflare.

## Stack

- **API**: Hono em Workers (`workers/api`), D1, R2, Durable Objects, Queues e Cron.
- **App**: Flutter Web e Android (`frontend/app`).
- **Painel**: Flutter Web (`frontend/panel`).
- **Landing**: Jaspr/Dart (`frontend/landing`).
- **Web Workers**: `workers/web` serve os assets e fazem proxy de `/api/*` e `/ws`
  para a API. Assim app, painel e landing ficam na mesma origem da API, sem CORS
  e sem cookies de terceiros.
- **Push**: Firebase Cloud Messaging no projeto `my-family-76986`.
- **APK**: GitHub Actions (`.github/workflows/android.yml`).

## URLs

- App: https://my-family-web.vira-ia-br.workers.dev
- Painel: https://my-family-panel.vira-ia-br.workers.dev
- Landing: https://my-family-landing.vira-ia-br.workers.dev
- API: https://my-family-api.vira-ia-br.workers.dev

## Estrutura

```
workers/api       API Hono + D1 + DO + Queue + Cron
workers/web       script de assets/proxy usado pelos três web Workers
workers/media     entrega privada de mídia no R2
frontend/app      aplicativo Flutter
frontend/panel    painel Flutter
frontend/landing  landing Jaspr
```

## Desenvolvimento

API:

```bash
cd workers/api
cp .dev.vars.example .dev.vars
npm install
npm run db:migrate:local
npm run dev
```

App:

```bash
cd frontend/app
flutter pub get
flutter run -d chrome \
  --dart-define=API_BASE_URL=http://localhost:8787/api \
  --dart-define=SOCKET_URL=http://localhost:8787
```

## Deploy (Cloudflare Workers Builds)

Os cinco Workers já estão publicados. Para ativar o build automático, conecte
cada root no dashboard (**Workers & Pages → Worker → Settings → Builds**).

| Worker | Root | Build | Deploy |
|---|---|---|---|
| `my-family-api` | `workers/api` | `npm ci` | `npx wrangler deploy` |
| `my-family-web` | `frontend/app` | Flutter + `flutter build web` | `npx wrangler deploy` |
| `my-family-panel` | `frontend/panel` | Flutter + `flutter build web` | `npx wrangler deploy` |
| `my-family-landing` | `frontend/landing` | Dart + `jaspr build` | `npx wrangler deploy` |
| `my-family-media` | `workers/media` | `npm ci` | `npm run deploy` |

### Variáveis de build

`my-family-web`:

```
API_BASE_URL=https://my-family-web.vira-ia-br.workers.dev/api
SOCKET_URL=https://my-family-api.vira-ia-br.workers.dev
FIREBASE_API_KEY=AIzaSyAdzcp6WxQEm7mKArNthR2OidbjvbPH91w
FIREBASE_APP_ID=1:177457768602:web:ecb14c8366741618439723
FIREBASE_MESSAGING_SENDER_ID=177457768602
FIREBASE_PROJECT_ID=my-family-76986
FIREBASE_AUTH_DOMAIN=my-family-76986.firebaseapp.com
FIREBASE_STORAGE_BUCKET=my-family-76986.firebasestorage.app
```

`my-family-panel`:

```
API_BASE_URL=https://my-family-panel.vira-ia-br.workers.dev/api
APP_BASE_URL=https://my-family-web.vira-ia-br.workers.dev
```

`my-family-landing`:

```
SITE_URL=https://my-family-landing.vira-ia-br.workers.dev
API_URL=https://my-family-landing.vira-ia-br.workers.dev/api
APP_URL=https://my-family-web.vira-ia-br.workers.dev
PANEL_URL=https://my-family-panel.vira-ia-br.workers.dev
```

### Build command — app e painel

```bash
git clone --depth 1 -b stable https://github.com/flutter/flutter.git /tmp/flutter
export PATH="/tmp/flutter/bin:$PATH"
flutter config --no-analytics
flutter pub get
flutter build web --release --no-wasm-dry-run \
  --dart-define=API_BASE_URL=$API_BASE_URL \
  --dart-define=SOCKET_URL=$SOCKET_URL \
  --dart-define=FIREBASE_API_KEY=$FIREBASE_API_KEY \
  --dart-define=FIREBASE_APP_ID=$FIREBASE_APP_ID \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=$FIREBASE_MESSAGING_SENDER_ID \
  --dart-define=FIREBASE_PROJECT_ID=$FIREBASE_PROJECT_ID \
  --dart-define=FIREBASE_AUTH_DOMAIN=$FIREBASE_AUTH_DOMAIN \
  --dart-define=FIREBASE_STORAGE_BUCKET=$FIREBASE_STORAGE_BUCKET
npx --yes wrangler@4.151.3 deploy
```

No painel, troque as defines de Firebase por
`--dart-define=APP_BASE_URL=$APP_BASE_URL` (o painel não usa push).

### Build command — landing

```bash
curl -sSL https://storage.googleapis.com/dart-archive/channels/stable/release/3.13.6/sdk/dartsdk-linux-x64-release.zip -o /tmp/dart.zip
unzip -q /tmp/dart.zip -d /tmp
export PATH="/tmp/dart-sdk/bin:$PATH"
dart pub get
dart pub global activate jaspr_cli 0.23.4
export PATH="$HOME/.pub-cache/bin:$PATH"
jaspr build --port 8099 \
  --sitemap-domain $SITE_URL \
  --sitemap-exclude '^/cadastro' \
  --dart-define SITE_URL=$SITE_URL \
  --dart-define API_URL=$API_URL \
  --dart-define APP_URL=$APP_URL \
  --dart-define PANEL_URL=$PANEL_URL
dart run tool/finalize.dart $SITE_URL $API_URL
npx --yes wrangler@4.151.3 deploy
```


## Secrets do Worker `my-family-api`

```bash
npx wrangler secret put JWT_SECRET
npx wrangler secret put PHONE_OTP_SECRET
npx wrangler secret put TWILIO_ACCOUNT_SID
npx wrangler secret put TWILIO_AUTH_TOKEN
npx wrangler secret put TWILIO_FROM_NUMBER
npx wrangler secret put FIREBASE_SERVICE_ACCOUNT_JSON
# opcionais
npx wrangler secret put TURNSTILE_SECRET
npx wrangler secret put MEDIA_SIGNING_SECRET
```

## Autenticação

Passwordless por celular, com código de 6 dígitos por **SMS (Twilio)**. O
WhatsApp foi removido. Sem `TWILIO_*`, o login em produção retorna 503; a demo
e o ambiente local (`APP_ENV=development`) continuam funcionando.

## Banco

D1 `my-family`. Migrações:

```bash
cd workers/api
npm run db:migrate        # remoto
npm run db:migrate:local  # local
```

## Android

O workflow `android.yml` gera o APK release em pushes na `main`, tags ou
manualmente. Ele usa o secret `GOOGLE_SERVICES_JSON` e as vars
`FIREBASE_ANDROID_API_KEY`/`FIREBASE_ANDROID_APP_ID`.
