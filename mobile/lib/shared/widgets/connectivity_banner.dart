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

    // The navigator under [child] owns a GlobalKey. Keep it in a stable slot so
    // showing the banner does not remount that key.
    return Column(
      children: [
        _OfflineNotice(visible: offline),
        Expanded(child: child),
      ],
    );
  }
}

class _OfflineNotice extends StatelessWidget {
  const _OfflineNotice({required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    return MaterialBanner(
      content: const Text('İnternet bağlantısı gerekli'),
      leading: const Icon(Icons.wifi_off, color: Colors.white),
      backgroundColor: Colors.red.shade700,
      actions: const [SizedBox.shrink()],
    );
  }
}
