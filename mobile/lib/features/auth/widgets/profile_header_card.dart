import 'package:flutter/material.dart';

class ProfileHeaderCard extends StatelessWidget {
  const ProfileHeaderCard({
    super.key,
    required this.displayName,
    required this.initials,
    this.roleLabel,
    this.metaLine,
    this.isStaff = false,
  });

  final String displayName;
  final String initials;
  final String? roleLabel;
  final String? metaLine;
  final bool isStaff;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accent = isStaff ? colorScheme.primary : colorScheme.tertiary;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      color: colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(color: accent.withValues(alpha: 0.45)),
            child: const SizedBox(height: 4),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: accent.withValues(alpha: 0.2),
                  child: Text(
                    initials,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                      if (roleLabel != null) ...[
                        const SizedBox(height: 8),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: (isStaff
                                    ? colorScheme.primaryContainer
                                    : colorScheme.tertiaryContainer)
                                .withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            child: Text(
                              roleLabel!,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: isStaff
                                    ? colorScheme.onPrimaryContainer
                                    : colorScheme.onTertiaryContainer,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                      if (metaLine != null && metaLine!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          metaLine!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileGuestCard extends StatelessWidget {
  const ProfileGuestCard({
    super.key,
    required this.onLogin,
    required this.onRegister,
  });

  final VoidCallback onLogin;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      color: colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.35),
            ),
            child: const SizedBox(height: 4),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.55),
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Icon(
                      Icons.person_outline_rounded,
                      size: 40,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Hesabınıza giriş yapın',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Talep göndermek ve sepetinizi yönetmek için giriş yapın veya kayıt olun.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: onLogin,
                  child: const Text('Giriş Yap'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: onRegister,
                  child: const Text('Kayıt Ol'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String profileInitials(String username) {
  final trimmed = username.trim();
  if (trimmed.isEmpty) return '?';

  final parts = trimmed.split(RegExp(r'\s+'));
  if (parts.length >= 2) {
    return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }
  return trimmed.length >= 2
      ? trimmed.substring(0, 2).toUpperCase()
      : trimmed[0].toUpperCase();
}

String profileRoleLabel(String? role) => switch (role) {
      'Staff' => 'Personel',
      _ => 'Üye',
    };

String? profileMemberSinceLabel(DateTime? createdAt) {
  if (createdAt == null) return null;
  final local = createdAt.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  return 'Üyelik: $day.$month.${local.year}';
}
