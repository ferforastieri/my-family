# my-family-api

Backend 100% Cloudflare Workers: Hono + D1 + Durable Objects + Queues + R2.

## Bindings

- `DB`: D1 `my-family`
- `MEDIA`: R2 `my-family-media`
- `JOBS`: Queue `my-family-jobs`
- `REALTIME`: Durable Object `TenantRealtime` (WebSocket por família)
- `RATE_LIMITER`: Durable Object `RateLimiter` (rate limit por IP)

## Secrets

```bash
npx wrangler secret put JWT_SECRET
npx wrangler secret put PHONE_OTP_SECRET
# opcionais
npx wrangler secret put TURNSTILE_SECRET
npx wrangler secret put WHATSAPP_ACCESS_TOKEN
npx wrangler secret put WHATSAPP_PHONE_NUMBER_ID
npx wrangler secret put WHATSAPP_OTP_TEMPLATE
npx wrangler secret put TWILIO_ACCOUNT_SID
npx wrangler secret put TWILIO_AUTH_TOKEN
npx wrangler secret put TWILIO_FROM_NUMBER
npx wrangler secret put MEDIA_SIGNING_SECRET
npx wrangler secret put FIREBASE_SERVICE_ACCOUNT_JSON
```

## Migrations

```bash
npm run db:migrate        # remoto
npm run db:migrate:local  # local (wrangler dev)
```

## Desenvolvimento

```bash
cp .dev.vars.example .dev.vars
npm install
npm run db:migrate:local
npm run dev
```

## Workers Builds (build automático da Cloudflare)

No dashboard em **Workers & Pages → my-family-api → Settings → Builds**, conecte
o repositório `ferforastieri/my-family` com:

- **Root directory:** `workers/api`
- **Build command:** `npm ci`
- **Deploy command:** `npx wrangler deploy`
- **Branch:** `main`

O `wrangler.jsonc` já contém D1, R2, fila, Durable Objects, Cron Trigger e as
variáveis não sensíveis. Os secrets ficam fora do repositório (acima).

As migrações D1 devem rodar antes do deploy (job de CI ou manualmente) porque
Workers Builds executa apenas o build e o deploy.

## Contrato

As rotas mantêm o prefixo `/api` e o envelope:

```json
{ "ok": true, "message": "...", "data": {}, "timestamp": "..." }
```

Erros:

```json
{ "ok": false, "message": "...", "error": "...", "statusCode": 400, "timestamp": "..." }
```

WebSocket: `/ws?ticket=...`. O ticket é obtido em `POST /api/auth/ws-ticket`
(válido por 60s, uso único). Mensagens usam `{ "id", "event", "data" }` e as
respostas usam `{ "id", "ok", "message", "data" }`; eventos do servidor usam
`{ "event", "data" }`.
