# Migração para Cloudflare (estado atual)

Este documento descreve o que já foi portado para `workers/api` e o que falta
para o cutover. O backend antigo em `backend/` continua no repositório para
referência e rollback.

## O que está pronto

- API Hono em Workers, mantendo o prefixo `/api` e o envelope de resposta.
- D1 `my-family` com 26 tabelas e migrações em `workers/api/migrations`.
- Auth passwordless: OTP por WhatsApp/SMS, JWT HS256 em cookie `HttpOnly`,
  refresh token de uso único, CSRF double-submit, Turnstile opcional.
- Multi-tenancy explícito por `tenant_id` em todas as consultas.
- Tenancy: famílias, membros, convites, papéis, tema, painel da plataforma.
- Módulos: notas, cartas, jornada, músicas, listas, home, fotos, notificações,
  localização, jogos e demo.
- Upload direto para R2 (multipart e URL assinada) e leitura por URL assinada
  ou streaming pelo Worker.
- Tempo real: Durable Object `TenantRealtime` com WebSocket, chat completo
  (conversas, mensagens, edição, exclusão, leitura, digitando) e broadcast de
  listas/notificações/localização.
- Filas: `my-family-jobs` (Cloudflare Queues) e Cron Trigger de 1 minuto para
  notificações agendadas, limpeza de sessões/desafios e demos expiradas.
- Rate limit em Durable Object, com bucket mais restrito para OTP.
- `workers/api/wrangler.jsonc` com D1, R2, Queue, DOs e Cron.
- Workflow `.github/workflows/android.yml` para gerar o APK release.

## Estado do deploy

- API: `https://my-family-api.vira-ia-br.workers.dev`
- D1: `my-family` (`9182fca4-3f7f-4cde-97b2-e1a077d8c20d`)
- R2: `my-family-media`
- Queue: `my-family-jobs`
- Frontends: ainda sem projetos Pages neste repositório; o workflow antigo
  depende das variáveis `CF_*` e `API_BASE_URL`/`SOCKET_URL`.
- Backend NestJS/Coolify: intocado, ainda pode ser usado para rollback.

## O que falta / diferenças conhecidas

1. **Push FCM**: implementado em `src/push.ts` (FCM HTTP v1 com JWT RS256).
   Basta configurar `FIREBASE_SERVICE_ACCOUNT_JSON` no Worker. Sem o secret, o
   envio retorna `sent: 0` e o app continua recebendo em tempo real.
2. **Cloudflare Images**: as fotos são servidas no original. Não há thumbnail
   nem conversão para WebP. Opções: transformar na leitura com
   `/cdn-cgi/image/...` ou usar o binding de Images.
3. **Importação de dados**: não há script Mongo → D1. Se houver dados de
   produção, exportar por coleção respeitando `tenant_id` e importar com
   `wrangler d1 import`.
4. **CORS**: `CORS_ORIGIN` em `wrangler.jsonc` está `http://localhost:8080`.
   Trocar pelos domínios reais (`app`, `painel`, `landing`).
5. **Secrets de produção**: configurar WhatsApp/Twilio, Turnstile,
   `MEDIA_SIGNING_SECRET` e FCM no Worker. Sem isso, o OTP em produção retorna
   503 e o push fica desativado.
6. **Domínio**: o Worker está em `my-family-api.vira-ia-br.workers.dev`.
   Adicionar custom domain `api.<dominio>` e apontar `API_BASE_URL`/`SOCKET_URL`
   dos frontends para ele.
7. **Frontend web**: `socket_io_client` foi removido; o app usa
   `web_socket_channel` e `POST /api/auth/ws-ticket`. O APK precisa ser
   regenerado e distribuído.
8. **Deploy**: o workflow antigo ainda publica a imagem no GHCR e aciona o
   Coolify. Desativar o job `publish-backend` após o cutover; o deploy da API
   passa a ser feito pelo Workers Builds.

## Workers Builds

No dashboard: **Workers & Pages → my-family-api → Settings → Builds**,
conectar `ferforastieri/my-family` com:

- Root directory: `workers/api`
- Build command: `npm ci`
- Deploy command: `npx wrangler deploy`
- Branch: `main`

As migrações D1 rodam separadamente:

```bash
cd workers/api
npx wrangler d1 migrations apply my-family --remote
```

## Cutover sugerido

1. Configurar secrets e `CORS_ORIGIN`.
2. Rodar migrações D1.
3. Importar dados (se houver).
4. Apontar `API_BASE_URL`/`SOCKET_URL` dos frontends para o Worker.
5. Gerar e distribuir o novo APK.
6. Validar login, chat, upload, listas e notificações.
7. Desativar o job de backend do Coolify e o workflow antigo.

## Rollback

O backend NestJS e o `docker-compose.yml` continuam intactos. Basta apontar os
frontends de volta para a API antiga e reativar o Coolify.
