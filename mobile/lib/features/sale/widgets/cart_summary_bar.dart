import 'package:flutter/material.dart';

import '../../../core/format/price_format.dart';

class CartSummaryBar extends StatelessWidget {
  const CartSummaryBar({
    super.key,
    required this.itemCount,
    required this.totalLabel,
    required this.actionLabel,
    required this.onAction,
    this.enabled = true,
    this.subtotalLabel,
    this.discountAmount,
    this.discountSymbol = '',
  });

  final int itemCount;
  final String totalLabel;
  final String actionLabel;
  final VoidCallback? onAction;
  final bool enabled;
  final String? subtotalLabel;
  final double? discountAmount;
  final String discountSymbol;

  bool get _showDiscountBreakdown =>
      subtotalLabel != null &&
      discountAmount != null &&
      discountAmount! > 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      elevation: 8,
      color: colorScheme.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(
                    '$itemCount kalem',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  if (!_showDiscountBreakdown) ...[
                    Text(
                      'Toplam',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      totalLabel,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
              if (_showDiscountBreakdown) ...[
                const SizedBox(height: 6),
                _TotalRow(
                  label: 'Toplam',
                  value: subtotalLabel!,
                  theme: theme,
                ),
                const SizedBox(height: 4),
                _TotalRow(
                  label: 'İndirim',
                  value: '- ${formatPriceWithSymbol(discountAmount!, discountSymbol)}',
                  theme: theme,
                  valueColor: colorScheme.error,
                ),
                const SizedBox(height: 4),
                _TotalRow(
                  label: 'Net toplam',
                  value: totalLabel,
                  theme: theme,
                  emphasized: true,
                ),
              ],
              const SizedBox(height: 10),
              FilledButton(
                onPressed: enabled ? onAction : null,
                child: Text(actionLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.label,
    required this.value,
    required this.theme,
    this.valueColor,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final ThemeData theme;
  final Color? valueColor;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final labelStyle = theme.textTheme.labelLarge?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final valueStyle = emphasized
        ? theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: valueColor,
          )
        : theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: valueColor,
          );

    return Row(
      children: [
        const SizedBox(width: 0),
        Text(label, style: labelStyle),
        const Spacer(),
        Text(value, style: valueStyle),
      ],
    );
  }
}

String formatCartTotal(double total, String currencySymbol) {
  return formatPriceWithSymbol(total, currencySymbol, decimals: 0);
}
