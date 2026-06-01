import 'package:flutter_test/flutter_test.dart';
import 'package:my_family/core/auth/auth_controller.dart';
import 'package:my_family/core/auth/token_store.dart';
import 'package:my_family/core/socket/socket_client.dart';
import 'package:my_family/core/widgets/skeleton.dart';
import 'package:my_family/data/family_repository.dart';
import 'package:my_family/main.dart';

void main() {
  testWidgets('shows loading while auth bootstraps', (tester) async {
    final socket = SocketClient();
    await tester.pumpWidget(
      MyFamilyApp(
        auth: AuthController(socket, TokenStore()),
        repository: FamilyRepository(socket),
      ),
    );

    expect(find.byType(PageSkeleton), findsOneWidget);
    expect(find.byType(SkeletonCard), findsWidgets);
  });
}
