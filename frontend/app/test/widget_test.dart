import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_family/core/auth/auth_controller.dart';
import 'package:my_family/core/chat/chat_controller.dart';
import 'package:my_family/core/notifications/notifications_controller.dart';
import 'package:my_family/core/socket/socket_client.dart';
import 'package:my_family/core/theme/theme_controller.dart';
import 'package:my_family/core/toast/toast_controller.dart';
import 'package:my_family/data/family_repository.dart';
import 'package:my_family/main.dart';

void main() {
  testWidgets('shows loading while auth bootstraps', (tester) async {
    final socket = SocketClient();
    final repository = FamilyRepository(socket);
    await tester.pumpWidget(
      MyFamilyApp(
        auth: AuthController(socket),
        notifications: NotificationsController(socket),
        chat: ChatController(socket, repository),
        theme: ThemeController(),
        toast: ToastController(),
        repository: repository,
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
  });
}
