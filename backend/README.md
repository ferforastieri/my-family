# Backend NestJS

API multi-tenant do SaaS Nossa Família, responsável por autenticação passwordless,
isolamento entre famílias, WebSocket, filas, mídia privada, notificações e
administração da plataforma.

## Tecnologias

- NestJS
- TypeScript
- MongoDB com Mongoose
- Socket.IO
- Redis e BullMQ
- Firebase Admin SDK
- JWT
- Helmet, CORS restrito e rate limit compartilhado no Redis

## Organizacao

Cada feature segue a separacao:

- `domain`: entidades e tipos puros.
- `application`: services, factories e mappers.
- `infrastructure`: repositorios, filas, schemas e integracoes.
- `interfaces`: gateways WebSocket, controllers REST e DTOs.

## Modulos

- `auth`: OTP por celular, JWT, perfil, avatar, sessoes WebSocket e permissoes.
- `fotos`: memorias, albuns, upload e arquivos.
- `musicas`: playlist.
- `cartas`: cartas de amor.
- `lists`: listas compartilhadas.
- `games`: jogos e estatisticas.
- `chat`: chat em tempo real.
- `notifications`: historico, envio imediato, agendamento e push mobile.
- `location`: localizacao, locais, presenca e alertas.
- `health`: healthcheck.
- `tenancy`: famílias, memberships, convites, sessões e administração da plataforma.
- `demo`: tenants fictícios isolados e limpeza após 24 horas.

## Papeis E Acessos

Papéis de membership:

- `owner`
- `admin`
- `member`

`husband`, `wife`, `children` e `friends` representam somente parentesco. O
painel administrativo gerencia acessos por módulo e o papel `super_admin` fica
separado da família.

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
- `maintenance`: expiração e remoção completa das demos.

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
- `TRUST_PROXY_HOPS` conforme a quantidade de proxies confiáveis até a API
- `TURNSTILE_SECRET`
- `PHONE_OTP_SECRET`
- `DEFAULT_PHONE_COUNTRY_CODE`
- `WHATSAPP_ACCESS_TOKEN` e `WHATSAPP_PHONE_NUMBER_ID`
- `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN` e `TWILIO_FROM_NUMBER`
- `FIREBASE_SERVICE_ACCOUNT_PATH`
- `FIREBASE_SERVICE_ACCOUNT_JSON`

## Seguranca

- OTP de seis dígitos, uso único, expiração de cinco minutos e limite de tentativas.
- JWT para usuarios autenticados.
- Guards de admin e acesso por area.
- Sessões em cookies `HttpOnly`, `Secure` em produção e proteção CSRF por double-submit cookie.
- Rate limit global compartilhado no Redis, com limites adicionais por IP e
  telefone no OTP, por IP na demo e por sessão no WebSocket.
- Turnstile obrigatório no cadastro público e na demo em produção.
- Redis protegido por senha no `docker-compose.yml`.
- Helmet em HTTP.
- Secrets somente por ambiente seguro.
- Nenhum IP, senha, token ou chave deve aparecer na documentacao.
