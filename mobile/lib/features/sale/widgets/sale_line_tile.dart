import 'package:flutter/material.dart';

import '../../../core/format/price_format.dart';
import '../models/sale.dart';

class SaleLineTile extends StatelessWidget {
  const SaleLineTile({
    super.key,
    required this.line,
    this.currencySymbol = '₺',
  });

  final SaleLine line;
  final String currencySymbol;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final lineTotal = line.lineTotal ?? line.computedTotal;
    final hasLineDiscount = line.listPrice > line.unitPrice;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    line.product,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${line.quantity} adet · ${formatPriceWithSymbol(line.unitPrice, currencySymbol)}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (hasLineDiscount) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Liste: ${formatPriceWithSymbol(line.listPrice, currencySymbol)}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        decoration: TextDecoration.lineThrough,
                        decorationColor: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              formatPriceWithSymbol(lineTotal, currencySymbol),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
