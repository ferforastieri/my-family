# Sua Família

SaaS para criar um espaço familiar privado com memórias, cartas, músicas,
linha do tempo, chat, listas, jogos, notificações e localização.

## Arquitetura

- `app/`: um único cliente Flutter para Web, Android e iOS.
- `landing-page/`: landing pública em Next.js, renderizada no servidor para SEO.
- `backend/`: API NestJS, autenticação, multi-tenancy, Stripe, conteúdo público
  dinâmico e entrega do Flutter Web em `/app/`.
- MongoDB: dados persistentes de todas as famílias, isolados por `tenantId`.
- Redis/BullMQ: filas, notificações e trabalhos em segundo plano.

Planos e política de privacidade não ficam chumbados na landing. O Next.js lê
esses dados do backend em tempo de request.

## Rotas públicas

- `/pt`, `/en`, `/es`: landing pages indexáveis renderizadas pelo Next.js.
- `/{idioma}/privacidade`: política renderizada pela landing a partir do backend.
- `/app/`: cliente Flutter Web.
- `/app/demo`: demonstração no Flutter.
- `/app/signup`: cadastro e início da assinatura.
- `/app/login/cliente`: login do cliente.
- `/app/login/painel`: login para o painel da família.
- `/app/familia/{slug}/login`: login direto em uma família.
- `/{idioma}/familia/{slug}`: site compartilhado da família, renderizado pelo
  Next.js a partir de `/api/public/sites/{slug}`.
- `/robots.txt` e `/sitemap.xml`: gerados pela landing Next.js.

Android e iOS apresentam o mesmo fluxo público, demonstração, cadastro,
assinatura e funcionalidades do Web.

## Serviços Docker

- `app`: serviço único com landing Next.js, API NestJS, Socket.IO e Flutter Web.
- `mongo` e `redis`: persistência e filas.

```bash
docker compose build
docker compose up -d
```

O endereço padrão é `http://localhost:3458`:

- `/`: redireciona para `/pt`.
- `/pt`, `/en`, `/es`: landing SEO em Next.js.
- `/api`: backend NestJS.
- `/app`: Flutter Web.
- `/socket.io`: WebSocket do backend.

## Deploy

- Railway deve ter um único serviço apontando para a raiz do repositório,
  usando `railway.toml` e `Dockerfile.backend`.
- O container sobe três processos internos: NestJS, Next.js e um roteador HTTP.
- O roteador expõe `/api`, `/socket.io` e `/app/` pelo NestJS; o restante fica
  com o Next.js, incluindo landing, privacidade, páginas familiares,
  `robots.txt` e `sitemap.xml`.
- MongoDB, Redis/BullMQ e Bucket S3 ficam no Railway ou em serviços externos
  apontados por variáveis.
- Cloudflare fica como DNS, proxy, SSL, WAF e camada de segurança do domínio.
- Android é build de aplicativo, não serviço Railway. O APK/AAB é gerado a
  partir de `app/` com Flutter, apontando para o domínio público do backend.

No Railway, mantenha a raiz do repositório como fonte do serviço. As variáveis
principais são:

```text
NODE_ENV=production
CORS_ORIGIN=https://seu-dominio.com
API_BASE_URL=https://seu-dominio.com/api
MONGO_URI=<mongo-uri>
REDIS_URL=<redis-url>
JWT_SECRET=<segredo>
CSRF_SECRET=<segredo>
BUCKET=<bucket>
ENDPOINT=<endpoint-s3>
REGION=<regiao>
ACCESS_KEY_ID=<access-key>
SECRET_ACCESS_KEY=<secret-key>
PASSWORD_RESET_URL=https://seu-dominio.com/app/reset-password
```

Stripe e URLs de billing são opcionais. Configure
`STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`, `BILLING_SUCCESS_URL` e
`BILLING_CANCEL_URL` somente quando for ativar checkout/assinaturas. Os Price
IDs do Stripe, quando usados, ficam nos planos gerenciados pelo painel da
plataforma.

Mudanças de dados e schema do MongoDB devem ser feitas com operações explícitas
do próprio MongoDB, como `updateMany`, pipelines de atualização, criação de
índices e validação de schema. Não coloque mutação de banco dentro do build
Docker; a imagem precisa ser reprodutível.

## Configuração

As variáveis sensíveis devem ficar somente no `.env` local ou no gerenciador de
segredos do ambiente de deploy. Nunca versione credenciais.

Variáveis principais:

- `MONGO_ROOT_USER`, `MONGO_ROOT_PASSWORD`
- `JWT_SECRET`, `CSRF_SECRET`
- `REDIS_URL`
- `BUCKET`, `ENDPOINT`, `REGION`, `ACCESS_KEY_ID`, `SECRET_ACCESS_KEY`
- variáveis Firebase usadas no Web, Android e backend
- Stripe/billing quando checkout estiver ativo

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

Landing:

```bash
cd landing-page
npm install
API_BASE_URL=http://localhost:3001/api \
npm run dev -- -p 3458
```

Android:

```bash
cd app
flutter build apk --release \
  --dart-define=API_BASE_URL=https://seu-dominio.com/api \
  --dart-define=SOCKET_URL=https://seu-dominio.com \
  --dart-define=PUBLIC_WEB_URL=https://seu-dominio.com
```

Validação:

```bash
cd backend && npm run build && npm test -- --runInBand
cd app && flutter analyze && flutter test
cd landing-page && npm run typecheck && npm run build
```

## Dados

Para mudanças destrutivas, faça backup do MongoDB antes de subir a versão.
