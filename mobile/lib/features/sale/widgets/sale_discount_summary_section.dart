import 'package:flutter/material.dart';

import '../../../core/format/price_format.dart';
import '../checkout_discount.dart';

class SaleDiscountSummarySection extends StatelessWidget {
  const SaleDiscountSummarySection({
    super.key,
    required this.subtotal,
    required this.discount,
    required this.symbol,
  });

  final double subtotal;
  final CheckoutDiscountInput discount;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final percentAmount = discount.percentDiscountAmount(subtotal);
    final fixedAmount = discount.fixedDiscountAmount(subtotal);
    final netTotal = discount.grandTotal(subtotal);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'İndirimler',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            _Row(
              label: 'Ara toplam',
              value: formatSaleMoney(roundSaleMoney(subtotal), symbol),
              theme: theme,
            ),
            if (discount.percent > 0) ...[
              const SizedBox(height: 8),
              _Row(
                label:
                    '% indirim (${discount.percent == discount.percent.roundToDouble() ? discount.percent.round() : discount.percent}%)',
                value:
                    '- ${formatSaleMoney(roundSaleMoney(percentAmount), symbol)}',
                theme: theme,
                valueColor: colorScheme.error,
              ),
            ],
            if (fixedAmount != 0) ...[
              const SizedBox(height: 8),
              _Row(
                label: fixedAmount < 0 ? 'Tutar düzeltmesi' : 'Tutar indirimi',
                value: fixedAmount < 0
                    ? '+ ${formatSaleMoney(roundSaleMoney(fixedAmount.abs()), symbol)}'
                    : '- ${formatSaleMoney(roundSaleMoney(fixedAmount), symbol)}',
                theme: theme,
                valueColor: fixedAmount < 0 ? null : colorScheme.error,
              ),
            ],
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            _Row(
              label: 'Net toplam',
              value: formatSaleMoney(roundSaleMoney(netTotal), symbol),
              theme: theme,
              emphasized: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
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
    final valueStyle = emphasized
        ? theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: valueColor,
          )
        : theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: valueColor,
          );

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Text(value, style: valueStyle),
      ],
    );
  }
}
