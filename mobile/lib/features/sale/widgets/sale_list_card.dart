import 'package:flutter/material.dart';

import '../../../core/format/price_format.dart';
import '../models/sale.dart';
import '../sale_totals.dart';
import 'sale_flag_picker.dart';

class SaleListCard extends StatelessWidget {
  const SaleListCard({
    super.key,
    required this.sale,
    this.createdAtLabel,
    this.amountLabel,
    this.symbol = '₺',
    this.onTap,
  });

  final SaleSummary sale;
  final String? createdAtLabel;
  final String? amountLabel;
  final String symbol;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final amount = amountLabel ??
        (sale.subtotalAmount != null || sale.totalAmount != null
            ? formatPriceWithSymbol(sale.netTotal, symbol)
            : '—');

    return Material(
      color: colorScheme.surface,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 44,
                child: Text(
                  '#${sale.saleId}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sale.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                    if (sale.flags.any) ...[
                      const SizedBox(height: 4),
                      SaleFlagMarks(flags: sale.flags),
                    ],
                    if (_subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        _subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                amount,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _subtitle {
    final parts = <String>[
      if (createdAtLabel != null && createdAtLabel!.isNotEmpty) createdAtLabel!,
      if (sale.lineCount != null) '${sale.lineCount} kalem',
      if (sale.orderRequestId != null) 'Talep #${sale.orderRequestId}',
    ];
    return parts.join(' · ');
  }
}
