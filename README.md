# Nossa Família

SaaS privado multi-tenant para memórias e rotina familiar. O monorepo mantém a
stack original: Flutter/Dart nos aplicativos, Dart/Jaspr na landing e
NestJS/TypeScript no backend.

## Estrutura

- `frontend/app`: aplicativo familiar Web e Android existente.
- `frontend/panel`: painel Flutter Web para clientes e super-admin.
- `frontend/landing`: site estático indexável e cadastro público.
- `frontend/packages/family_ui`: tema e componentes Dart compartilhados.
- `backend`: API/WebSocket NestJS e processo BullMQ worker.
- `workers/media`: Cloudflare Worker que entrega objetos privados do R2.
- `.github/workflows`: validação e deploy.

## Modelo de acesso

Usuários são globais e podem participar de várias famílias. Toda requisição de
conteúdo executa com um `tenantId` obtido da sessão, nunca do corpo da requisição.
Os papéis familiares são `owner`, `admin` e `member`; parentesco é apenas um
atributo. `super_admin` é um papel separado da plataforma e não concede leitura
do conteúdo privado.

O acesso é passwordless: a pessoa informa o celular, escolhe WhatsApp ou SMS e
confirma um código de seis dígitos válido por cinco minutos. No primeiro acesso,
o mesmo fluxo cria automaticamente “Minha Família” no plano `early_access`, com
um endereço aleatório que pode ser personalizado depois no painel. Nos acessos
seguintes, apenas abre uma nova sessão curta e renovável. A demo cria um tenant
fictício isolado por 24 horas, com upload, localização, push e convites
bloqueados.

Access e refresh tokens nunca são entregues ao Dart ou gravados no armazenamento
do navegador. A API usa cookies `HttpOnly`, `Secure` em produção e `SameSite`,
com CSRF double-submit nas operações de escrita. WebSocket também autentica pelo
cookie do handshake; o cabeçalho Bearer não é aceito pela API do produto.

## Desenvolvimento

Backend:

```bash
cd backend
cp .env.example .env
npm install
npm run start:dev
```

Aplicativo e painel:

```bash
cd frontend/app # ou frontend/panel
flutter pub get
flutter run -d chrome \
  --dart-define=API_BASE_URL=http://localhost:3001/api \
  --dart-define=SOCKET_URL=http://localhost:3001
```

Landing:

```bash
cd frontend/landing
dart pub get
dart pub global activate jaspr_cli 0.23.4
jaspr serve
```

O build estático gera HTML real e indexável em `build/jaspr`:

```bash
jaspr build --sitemap-domain https://dominio.com \
  --sitemap-exclude '^/cadastro' \
  --dart-define SITE_URL=https://dominio.com \
  --dart-define API_URL=https://api.dominio.com/api \
  --dart-define APP_URL=https://app.dominio.com \
  --dart-define PANEL_URL=https://painel.dominio.com
```

`TURNSTILE_SITE_KEY` pode ser adicionado como outro `--dart-define`. O código
fonte da landing é Dart; Jaspr gera HTML semântico, canonical, JSON-LD e sitemap.

## Autenticação por celular

Configure `PHONE_OTP_SECRET` e pelo menos um transporte em `backend/.env`.
WhatsApp usa a Cloud API da Meta com templates aprovados; SMS usa Twilio. Em
desenvolvimento, quando o canal não está configurado, a API devolve `devCode`
para permitir testes locais. Em produção, a ausência do provedor é um erro.

## Entrega

Pull requests validam backend, landing, Worker, os dois projetos Flutter e a
imagem Docker. Após a CI de `main`, GitHub Actions publica a imagem API/worker no
GHCR, os três frontends na Cloudflare e aciona o Coolify. Produção usa MongoDB,
Redis, API e worker separados, R2 privado para mídia e health checks em
`/api/health/live` e `/api/health/ready`.

Nenhum secret, credencial Firebase, token ou arquivo `.env` real deve ser
versionado.
