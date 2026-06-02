# Nossa Familia

Aplicacao familiar privada para servidor pessoal, com backend NestJS, app Flutter para Web/Android e deploy por Docker Compose via Gitea Actions.

## Visao Geral

O projeto centraliza memorias, cartas, playlist, jogos, notificacoes, perfil e chat em tempo real. O Flutter e o cliente principal: o mesmo codigo gera o site Web e o APK Android.

Principais caracteristicas:

- App Flutter em `app/`, com suporte Web e Android.
- Backend NestJS em `backend/`, usando MongoDB, Redis/BullMQ e Socket.IO.
- Acoes de negocio preferencialmente via WebSocket.
- REST reservado para endpoints tecnicos, healthcheck e arquivos.
- Uploads persistidos fora do repositorio, por bind mount no Docker.
- Push notifications via Firebase.
- Deploy no padrao do `atacte`, com containers persistentes e artefato APK gerado no workflow.

## Estrutura

- `app/`: cliente Flutter Web/Android.
- `backend/`: API NestJS.
- `nginx/`: configuracoes nginx para Flutter Web, API e WebSocket.
- `.gitea/workflows/deploy.yml`: build, APK e deploy no servidor.
- `docker-compose.yml`: MongoDB, Redis, backend e frontend.
- `Dockerfile.backend`: build e runtime do NestJS.
- `Dockerfile.front`: build Flutter Web e nginx.

## Backend

O backend segue uma divisao por feature:

- `application`: services e casos de uso.
- `domain`: entidades e tipos puros compartilhados.
- `infrastructure`: schemas Mongo, repositorios, filas, upload e integracoes.
- `interfaces`: gateways WebSocket e controllers REST.

Features principais:

- `auth`: login, registro, JWT, perfil e sessoes WebSocket.
- `fotos`: memorias, albums, upload e arquivos.
- `musicas`: playlist.
- `cartas`: cartas e mensagens.
- `notifications`: notificacoes, agendamento BullMQ/Redis e Firebase.
- `chat`: chat global publico e conversas entre usuarios autenticados.
- `health`: healthcheck REST.

Eventos WebSocket principais:

- `auth.*`
- `users.*`
- `fotos.*`
- `musicas.*`
- `cartas.*`
- `notifications.*`
- `chat.*`

Endpoints REST principais:

- `GET /api/health`
- `POST /api/fotos/upload`
- `GET /api/fotos/file?path=...`
- endpoints tecnicos de auth/usuarios quando necessario.

## Flutter

O app em `app/` usa camadas simples:

- `core/`: auth, socket, chat, notifications, tema, toast e widgets globais.
- `data/`: modelos e repository compartilhado.
- `features/`: telas e widgets por dominio.

Recursos atuais:

- Shell responsivo para Web e Mobile.
- Menu, perfil, configuracoes e sheets reutilizaveis.
- Tema com modo claro/escuro e cores.
- Toast global no topo.
- Chat flutuante no canto inferior esquerdo.
- Upload/listagem/edicao de memorias.
- Splash e icones Web/Android baseados na logo do projeto.

## Desenvolvimento Local

Backend:

```bash
cd backend
npm install
npm run start:dev
```

Flutter Web:

```bash
cd app
flutter pub get
flutter run -d chrome \
  --dart-define=API_BASE_URL=http://localhost:3001/api \
  --dart-define=SOCKET_URL=http://localhost:3001
```

Builds:

```bash
cd backend
npm run build
```

```bash
cd app
flutter analyze
flutter test
flutter build web --release
flutter build apk --release
```

## Variaveis

Backend local (`backend/.env`):

- `NODE_ENV`
- `PORT`
- `MONGO_URI`
- `MONGO_DB`
- `REDIS_URL`
- `JWT_SECRET`
- `JWT_EXPIRES_IN`
- `UPLOAD_PATH`
- `CORS_ORIGIN`
- `SMTP_*`
- `EMAIL_FROM`
- `EMAIL_FROM_NAME`
- `PASSWORD_RESET_URL`
- `FIREBASE_SERVICE_ACCOUNT_PATH`
- `FIREBASE_SERVICE_ACCOUNT_JSON`

Compose/deploy (`.env` ou Gitea secrets):

- `MONGO_ROOT_USER`
- `MONGO_ROOT_PASSWORD`
- `MONGO_DB`
- `BACKEND_PORT`
- `FRONT_PORT`
- `MONGO_PORT`
- `REDIS_PORT`
- `JWT_SECRET`
- `JWT_EXPIRES_IN`
- `CORS_ORIGIN`
- `API_BASE_URL`
- `SOCKET_URL`
- `UPLOAD_HOST_PATH`
- `SMTP_*`
- `EMAIL_FROM`
- `EMAIL_FROM_NAME`
- `PASSWORD_RESET_URL`
- `FIREBASE_*`

`UPLOAD_HOST_PATH` e obrigatorio no Docker Compose. O container backend monta esse caminho em `/data/uploads` e usa `UPLOAD_PATH=/data/uploads`.

## Deploy

O deploy e executado pelo workflow `.gitea/workflows/deploy.yml` em pushes para `main` ou `master`.

Fluxo:

1. Checkout do repositorio.
2. Validacao de secrets obrigatorios.
3. Geracao do `.env` de deploy.
4. Build do APK Android release.
5. Publicacao do APK como artefato `my-family-android-apk`.
6. Build dos containers.
7. Subida de `mongo` e `redis`.
8. Subida de `backend` e `front` com `--remove-orphans`.

Servicos:

- `mongo`: MongoDB 7.
- `redis`: Redis 7 Alpine.
- `backend`: NestJS em `3001`, exposto pela porta definida em `BACKEND_PORT`.
- `front`: Flutter Web via nginx, exposto pela porta definida em `FRONT_PORT`.

Portas padrao:

- Backend: `3459 -> 3001`
- Frontend Web: `3458 -> 80`
- Mongo: `127.0.0.1:27019 -> 27017`
- Redis: `127.0.0.1:6389 -> 6379`

## Secrets Do Gitea

Secrets obrigatorios:

- `MONGO_ROOT_PASSWORD`
- `JWT_SECRET`
- `UPLOAD_HOST_PATH`

Secrets recomendados:

- `MONGO_ROOT_USER`
- `MONGO_DB`
- `BACKEND_PORT`
- `FRONT_PORT`
- `MONGO_PORT`
- `REDIS_PORT`
- `JWT_EXPIRES_IN`
- `CORS_ORIGIN`
- `API_BASE_URL`
- `SOCKET_URL`
- `EMAIL_FROM_NAME`
- `SMTP_PORT`

Secrets opcionais:

- `SMTP_HOST`
- `SMTP_USER`
- `SMTP_PASS`
- `EMAIL_FROM`
- `PASSWORD_RESET_URL`
- `FIREBASE_SERVICE_ACCOUNT_PATH`
- `FIREBASE_SERVICE_ACCOUNT_JSON`
- `FIREBASE_API_KEY`
- `FIREBASE_APP_ID`
- `FIREBASE_MESSAGING_SENDER_ID`
- `FIREBASE_PROJECT_ID`
- `FIREBASE_AUTH_DOMAIN`
- `FIREBASE_STORAGE_BUCKET`
- `FIREBASE_WEB_PUSH_CERTIFICATE_KEY`

## Verificacao

Comandos usados para validar mudancas:

```bash
cd backend && npm run build
```

```bash
cd app && flutter analyze
cd app && flutter test
cd app && flutter build web --release
cd app && flutter build apk --release
```

```bash
docker compose --env-file .env -f docker-compose.yml config
```

## Notas De Arquitetura

- IDs expostos pela API sao strings, compatíveis com Mongo ObjectId.
- Escritas de negocio exigem autenticacao, exceto fluxos explicitamente publicos.
- Chat global aceita visitante; conversas privadas exigem usuario autenticado.
- Imagens enviadas pelo chat autenticado tambem sao salvas em Memorias.
- Arquivos nao ficam no repositorio e nao dependem da pasta de desenvolvimento.
