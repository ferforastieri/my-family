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

Cada Worker é conectado ao repositório no dashboard, com o root indicado:

| Worker | Root | Build | Deploy |
|---|---|---|---|
| `my-family-api` | `workers/api` | `npm ci` | `npx wrangler deploy` |
| `my-family-web` | `frontend/app` | baixa Flutter + `flutter build web` | `npx wrangler deploy` |
| `my-family-panel` | `frontend/panel` | baixa Flutter + `flutter build web` | `npx wrangler deploy` |
| `my-family-landing` | `frontend/landing` | baixa Dart + `jaspr build` | `npx wrangler deploy` |
| `my-family-media` | `workers/media` | `npm ci` | `npm run deploy` |

Build do app/painel (Workers Builds não tem Flutter instalado):

```bash
git clone --depth 1 -b stable https://github.com/flutter/flutter.git /tmp/flutter
export PATH="/tmp/flutter/bin:$PATH"
flutter config --no-analytics
flutter pub get
flutter build web --release --no-wasm-dry-run \
  --dart-define=API_BASE_URL=$API_BASE_URL \
  --dart-define=SOCKET_URL=$SOCKET_URL
npx --yes wrangler@4.151.3 deploy
```

O build da landing baixa o Dart SDK 3.13.6 e ativa `jaspr_cli 0.23.4` antes do
`jaspr build`.

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
