# App Flutter

Cliente Web/Android do projeto Nossa Familia. Este app e parte de um projeto de estudos para praticar Flutter, Firebase Messaging, Socket.IO, mapas, upload, notificacoes e tracking mobile.

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

- Home
- Memorias/fotos
- Playlist
- Cartas
- Listas
- Jogos
- Chat
- Localizacao
- Administracao
- Perfil

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
flutter build web --release --no-wasm-dry-run
flutter build apk --debug
flutter build apk --release
```

## Seguranca

- Nao versionar `google-services.json`.
- Nao colocar IPs, tokens ou chaves nos READMEs.
- Usar secrets do Gitea ou arquivos locais ignorados para configuracao real.

