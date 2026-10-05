import 'dart:async';

import 'package:cavalierp/app_router.dart';
import 'package:cavalierp/features/auth/auth_provider.dart';
import 'package:cavalierp/shared/widgets/connectivity_banner.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('auth resolution keeps the same GoRouter', (tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final router = container.read(routerProvider);
    container.read(authStateProvider);

    for (var i = 0; i < 30 && container.read(authStateProvider).isLoading; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }

    expect(container.read(authStateProvider).isLoading, isFalse);
    expect(identical(container.read(routerProvider), router), isTrue);
  });

  testWidgets('offline toggle does not duplicate the navigator key', (tester) async {
    final connectivity = StreamController<List<ConnectivityResult>>.broadcast();
    addTearDown(connectivity.close);

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Text('home'),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          connectivityProvider.overrideWith((ref) => connectivity.stream),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          builder: (context, child) =>
              ConnectivityBanner(child: child ?? const SizedBox()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('home'), findsOneWidget);
    expect(tester.takeException(), isNull);

    connectivity.add(const [ConnectivityResult.none]);
    await tester.pumpAndSettle();
    expect(find.text('İnternet bağlantısı gerekli'), findsOneWidget);
    expect(find.text('home'), findsOneWidget);
    expect(tester.takeException(), isNull);

    connectivity.add(const [ConnectivityResult.wifi]);
    await tester.pumpAndSettle();
    expect(find.text('İnternet bağlantısı gerekli'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('replacing the router while offline does not duplicate keys', (
    tester,
  ) async {
    final connectivity = StreamController<List<ConnectivityResult>>.broadcast();
    addTearDown(connectivity.close);

    final generation = StateProvider<int>((ref) => 0);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          connectivityProvider.overrideWith((ref) => connectivity.stream),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            final version = ref.watch(generation);
            final router = GoRouter(
              initialLocation: '/',
              routes: [
                GoRoute(
                  path: '/',
                  builder: (_, _) => Text('home $version'),
                ),
              ],
            );
            return MaterialApp.router(
              routerConfig: router,
              builder: (context, child) =>
                  ConnectivityBanner(child: child ?? const SizedBox()),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    connectivity.add(const [ConnectivityResult.none]);
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(ConnectivityBanner)),
    );
    container.read(generation.notifier).state = 1;
    await tester.pumpAndSettle();

    expect(find.text('home 1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('offline toggle while a text field is focused does not duplicate keys', (
    tester,
  ) async {
    final connectivity = StreamController<List<ConnectivityResult>>.broadcast();
    addTearDown(connectivity.close);

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(
            body: TextField(),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          connectivityProvider.overrideWith((ref) => connectivity.stream),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          builder: (context, child) =>
              ConnectivityBanner(child: child ?? const SizedBox()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.showKeyboard(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'abc');
    await tester.pump();

    connectivity.add(const [ConnectivityResult.none]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.takeException(), isNull);
    expect(find.text('İnternet bağlantısı gerekli'), findsOneWidget);
  });
}
