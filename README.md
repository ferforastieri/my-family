# Nossa Família

SaaS para criar um espaço familiar privado com memórias, cartas, músicas,
linha do tempo, chat, listas, jogos, notificações e localização.

## Arquitetura

- `app/`: um único cliente Flutter para Web, Android e iOS.
- `backend/`: API NestJS, autenticação, multi-tenancy, Stripe, páginas SEO e
  entrega do Flutter Web em `/app/`.
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

- `backend`: única porta pública; serve o Flutter em `/app/`, as páginas SEO,
  a API e o Socket.IO.
- `mongo` e `redis`: persistência e filas.

```bash
docker compose build
docker compose up -d
```

O endereço padrão é `http://localhost:3458`.

## Deploy

- Railway cria o serviço a partir deste repositório, usando `railway.toml` e
  `Dockerfile.backend`.
- O serviço Railway expõe o backend, as páginas SEO, `/api`, `/socket.io` e o
  Flutter Web em `/app/`.
- MongoDB, Redis/BullMQ e Bucket S3 ficam no Railway ou em serviços externos
  compatíveis apontados por variáveis.
- Cloudflare fica como DNS, proxy, SSL, WAF e camada de segurança do domínio.
- Android é build de aplicativo, não serviço Railway. O APK/AAB é gerado a
  partir de `app/` com Flutter, apontando para o domínio público do backend.

No Railway, mantenha a raiz do repositório como fonte do serviço. As variáveis
principais do serviço são:

```text
NODE_ENV=production
PORT=3000
CORS_ORIGIN=https://seu-dominio.com
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
`STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`, `STRIPE_PRICE_ID`,
`BILLING_SUCCESS_URL` e `BILLING_CANCEL_URL` somente quando for ativar
checkout/assinaturas.

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
```

## Dados

Para mudanças destrutivas, faça backup do MongoDB antes de subir a versão.
