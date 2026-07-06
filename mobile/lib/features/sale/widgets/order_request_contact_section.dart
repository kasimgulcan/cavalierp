import 'package:flutter/material.dart';

import 'checkout_form_section.dart';

class OrderRequestContactSection extends StatelessWidget {
  const OrderRequestContactSection({
    super.key,
    this.customer,
    this.phone,
    this.email,
    this.memberEmail,
  });

  final String? customer;
  final String? phone;
  final String? email;
  final String? memberEmail;

  bool get _hasCustomer => customer?.trim().isNotEmpty == true;
  bool get _hasPhone => phone?.trim().isNotEmpty == true;
  bool get _hasEmail => email?.trim().isNotEmpty == true;
  bool get _hasMemberEmail =>
      memberEmail?.trim().isNotEmpty == true &&
      memberEmail!.trim() != customer?.trim();

  @override
  Widget build(BuildContext context) {
    if (!_hasCustomer && !_hasPhone && !_hasEmail && !_hasMemberEmail) {
      return const SizedBox.shrink();
    }

    return CheckoutFormSection(
      title: 'İletişim',
      children: [
        if (_hasCustomer)
          _ContactRow(
            icon: Icons.person_outline_rounded,
            label: 'İsim / firma',
            value: customer!.trim(),
          ),
        if (_hasMemberEmail) ...[
          if (_hasCustomer) const SizedBox(height: 10),
          _ContactRow(
            icon: Icons.badge_outlined,
            label: 'Üye hesabı',
            value: memberEmail!.trim(),
          ),
        ],
        if (_hasPhone) ...[
          if (_hasCustomer || _hasMemberEmail) const SizedBox(height: 10),
          _ContactRow(
            icon: Icons.phone_outlined,
            label: 'Telefon',
            value: phone!.trim(),
          ),
        ],
        if (_hasEmail) ...[
          if (_hasCustomer || _hasMemberEmail || _hasPhone)
            const SizedBox(height: 10),
          _ContactRow(
            icon: Icons.mail_outline_rounded,
            label: 'E-posta',
            value: email!.trim(),
          ),
        ],
      ],
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, size: 18, color: colorScheme.primary),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
