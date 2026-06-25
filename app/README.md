# App Flutter

Cliente Flutter do SaaS Nossa Família. O Android é o build de aplicativo usado
agora; o Web continua disponível em `/app/` quando o serviço fullstack do
Railway é usado.

## Tecnologias

- Flutter
- Dart
- Firebase Core e Firebase Messaging
- Flutter Local Notifications
- Geolocator
- Flutter Map
- Socket.IO client
- Shared Preferences e Secure Storage

## Areas Do App

- Demonstração, login e cadastro em `/app/demo`, `/app/login` e `/app/signup`
- Painel do cliente em `/app/cliente/:tenantSlug/dashboard`
- Administração da família dentro da área autenticada do cliente
- Administração global da plataforma em `/app/admin/dashboard`
- Home
- Memorias/fotos
- Playlist
- Cartas
- Listas
- Jogos
- Chat
- Localizacao
- Perfil

Os componentes reutilizáveis de layout, métricas, seções, botões, cabeçalhos,
tema e feedback ficam em `lib/core/widgets` e `lib/core/theme`. As regras e
telas específicas ficam isoladas por feature em `lib/features`.

O app envia ao backend eventos autenticados de abertura, navegação e erros não
tratados. Tokens, senhas e secrets não fazem parte desses eventos.

## Notificacoes Mobile

No Android, o app inicializa Firebase pelo `google-services.json` nativo quando nao houver configuracao via `dart-define`.

Fluxo esperado:

1. App inicializa Firebase.
2. Usuario concede permissao de notificacao.
3. App chama `FirebaseMessaging.getToken()`.
4. Token e enviado ao backend em `notifications.subscribe`.
5. Backend salva o token e usa Firebase Admin para envio.

O arquivo `google-services.json` e necessario para build Android, mas nao deve ser versionado.

## Localizacao Em Background

O tracking Android usa servico nativo:

- Foreground service.
- Notificacao persistente.
- `FusedLocationProviderClient`.
- Envio para o backend por endpoint HTTP autenticado.
- Reinicio apos boot/update quando ja configurado.

## Desenvolvimento

```bash
flutter pub get
flutter run -d chrome \
  --dart-define=API_BASE_URL=<api-url> \
  --dart-define=SOCKET_URL=<socket-url>
```

Android:

```bash
flutter devices
flutter run -d <device-id> \
  --dart-define=API_BASE_URL=<api-url> \
  --dart-define=SOCKET_URL=<socket-url>
```

## Builds

```bash
flutter analyze
flutter build apk --debug
flutter build apk --release \
  --dart-define=API_BASE_URL=https://seu-dominio.com/api \
  --dart-define=SOCKET_URL=https://seu-dominio.com \
  --dart-define=PUBLIC_WEB_URL=https://seu-dominio.com
flutter build web --release --no-wasm-dry-run --base-href=/app/
```

## Seguranca

- Nao versionar `google-services.json`.
- Nao colocar IPs, tokens ou chaves nos READMEs.
- Usar secrets do Gitea ou arquivos locais ignorados para configuracao real.
