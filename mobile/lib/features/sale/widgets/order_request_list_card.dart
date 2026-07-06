import 'package:flutter/material.dart';

import '../../../core/format/price_format.dart';
import '../models/order_request.dart';
import 'order_status_chip.dart';

class OrderRequestListCard extends StatelessWidget {
  const OrderRequestListCard({
    super.key,
    required this.order,
    this.createdAtLabel,
    this.lineCount,
    this.metaLine,
    this.showStatusChip = false,
    this.onTap,
  });

  final OrderRequestSummary order;
  final String? createdAtLabel;
  final int? lineCount;
  final String? metaLine;
  final bool showStatusChip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final (accent, _) = OrderStatusChip.colors(colorScheme, order.status);
    final amount = order.totalAmount != null
        ? formatPrice(order.totalAmount!)
        : '—';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      color: colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(color: accent.withValues(alpha: 0.5)),
              child: const SizedBox(height: 3),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer
                              .withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: Text(
                            '#${order.orderRequestId}',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (showStatusChip)
                        OrderStatusChip(status: order.status),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    order.displayName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  if (_hasMeta) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (createdAtLabel != null && createdAtLabel!.isNotEmpty)
                          _MetaChip(
                            icon: Icons.schedule_outlined,
                            label: createdAtLabel!,
                          ),
                        if (lineCount != null)
                          _MetaChip(
                            icon: Icons.inventory_2_outlined,
                            label: '$lineCount kalem',
                          ),
                        if (metaLine != null &&
                            metaLine!.isNotEmpty &&
                            createdAtLabel == null &&
                            lineCount == null)
                          _MetaChip(
                            icon: Icons.info_outline,
                            label: metaLine!,
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        amount,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool get _hasMeta =>
      (createdAtLabel != null && createdAtLabel!.isNotEmpty) ||
      lineCount != null ||
      (metaLine != null && metaLine!.isNotEmpty);
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OrderRequestDetailHeader extends StatelessWidget {
  const OrderRequestDetailHeader({
    super.key,
    required this.title,
    required this.status,
    this.metaLine,
  });

  final String title;
  final String status;
  final String? metaLine;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
            ),
            const SizedBox(width: 8),
            OrderStatusChip(status: status),
          ],
        ),
        if (metaLine != null && metaLine!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            metaLine!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
