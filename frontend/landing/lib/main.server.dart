import 'package:jaspr/dom.dart';
import 'package:jaspr/server.dart';

import 'app.dart';
import 'main.server.options.dart';

void main() {
  Jaspr.initializeApp(options: defaultServerOptions);
  runApp(
    Document(
      lang: 'pt-BR',
      title: 'Sião',
      meta: const {'theme-color': '#FEFBF3', 'color-scheme': 'light'},
      head: const [
        link(rel: 'icon', href: '/api/public/branding/logo'),
        link(rel: 'stylesheet', href: '/styles.css'),
      ],
      body: const App(),
    ),
  );
}
