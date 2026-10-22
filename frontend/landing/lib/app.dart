import 'package:jaspr/jaspr.dart';
import 'package:jaspr_router/jaspr_router.dart';

import 'pages/home_page.dart';

class App extends StatelessComponent {
  const App({super.key});

  @override
  Component build(BuildContext context) => Router(
    routes: [
      Route(path: '/', builder: (_, _) => const HomePage()),
    ],
  );
}
