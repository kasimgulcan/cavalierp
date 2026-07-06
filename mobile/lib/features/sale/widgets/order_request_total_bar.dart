import 'package:flutter/material.dart';

import '../../../core/format/price_format.dart';

class OrderRequestTotalBar extends StatelessWidget {
  const OrderRequestTotalBar({
    super.key,
    required this.lineCount,
    required this.total,
    this.subtotal,
    this.discountAmount,
    this.currencySymbol = '₺',
  });

  final int lineCount;
  final double total;
  final double? subtotal;
  final double? discountAmount;
  final String currencySymbol;

  bool get _showDiscountBreakdown =>
      subtotal != null && discountAmount != null && discountAmount! > 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final netLabel = formatPriceWithSymbol(
      roundSaleMoney(total),
      currencySymbol,
      decimals: 0,
    );

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
                    '$lineCount kalem',
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
                      netLabel,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ],
              ),
              if (_showDiscountBreakdown) ...[
                const SizedBox(height: 6),
                _TotalRow(
                  label: 'Toplam',
                  value: formatPriceWithSymbol(
                    roundSaleMoney(subtotal!),
                    currencySymbol,
                    decimals: 0,
                  ),
                  theme: theme,
                ),
                const SizedBox(height: 4),
                _TotalRow(
                  label: 'İndirim',
                  value:
                      '- ${formatPriceWithSymbol(roundSaleMoney(discountAmount!), currencySymbol, decimals: 0)}',
                  theme: theme,
                  valueColor: colorScheme.error,
                ),
                const SizedBox(height: 4),
                _TotalRow(
                  label: 'Net toplam',
                  value: netLabel,
                  theme: theme,
                  emphasized: true,
                ),
              ],
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
        Text(label, style: labelStyle),
        const Spacer(),
        Text(value, style: valueStyle),
      ],
    );
  }
}
