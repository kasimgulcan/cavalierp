import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/json_field.dart';
import '../../core/network/api_error.dart';
import 'auth_provider.dart';
import 'user_profile_provider.dart';
import 'widgets/profile_action_tile.dart';
import 'widgets/profile_header_card.dart';
import 'widgets/profile_section_card.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _confirmDeleteAccount(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hesabı sil'),
        content: const Text('Bu işlem geri alınamaz. Devam edilsin mi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final error = await ref.read(authStateProvider.notifier).deleteAccount();
    if (!context.mounted) return;
    if (error != null) {
      showAppSnackBar(context, SnackBar(content: Text(error)));
      return;
    }
    context.go('/home');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loggedIn = ref.watch(authStateProvider).valueOrNull ?? false;
    final profileAsync = ref.watch(userProfileProvider);
    final isStaff = ref.watch(isStaffProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          if (!loggedIn)
            ProfileGuestCard(
              onLogin: () => context.push('/login'),
              onRegister: () => context.push('/register'),
            )
          else
            profileAsync.when(
              loading: () => const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (_, _) => ProfileHeaderCard(
                displayName: 'Hesabım',
                initials: '?',
                roleLabel: isStaff ? profileRoleLabel('Staff') : profileRoleLabel(null),
                isStaff: isStaff,
              ),
              data: (profile) {
                final username = profile?.stringField('Username') ?? 'Hesabım';
                final role = profile?.stringField('Role');
                final createdRaw = profile?.field('CreatedAt');
                DateTime? createdAt;
                if (createdRaw is String) {
                  createdAt = DateTime.tryParse(createdRaw);
                } else if (createdRaw is DateTime) {
                  createdAt = createdRaw;
                }

                return ProfileHeaderCard(
                  displayName: username,
                  initials: profileInitials(username),
                  roleLabel: profileRoleLabel(role),
                  metaLine: profileMemberSinceLabel(createdAt),
                  isStaff: role == 'Staff',
                );
              },
            ),
          const SizedBox(height: 12),
          ProfileSectionCard(
            title: 'Uygulama',
            children: [
              ProfileActionTile(
                icon: Icons.privacy_tip_outlined,
                title: 'Gizlilik Politikası',
                subtitle: 'Verilerinizin nasıl işlendiğini okuyun',
                showDivider: loggedIn,
                onTap: () => context.push('/privacy'),
              ),
              if (loggedIn)
                ProfileActionTile(
                  icon: Icons.logout_rounded,
                  title: 'Çıkış Yap',
                  subtitle: 'Hesabınızdan güvenli çıkış',
                  showDivider: false,
                  onTap: () async {
                    await ref.read(authStateProvider.notifier).logout();
                    if (context.mounted) context.go('/home');
                  },
                ),
            ],
          ),
          if (loggedIn) ...[
            const SizedBox(height: 12),
            ProfileSectionCard(
              title: 'Hesap',
              children: [
                ProfileActionTile(
                  icon: Icons.lock_reset_rounded,
                  title: 'Şifre Değiştir',
                  subtitle: 'Hesap şifrenizi güncelleyin',
                  onTap: () => context.push('/change-password'),
                ),
                ProfileActionTile(
                  icon: Icons.delete_outline_rounded,
                  title: 'Hesabımı Sil',
                  subtitle: 'Kalıcı olarak silinir, geri alınamaz',
                  destructive: true,
                  showDivider: false,
                  onTap: () => _confirmDeleteAccount(context, ref),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
