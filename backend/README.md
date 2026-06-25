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
- Helmet, CORS, CSRF e rate limit

## Organizacao

Cada feature segue a separacao:

- `domain`: entidades e tipos puros.
- `application`: services, factories e mappers.
- `infrastructure`: repositorios, filas, schemas e integracoes.
- `interfaces`: gateways WebSocket, controllers REST e DTOs.

A direção das dependências é `interfaces/infrastructure -> application -> domain`.
Contratos de persistência e integrações ficam em `application/ports`; o módulo
Nest associa esses contratos aos adapters concretos. O módulo `cartas` é a
implementação de referência para a migração gradual das demais features.

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
- `billing`: checkout Stripe, portal, webhook e processamento assíncrono.
- `tenancy`: famílias, membros e isolamento dos dados SaaS.
- `health`: healthcheck.

## Papeis E Acessos

Roles internas:

- `owner`
- `admin`
- `member`

Admins:

- `owner`
- `admin`

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
- `payments`: eventos Stripe com idempotência, retentativas exponenciais e retenção de falhas.

O webhook valida a assinatura antes de responder e adiciona o evento à fila. A
atualização da assinatura e do tenant é executada pelo worker, evitando timeout
do webhook e perda de eventos em falhas temporárias.

Notificações agendadas também usam jobs atrasados no BullMQ com identificador
idempotente. Elas não dependem da memória de uma instância do backend.

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
- `BUCKET`, `ENDPOINT`, `REGION`, `ACCESS_KEY_ID`, `SECRET_ACCESS_KEY`
- `CORS_ORIGIN`
- `REDIS_URL`
- `CSRF_SECRET`
- `FIREBASE_SERVICE_ACCOUNT_PATH`
- `FIREBASE_SERVICE_ACCOUNT_JSON`
- `STRIPE_SECRET_KEY`
- `STRIPE_WEBHOOK_SECRET`
- `STRIPE_PRICE_ID`
- `BILLING_SUCCESS_URL`
- `BILLING_CANCEL_URL`

## Seguranca

- JWT para usuarios autenticados.
- Guard JWT global baseado em `@nestjs/jwt`, com rotas anônimas marcadas por `@Public()`.
- Guards de admin e acesso por area.
- CSRF em rotas sem bearer token.
- Rate limit global.
- Helmet em HTTP.
- Secrets somente por ambiente seguro.
- Nenhum IP, senha, token ou chave deve aparecer na documentacao.

## Armazenamento

O backend usa exclusivamente armazenamento S3 compatível. As cinco variáveis do
Bucket são obrigatórias em todos os ambientes. Fotos, avatares, miniaturas e
metadados continuam privados e são entregues pelos endpoints autorizados.
