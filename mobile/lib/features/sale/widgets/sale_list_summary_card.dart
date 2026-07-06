import 'package:flutter/material.dart';

import '../../../core/format/price_format.dart';

class SaleListSummaryCard extends StatelessWidget {
  const SaleListSummaryCard({
    super.key,
    required this.saleCount,
    required this.totalAmount,
    this.hasMore = false,
    this.symbol = '₺',
  });

  final int saleCount;
  final double totalAmount;
  final bool hasMore;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final countLabel = hasMore ? '$saleCount+ satış' : '$saleCount satış';

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colorScheme.primaryContainer.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: _SummaryMetric(
                label: 'Satış sayısı',
                value: countLabel,
              ),
            ),
            Container(
              width: 1,
              height: 40,
              color: colorScheme.outlineVariant,
            ),
            Expanded(
              child: _SummaryMetric(
                label: hasMore ? 'Yüklenen toplam' : 'Toplam tutar',
                value: formatPriceWithSymbol(
                  roundSaleMoney(totalAmount),
                  symbol,
                  decimals: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: theme.textTheme.labelMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
