import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:cavalierp/main.dart' as app;

const _username = String.fromEnvironment('SCREENSHOT_USERNAME');
const _email = String.fromEnvironment('SCREENSHOT_EMAIL');
const _password = String.fromEnvironment('SCREENSHOT_PASSWORD');

String get _loginUsername {
  if (_username.isNotEmpty) return _username;
  return _email;
}

Future<void> _screenshot(
  IntegrationTestWidgetsFlutterBinding binding,
  String name,
) async {
  await binding.convertFlutterSurfaceToImage();
  await binding.takeScreenshot(name);
}

/// Avoid pumpAndSettle — loading spinners and streams never "settle".
Future<void> _pause(
  WidgetTester tester, [
  Duration wait = const Duration(seconds: 3),
]) async {
  await tester.pump(wait);
  await Future<void>.delayed(wait);
}

Future<void> _restartApp(WidgetTester tester) async {
  app.main();
  await _pause(tester, const Duration(seconds: 4));
}

Future<void> _tapNavIcon(WidgetTester tester, IconData icon) async {
  final target = find.byIcon(icon);
  if (target.evaluate().isEmpty) return;
  await tester.tap(target.last);
  await _pause(tester, const Duration(seconds: 4));
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App Store screenshots', (tester) async {
    await _restartApp(tester);
    await _screenshot(binding, '01-login');

    await tester.tap(find.text('Kayıt olun'));
    await _pause(tester, const Duration(seconds: 2));
    await _screenshot(binding, '02-register');

    if (_loginUsername.isEmpty || _password.isEmpty) return;

    await _restartApp(tester);

    final fields = find.byType(TextFormField);
    if (fields.evaluate().length < 2) return;
    await tester.enterText(fields.at(0), _loginUsername);
    await tester.enterText(fields.at(1), _password);
    await tester.tap(find.text('Giriş Yap'));
    await _pause(tester, const Duration(seconds: 12));

    if (find.text('Ürünler').evaluate().isEmpty) return;

    await _screenshot(binding, '03-products');

    await _tapNavIcon(tester, Icons.assignment_outlined);
    await _screenshot(binding, '04-orders');

    await _tapNavIcon(tester, Icons.shopping_cart);
    await _screenshot(binding, '05-cart');

    await _tapNavIcon(tester, Icons.point_of_sale);
    await _screenshot(binding, '06-sales');

    await _tapNavIcon(tester, Icons.bar_chart_rounded);
    await _screenshot(binding, '07-reports');

    if (find.byType(FloatingActionButton).evaluate().isNotEmpty) {
      await tester.tap(find.byType(FloatingActionButton).first);
      await _pause(tester, const Duration(seconds: 2));
      await _screenshot(binding, '08-scanner');
      await tester.pageBack();
      await _pause(tester, const Duration(seconds: 2));
    }

    await _tapNavIcon(tester, Icons.person);
    await _screenshot(binding, '09-profile');
  });
}
