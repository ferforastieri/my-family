# Nossa Familia App

App Flutter do projeto Nossa Familia. O mesmo codigo roda como site Flutter Web e app Android.

## Rodar em desenvolvimento

```bash
flutter pub get
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080 \
  --dart-define=API_BASE_URL=http://localhost:3459/api \
  --dart-define=SOCKET_URL=http://localhost:3459
```

Para Android:

```bash
flutter devices
flutter run -d <device-id> \
  --dart-define=API_BASE_URL=http://SEU_IP:3459/api \
  --dart-define=SOCKET_URL=http://SEU_IP:3459
```

## Builds

```bash
flutter build web --release --no-wasm-dry-run
flutter build apk --debug
```
