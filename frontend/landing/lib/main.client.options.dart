// dart format off
// ignore_for_file: type=lint

// GENERATED FILE, DO NOT MODIFY
// Generated with jaspr_builder

import 'package:jaspr/client.dart';

import 'package:my_family_landing/components/demo_button.dart'
    deferred as _demo_button;
import 'package:my_family_landing/pages/register_page.dart'
    deferred as _register_page;

/// Default [ClientOptions] for use with your Jaspr project.
///
/// Use this to initialize Jaspr **before** calling [runApp].
///
/// Example:
/// ```dart
/// import 'main.client.options.dart';
///
/// void main() {
///   Jaspr.initializeApp(
///     options: defaultClientOptions,
///   );
///
///   runApp(...);
/// }
/// ```
ClientOptions get defaultClientOptions => ClientOptions(
  clients: {
    'demo_button': ClientLoader(
      (p) => _demo_button.DemoButton(label: p['label'] as String),
      loader: _demo_button.loadLibrary,
    ),
    'register_page': ClientLoader(
      (p) => _register_page.EmailRegistrationForm(),
      loader: _register_page.loadLibrary,
    ),
  },
);
