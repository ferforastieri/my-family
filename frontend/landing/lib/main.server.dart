import 'package:jaspr/dom.dart';
import 'package:jaspr/server.dart';

import 'app.dart';
import 'main.server.options.dart';

void main() {
  Jaspr.initializeApp(options: defaultServerOptions);
  runApp(
    Document(
      lang: 'pt-BR',
      title: 'Nossa Família',
      meta: const {'theme-color': '#FEFBF3', 'color-scheme': 'light'},
      head: const [
        link(rel: 'icon', href: '/assets/favicon.png'),
        link(rel: 'stylesheet', href: '/styles.css'),
      ],
      body: const App(),
    ),
  );
}
