# Nossa Familia

Projeto privado de estudos para experimentar, integrar e documentar tecnologias modernas em um produto familiar completo. A ideia e construir um app real, com frontend, backend, mobile, tempo real, filas, upload, notificacoes, localizacao e deploy automatizado, sem expor dados pessoais ou credenciais no repositorio.

Este repositorio nao deve conter chaves, IPs publicos/privados, senhas, tokens, service accounts ou arquivos de ambiente reais. Todas as configuracoes sensiveis ficam em secrets do Gitea, variaveis de ambiente locais ignoradas pelo Git ou arquivos gerados no build.

## Objetivo De Estudo

O projeto foi criado para estudar na pratica:

- Flutter Web e Android com uma base unica de UI.
- NestJS com arquitetura por dominio.
- Socket.IO para comunicacao em tempo real.
- MongoDB com Mongoose.
- Redis e BullMQ para filas.
- Firebase Cloud Messaging para notificacoes mobile.
- Localizacao mobile em background no Android.
- Uploads e midias fora do repositorio.
- Docker Compose para orquestracao local/servidor.
- Gitea Actions para CI/CD e artefatos.
- Controle de acesso por papeis e permissoes.
- Boas praticas de seguranca para secrets e configuracao.

## Stack

Frontend/mobile:

- Flutter
- Dart
- Firebase Messaging
- Flutter Local Notifications
- Geolocator
- Flutter Map
- Socket.IO client

Backend:

- NestJS
- TypeScript
- MongoDB/Mongoose
- Redis/BullMQ
- Socket.IO
- Firebase Admin SDK
- JWT
- Helmet, CORS, rate limit e CSRF

Infra:

- Docker Compose
- Nginx
- Gitea Actions
- MongoDB
- Redis

## Estrutura

- `app/`: app Flutter Web/Android.
- `backend/`: API NestJS.
- `nginx/`: configuracoes nginx.
- `.gitea/workflows/deploy.yml`: pipeline de build/deploy.
- `docker-compose.yml`: orquestracao de backend, frontend, banco e filas.
- `Dockerfile.backend`: imagem do backend.
- `Dockerfile.front`: build Flutter Web e publicacao via nginx.

## Funcionalidades

- Autenticacao com JWT.
- Perfil, avatar e configuracoes.
- Controle de papeis: `husband`, `wife`, `children`, `friends`.
- Admins: `husband` e `wife`.
- Permissoes por area gerenciaveis no painel administrativo.
- Memorias com fotos, albuns e upload.
- Playlist.
- Cartas de amor.
- Listas compartilhadas.
- Jogos.
- Chat em tempo real.
- Notificacoes com historico, envio imediato e agendamento.
- Localizacao da familia com mapa, lugares e presenca.
- Tracking Android em background usando foreground service.
- Alertas derivados de localizacao, como bateria baixa e entrada/saida de locais.

## Mudancas Recentes

UI e experiencia:

- Padronizacao de margens nas paginas.
- Ajustes de alinhamento e densidade visual em administracao, listas, jogos, playlist, memorias, cartas e home.
- Remocao de cards de estatistica em telas onde estavam poluindo a interface.
- Uso de sheets globais para opcoes.
- Tela de localizacao revisada sem card de pontos importantes.
- Criacao/edicao de locais por arraste no mapa, sem digitar latitude/longitude.

Permissoes e administracao:

- Enum de usuario consolidado em ingles.
- Labels em portugues no frontend.
- `husband` e `wife` com acesso administrativo.
- Painel administrativo para gerenciar acessos por area.
- Correcoes de clique/layout em telas com sobreposicoes indevidas.

Notificacoes:

- Ajuste do fluxo mobile para inicializar Firebase no Android pelo `google-services.json`.
- Geracao de token FCM via `FirebaseMessaging.getToken()`.
- Envio do token para o backend por `notifications.subscribe`.
- Backend com envio FCM imediato quando disponivel.
- Logs e retorno de envio mais claros.
- Tokens invalidos sao removidos somente quando o Firebase indica token invalido ou nao registrado.

Localizacao:

- Android passou a ter foreground service nativo para tracking em background.
- O servico usa `FusedLocationProviderClient`.
- O tracking envia dados para endpoint HTTP autenticado, evitando dependencia de Socket.IO em background.
- O app continua recebendo atualizacoes em tempo real pela tela de mapa.
- Reinicio do tracking apos boot/update quando houver configuracao salva.

Backend:

- Endpoint HTTP autenticado para atualizacao de localizacao mobile.
- Emissao de evento em tempo real quando localizacao chega via HTTP.
- Build do backend validado apos alteracoes.

## Configuracao

Use arquivos reais de ambiente apenas localmente e nunca versionados. O repositorio deve conter somente exemplos e nomes de variaveis.

Variaveis principais do backend:

- `NODE_ENV`
- `PORT`
- `MONGO_URI`
- `MONGO_DB`
- `JWT_SECRET`
- `JWT_EXPIRES_IN`
- `UPLOAD_PATH`
- `CORS_ORIGIN`
- `REDIS_URL`
- `CSRF_SECRET`
- `FIREBASE_SERVICE_ACCOUNT_PATH`
- `FIREBASE_SERVICE_ACCOUNT_JSON`

Variaveis principais do app/deploy:

- `API_BASE_URL`
- `SOCKET_URL`
- `FIREBASE_API_KEY`
- `FIREBASE_APP_ID`
- `FIREBASE_MESSAGING_SENDER_ID`
- `FIREBASE_PROJECT_ID`
- `FIREBASE_AUTH_DOMAIN`
- `FIREBASE_STORAGE_BUCKET`
- `FIREBASE_WEB_PUSH_CERTIFICATE_KEY`
- `GOOGLE_SERVICES_JSON`

Secrets de infraestrutura:

- `MONGO_ROOT_USER`
- `MONGO_ROOT_PASSWORD`
- `MONGO_DB`
- `JWT_SECRET`
- `CSRF_SECRET`
- `UPLOAD_HOST_PATH`
- `BACKEND_PORT`
- `FRONT_PORT`
- `MONGO_PORT`
- `REDIS_PORT`

## Firebase Mobile

Para notificacoes Android:

- `google-services.json` deve existir no build Android, mas nao deve ser commitado.
- O service account do Firebase Admin deve ficar em secret, preferencialmente `FIREBASE_SERVICE_ACCOUNT_JSON`.
- O app gera o token FCM no mobile e envia ao backend em `notifications.subscribe`.
- O backend persiste tokens na colecao de inscricoes push e usa Firebase Admin para enviar.

## Tracking Android

O tracking em background foi implementado com servico nativo Android:

- Foreground service com notificacao persistente.
- Permissoes de localizacao e servico em primeiro plano.
- Envio por HTTP autenticado ao backend.
- Reinicio apos boot/update quando configurado.

Limites conhecidos:

- O Android pode exigir que o usuario permita localizacao "sempre".
- Alguns aparelhos aplicam economia de bateria agressiva.
- Se o app for forcadamente parado pelo usuario, o sistema pode impedir reinicio automatico ate o app ser aberto novamente.

## Deploy

O workflow do Gitea:

1. Faz checkout.
2. Valida secrets obrigatorios.
3. Gera `.env` temporario de deploy.
4. Injeta `google-services.json` a partir de secret.
5. Gera APK Android release.
6. Publica o APK como artefato.
7. Faz build dos containers.
8. Sobe banco, filas, backend e frontend.

Nenhum valor sensivel deve ser escrito no README, em logs ou em arquivos versionados.

## Desenvolvimento

Backend:

```bash
cd backend
npm install
npm run start:dev
```

App:

```bash
cd app
flutter pub get
flutter run -d chrome \
  --dart-define=API_BASE_URL=<api-url> \
  --dart-define=SOCKET_URL=<socket-url>
```

Android:

```bash
cd app
flutter devices
flutter run -d <device-id> \
  --dart-define=API_BASE_URL=<api-url> \
  --dart-define=SOCKET_URL=<socket-url>
```

## Validacao

Comandos usados durante desenvolvimento:

```bash
cd backend
npm run build
```

```bash
cd app
flutter analyze
flutter build apk --debug
```

