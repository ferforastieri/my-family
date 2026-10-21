import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siao/core/auth/auth_controller.dart';
import 'package:siao/core/chat/chat_controller.dart';
import 'package:siao/core/location/location_controller.dart';
import 'package:siao/core/notifications/notifications_controller.dart';
import 'package:siao/core/socket/socket_client.dart';
import 'package:siao/core/theme/theme_controller.dart';
import 'package:siao/core/toast/toast_controller.dart';
import 'package:siao/data/family_repository.dart';
import 'package:siao/main.dart';

void main() {
  testWidgets('shows loading while auth bootstraps', (tester) async {
    final socket = SocketClient();
    final auth = AuthController(socket);
    final repository = FamilyRepository(socket);
    await tester.pumpWidget(
      MyFamilyApp(
        auth: auth,
        notifications: NotificationsController(socket),
        chat: ChatController(socket, repository),
        theme: ThemeController(),
        toast: ToastController(),
        location: LocationController(socket, auth),
        repository: repository,
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
  });
}
