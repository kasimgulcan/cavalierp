import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:csm_stok_mobile/main.dart' as app;

const _email = String.fromEnvironment('SCREENSHOT_EMAIL');
const _password = String.fromEnvironment('SCREENSHOT_PASSWORD');

Future<void> _screenshot(
  IntegrationTestWidgetsFlutterBinding binding,
  String name,
) async {
  await binding.convertFlutterSurfaceToImage();
  await binding.takeScreenshot(name);
}

Future<void> _restartApp(WidgetTester tester) async {
  app.main();
  await tester.pumpAndSettle(const Duration(seconds: 5));
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App Store screenshots', (tester) async {
    await _restartApp(tester);
    await _screenshot(binding, '01-login');

    await tester.tap(find.text('Kayıt olun'));
    await tester.pumpAndSettle(const Duration(seconds: 3));
    await _screenshot(binding, '02-register');

    if (_email.isEmpty || _password.isEmpty) return;

    await _restartApp(tester);

    final fields = find.byType(TextFormField);
    if (fields.evaluate().length < 2) return;
    await tester.enterText(fields.at(0), _email);
    await tester.enterText(fields.at(1), _password);
    await tester.tap(find.text('Giriş Yap'));
    await tester.pumpAndSettle(const Duration(seconds: 30));

    if (find.text('Ürünler').evaluate().isEmpty) return;

    await _screenshot(binding, '03-products');

    await tester.tap(find.text('Sepet'));
    await tester.pumpAndSettle(const Duration(seconds: 4));
    await _screenshot(binding, '04-cart');

    if (find.text('Barkod').evaluate().isNotEmpty) {
      await tester.tap(find.text('Barkod'));
      await tester.pumpAndSettle(const Duration(seconds: 4));
      await _screenshot(binding, '05-scanner');
    }

    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle(const Duration(seconds: 4));
    await _screenshot(binding, '06-profile');
  });
}
