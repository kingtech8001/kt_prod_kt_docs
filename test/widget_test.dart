import 'package:flutter_test/flutter_test.dart';
import 'package:kt_prod_kt_docs/app/routes/app_routes.dart';
import 'package:kt_prod_kt_docs/main.dart';

void main() {
  testWidgets('KT Vault app builds test', (WidgetTester tester) async {
    await tester.pumpWidget(const KTVaultApp(isDemoMode: true, initialRoute: AppRoutes.LOGIN));
    expect(find.byType(KTVaultApp), findsOneWidget);
  });
}
