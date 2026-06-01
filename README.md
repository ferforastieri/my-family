# Nossa Familia

Aplicacao familiar privada para rodar em servidor pessoal.

## Estrutura

- `backend/`: API NestJS com MongoDB, Redis/BullMQ, JWT, upload REST tecnico e eventos Socket.IO para acoes de negocio.
- `app/`: app Flutter para Android e Web.
- `nginx/`: configs para servir Flutter Web e tunelar API/WebSocket.
- `docker-compose.yml`: deploy no padrao do projeto `atacte`.

## Backend

O backend usa MongoDB via Mongoose. As operacoes principais do app passam por WebSocket:

- `auth.*`
- `users.*`
- `fotos.*`
- `musicas.*`
- `cartas.*`
- `notifications.*`

REST fica reservado para:

- `GET /api/health`
- upload de avatar/fotos/videos
- download/stream de arquivos salvos

## Desenvolvimento

```bash
cd backend
npm install
npm run build
npm test -- --runInBand
```

Para o app Flutter, use uma maquina com Flutter SDK:

```bash
cd app
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3459/api --dart-define=SOCKET_URL=http://localhost:3459
```

## Deploy

Copie as variaveis de `docker-compose.example.yml` para um `.env` real e ajuste senhas/URLs.

```bash
docker-compose --env-file .env -f docker-compose.yml config
docker-compose --env-file .env -f docker-compose.yml up -d --build
```

Portas padrao:

- Backend: `3459 -> 3001`
- Flutter Web: `3458 -> 80`
