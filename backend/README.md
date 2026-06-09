# Backend NestJS

Backend do projeto Nossa Familia. Ele foi criado como estudo pratico de arquitetura NestJS, WebSocket, MongoDB, filas, Firebase Admin, upload e seguranca em uma aplicacao real.

## Tecnologias

- NestJS
- TypeScript
- MongoDB com Mongoose
- Socket.IO
- Redis e BullMQ
- Firebase Admin SDK
- JWT
- Nest Schedule
- Helmet, CORS, CSRF e rate limit

## Organizacao

Cada feature segue a separacao:

- `domain`: entidades e tipos puros.
- `application`: services, factories e mappers.
- `infrastructure`: repositorios, filas, schemas e integracoes.
- `interfaces`: gateways WebSocket, controllers REST e DTOs.

## Modulos

- `auth`: login, cadastro, JWT, perfil, avatar, sessoes WebSocket e permissoes.
- `fotos`: memorias, albuns, upload e arquivos.
- `musicas`: playlist.
- `cartas`: cartas de amor.
- `lists`: listas compartilhadas.
- `games`: jogos e estatisticas.
- `chat`: chat em tempo real.
- `notifications`: historico, envio imediato, agendamento e push mobile.
- `location`: localizacao, locais, presenca e alertas.
- `health`: healthcheck.

## Papeis E Acessos

Roles internas:

- `husband`
- `wife`
- `children`
- `friends`

Admins:

- `husband`
- `wife`

O painel administrativo gerencia os acessos por area para usuarios nao administradores.

## Notificacoes

Fluxo mobile:

1. App mobile gera token FCM.
2. App envia token em `notifications.subscribe`.
3. Backend salva o token.
4. Admin envia ou agenda notificacao.
5. Backend usa Firebase Admin para entregar o push.

O backend aceita credencial Firebase por:

- `FIREBASE_SERVICE_ACCOUNT_PATH`
- `FIREBASE_SERVICE_ACCOUNT_JSON`

Esses valores devem vir de secrets ou ambiente seguro. Nunca versionar service account.

## Localizacao

O modulo de localizacao aceita atualizacoes por:

- WebSocket, para app em primeiro plano.
- HTTP autenticado, para tracking Android em background.

Ao receber localizacao, o backend:

- Persiste o ponto.
- Atualiza a tela em tempo real.
- Avalia entrada/saida de locais cadastrados.
- Pode gerar alertas derivados, como bateria baixa.

## Filas

Filas BullMQ:

- `notifications`: jobs de notificacao quando aplicavel.
- `media`: processamento de midia.
- `location`: alertas derivados de localizacao.
- `cleanup`: limpeza recorrente de arquivos orfaos.

## Desenvolvimento

```bash
npm install
npm run start:dev
```

Build:

```bash
npm run build
```

## Ambiente

Use `backend/.env.example` como base. O arquivo real `backend/.env` deve ficar fora do Git.

Variaveis principais:

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

## Seguranca

- JWT para usuarios autenticados.
- Guards de admin e acesso por area.
- CSRF em rotas sem bearer token.
- Rate limit global.
- Helmet em HTTP.
- Secrets somente por ambiente seguro.
- Nenhum IP, senha, token ou chave deve aparecer na documentacao.

