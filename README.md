# Nossa Família

Um espaço privado para a família guardar memórias, organizar a rotina e conversar.

O Nossa Família é um aplicativo multi-família: cada família tem seu próprio espaço,
seus membros, suas permissões e seu conteúdo. A mesma pessoa pode participar de
mais de uma família e alternar entre elas sem criar outra conta.

## O que dá para fazer

- Guardar fotos e vídeos em álbuns privados.
- Escrever notas, cartas e capítulos da história da família.
- Montar listas compartilhadas e marcar itens.
- Conversar no chat da família, com mensagens, fotos, respostas e indicadores de
  leitura.
- Compartilhar a localização em tempo real, com locais seguros, alertas de chegada/saída, bateria baixa, SOS e check-in.
- Criar playlists de músicas que marcaram momentos.
- Jogar quizzes e mini jogos em família.
- Receber notificações no aplicativo e no navegador.
- Convidar pessoas e definir o que cada uma pode acessar.

## Arquitetura

```
Aplicativo (Flutter Web/Android)   Painel (Flutter Web)   Site (Jaspr)
                    │                      │                  │
                    └──────────── HTTPS e WebSocket ──────────┘
                                       │
                              Cloudflare Workers
                              API Hono na borda
                                       │
        ┌──────────────┬───────────────┼──────────────┬─────────────┐
        │              │               │              │             │
     Banco D1       Mídia R2      Tempo real      Filas/Cron    Firebase
     (dados)        (fotos)      (Durable Objects) (rotinas)     (push)
```

- **Aplicativo, painel e site** rodam na Cloudflare e conversam com a API pela
  mesma origem, o que mantém cookies, sessões e WebSocket simples e seguros.
- **API** concentra autenticação, permissões, regras de negócio e acesso aos dados.
- **Banco** guarda usuários, famílias, membros e todo o conteúdo textual.
- **Mídia** fica em armazenamento privado; o acesso é sempre temporário e assinado.
- **Tempo real** mantém o chat, as listas e as notificações sincronizados entre os
  aparelhos da mesma família.
- **Rotinas** cuidam de notificações agendadas, limpeza de sessões e remoção de
  demonstrações expiradas.
- **Push** usa Web Push no navegador e Firebase no Android.

## Segurança e privacidade

- Login por **email e senha**. Não há telefone, SMS ou WhatsApp no fluxo.
- Senhas são protegidas por hash; nunca são armazenadas em texto puro.
- A sessão usa cookies seguros e tokens de curta duração.
- Toda operação é limitada à família da sessão. O identificador da família nunca
  vem do corpo da requisição.
- Cada membro tem um papel (`owner`, `admin` ou `member`) e permissões por área.
- Uploads e leituras de mídia usam URLs temporárias.
- Acesso à plataforma administrativa é separado do acesso ao conteúdo das famílias.

## Estrutura do repositório

```
frontend/app       aplicativo Flutter (Web e Android)
frontend/panel     painel para administradores das famílias
frontend/landing   site público de apresentação e cadastro
workers/api        API, banco, tempo real, filas e notificações
workers/web        camada que entrega os sites e encaminha a API
workers/media      entrega privada de mídia
```

## Como rodar

### Pré-requisitos

- Node.js 22 ou superior
- Flutter estável
- Dart 3.13 ou superior
- Conta Cloudflare com Workers, D1 e R2 para o ambiente completo

### API

```bash
cd workers/api
cp .dev.vars.example .dev.vars
npm install
npm run db:migrate:local
npm run dev
```

A API sobe em `http://localhost:8787`. O arquivo `.dev.vars` contém apenas as
configurações locais; os valores de produção ficam no painel da Cloudflare.

### Aplicativo

```bash
cd frontend/app
flutter pub get
flutter run -d chrome \
  --dart-define=API_BASE_URL=http://localhost:8787/api \
  --dart-define=SOCKET_URL=http://localhost:8787
```

Para Android, use o mesmo comando com um dispositivo ou emulador conectado.

### Painel

```bash
cd frontend/panel
flutter pub get
flutter run -d chrome \
  --dart-define=API_BASE_URL=http://localhost:8787/api \
  --dart-define=APP_BASE_URL=http://localhost:8080
```

### Site

```bash
cd frontend/landing
dart pub get
dart pub global activate jaspr_cli 0.23.4
jaspr serve
```

## Deploy

- **API, aplicativo, painel e site** são publicados na Cloudflare. Cada projeto
  tem seu próprio build automático conectado ao repositório.
- **Aplicativo Android** é gerado pelo GitHub Actions e publicado na página de
  releases.
- Configurações e credenciais ficam nos painéis da Cloudflare e do GitHub; nada
  sensível é versionado.

## Links

- Aplicativo: https://my-family-web.vira-ia-br.workers.dev
- Painel: https://my-family-panel.vira-ia-br.workers.dev
- Site: https://my-family-landing.vira-ia-br.workers.dev
- API: https://my-family-api.vira-ia-br.workers.dev
- Baixar o aplicativo: https://github.com/ferforastieri/my-family/releases/latest/download/app-release.apk

## Licença

Projeto privado da família. Todos os direitos reservados.
