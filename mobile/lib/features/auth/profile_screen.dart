import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loggedIn = ref.watch(authStateProvider).valueOrNull ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Gizlilik Politikası'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/privacy'),
          ),
          if (!loggedIn) ...[
            ListTile(
              title: const Text('Giriş Yap'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/login'),
            ),
            ListTile(
              title: const Text('Kayıt Ol'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/register'),
            ),
          ] else ...[
            ListTile(
              title: const Text('Çıkış Yap'),
              onTap: () async {
                await ref.read(authStateProvider.notifier).logout();
                if (context.mounted) context.go('/home');
              },
            ),
            ListTile(
              title: Text('Hesabımı Sil', style: TextStyle(color: Colors.red.shade700)),
              onTap: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Hesabı sil'),
                    content: const Text('Bu işlem geri alınamaz. Devam edilsin mi?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
                      FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sil')),
                    ],
                  ),
                );
                if (confirmed != true || !context.mounted) return;
                final error = await ref.read(authStateProvider.notifier).deleteAccount();
                if (!context.mounted) return;
                if (error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
                  return;
                }
                context.go('/home');
              },
            ),
          ],
        ],
      ),
    );
  }
}
