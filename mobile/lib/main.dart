import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_router.dart';
import 'shared/widgets/connectivity_banner.dart';

import 'core/config/app_branding.dart';

void main() {
  runApp(const ProviderScope(child: CavaliERPApp()));
}

class CavaliERPApp extends ConsumerWidget {
  const CavaliERPApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: kAppDisplayName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.7),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
      routerConfig: router,
      builder: (context, child) => ConnectivityBanner(child: child ?? const SizedBox()),
    );
  }
}
