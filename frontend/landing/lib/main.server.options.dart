// dart format off
// ignore_for_file: type=lint

// GENERATED FILE, DO NOT MODIFY
// Generated with jaspr_builder

import 'package:jaspr/server.dart';
import 'package:my_family_landing/components/demo_button.dart' as _demo_button;
import 'package:my_family_landing/pages/register_page.dart' as _register_page;

/// Default [ServerOptions] for use with your Jaspr project.
///
/// Use this to initialize Jaspr **before** calling [runApp].
///
/// Example:
/// ```dart
/// import 'main.server.options.dart';
///
/// void main() {
///   Jaspr.initializeApp(
///     options: defaultServerOptions,
///   );
///
///   runApp(...);
/// }
/// ```
ServerOptions get defaultServerOptions => ServerOptions(
  clientId: 'main.client.dart.js',
  clients: {
    _demo_button.DemoButton: ClientTarget<_demo_button.DemoButton>(
      'demo_button',
      params: __demo_buttonDemoButton,
    ),
    _register_page.PhoneRegistrationForm:
        ClientTarget<_register_page.PhoneRegistrationForm>('register_page'),
  },
);

Map<String, Object?> __demo_buttonDemoButton(_demo_button.DemoButton c) => {
  'label': c.label,
};
