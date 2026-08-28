import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_family_panel/main.dart';

void main() {
  testWidgets('shows the phone login form', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: LoginPage(session: PanelSession())),
    );

    expect(find.text('Painel da família'), findsOneWidget);
    expect(find.text('Celular com DDD'), findsOneWidget);
    expect(find.text('Receber código'), findsOneWidget);
  });
}
