# Nossa Família

SaaS para criar um espaço familiar privado com memórias, cartas, músicas,
linha do tempo, chat, listas, jogos, notificações e localização.

## Arquitetura

- `app/`: um único cliente Flutter para Web, Android e iOS.
- `backend/`: API NestJS, autenticação, multi-tenancy, Stripe e páginas SEO.
- `nginx/`: servidor do Flutter Web e proxy público para o NestJS.
- MongoDB: dados persistentes de todas as famílias, isolados por `tenantId`.
- Redis/BullMQ: filas, notificações e trabalhos em segundo plano.

Não existe mais uma aplicação Next.js. As páginas que precisam de indexação são
HTML renderizado pelo NestJS; a experiência interativa completa fica no Flutter.

## Rotas públicas

- `/pt`, `/en`, `/es`: landing pages indexáveis.
- `/app/`: cliente Flutter Web.
- `/app/demo`: demonstração no Flutter.
- `/app/signup`: cadastro e início da assinatura.
- `/app/login`: autenticação.
- `/{idioma}/familia/{slug}`: site compartilhado da família, com Open Graph e
  `noindex` para não expor conteúdo familiar nos buscadores.
- `/robots.txt` e `/sitemap.xml`: gerados pelo NestJS.

Android e iOS apresentam o mesmo fluxo público, demonstração, cadastro,
assinatura e funcionalidades do Web.

## Serviços Docker

- `front`: única porta pública; serve o Flutter em `/app/` e encaminha o restante ao Nest.
- `backend`: NestJS.
- `mongo` e `redis`: persistência e filas.

```bash
docker compose build
docker compose up -d
```

O endereço padrão é `http://localhost:3458`.

## Produção: Cloudflare Pages + Railway

- Cloudflare Pages: Flutter Web em `/app/` e proxy público para páginas SEO,
  API, Stripe e Socket.IO.
- Railway: NestJS, MongoDB, Redis/BullMQ e Bucket S3 privado.
- GitHub Actions: compila o Flutter e publica os arquivos no Pages.

Os arquivos necessários já estão em `railway.toml`, `deploy/cloudflare/` e
`.github/workflows/deploy-cloudflare-pages.yml`. O procedimento completo está em
[`docs/deploy-cloudflare-railway.md`](docs/deploy-cloudflare-railway.md).

## Configuração

As variáveis sensíveis devem ficar somente no `.env` local ou no gerenciador de
segredos do ambiente de deploy. Nunca versione credenciais.

Variáveis principais:

- `MONGO_ROOT_USER`, `MONGO_ROOT_PASSWORD`, `MONGO_DB`
- `JWT_SECRET`, `CSRF_SECRET`
- `REDIS_URL`, `UPLOAD_HOST_PATH`
- `API_BASE_URL`, `SOCKET_URL`, `PUBLIC_WEB_URL`
- `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`, `STRIPE_PRICE_ID`
- `BILLING_SUCCESS_URL`, `BILLING_CANCEL_URL`
- variáveis Firebase usadas no Web, Android e backend

Para produção, `BILLING_SUCCESS_URL` e `BILLING_CANCEL_URL` devem apontar para
`https://seu-dominio/app/billing`.

## Desenvolvimento

Backend:

```bash
cd backend
npm install
npm run start:dev
```

Flutter:

```bash
cd app
flutter pub get
flutter run
```

Validação:

```bash
cd backend && npm run build && npm test -- --runInBand
cd app && flutter analyze && flutter test
```

## Dados existentes

A migração SaaS está em `backend/scripts/migrate-to-saas.ts`. Ela cria o tenant
legado, preserva os dados existentes e adiciona o isolamento necessário. Execute
somente com backup confirmado.
