import 'package:flutter/material.dart';

import '../models/order_request.dart';

class OrderStatusChip extends StatelessWidget {
  const OrderStatusChip({super.key, required this.status});

  final String status;

  static (Color background, Color foreground) colors(
    ColorScheme colorScheme,
    String status,
  ) =>
      switch (status) {
        'Pending' || 'Accepted' => (
            colorScheme.tertiaryContainer,
            colorScheme.onTertiaryContainer,
          ),
        'Rejected' => (
            colorScheme.errorContainer,
            colorScheme.onErrorContainer,
          ),
        'Converted' => (
            colorScheme.secondaryContainer,
            colorScheme.onSecondaryContainer,
          ),
        _ => (
            colorScheme.surfaceContainerHighest,
            colorScheme.onSurfaceVariant,
          ),
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final (background, foreground) = colors(colorScheme, status);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          orderStatusLabel(status),
          style: theme.textTheme.labelMedium?.copyWith(
            color: foreground,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
