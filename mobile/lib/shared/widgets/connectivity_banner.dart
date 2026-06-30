import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

final connectivityProvider = StreamProvider<List<ConnectivityResult>>((ref) {
  return Connectivity().onConnectivityChanged;
});

class ConnectivityBanner extends ConsumerWidget {
  const ConnectivityBanner({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivity = ref.watch(connectivityProvider);
    final offline = connectivity.maybeWhen(
      data: (results) =>
          results.isEmpty || results.every((r) => r == ConnectivityResult.none),
      orElse: () => false,
    );

    return Column(
      children: [
        if (offline)
          MaterialBanner(
            content: const Text('İnternet bağlantısı gerekli'),
            leading: const Icon(Icons.wifi_off, color: Colors.white),
            backgroundColor: Colors.red.shade700,
            actions: const [SizedBox.shrink()],
          ),
        Expanded(child: child),
      ],
    );
  }
}
