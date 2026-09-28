import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format/price_format.dart';
import 'currency_display.dart';
import 'currency_provider.dart';
import 'models/sale_flags.dart';

class SaleSummaryScreen extends ConsumerWidget {
  const SaleSummaryScreen({super.key, required this.sale});

  final Map<String, dynamic> sale;

  double? get _totalAmount {
    final value = sale['TotalAmount'];
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final saleId = sale['SaleId'];
    final orderRequestId = sale['OrderRequestId'];
    final currency = ref.watch(selectedCurrencyProvider);
    final symbol = currencySymbolFrom(currency);
    final totalLabel = _totalAmount != null
        ? formatSaleMoney(roundSaleMoney(_totalAmount!), symbol)
        : null;
    final flags = SaleFlags.fromJson(sale);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Satış Özeti'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        size: 48,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Satış kaydedildi',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Satış başarıyla tamamlandı. Detayları aşağıda görebilirsiniz.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    Card(
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
                              color: colorScheme.primary.withValues(alpha: 0.55),
                            ),
                            child: const SizedBox(height: 4),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (saleId != null)
                                  _SummaryRow(
                                    icon: Icons.receipt_long_outlined,
                                    label: 'Satış no',
                                    value: '#$saleId',
                                  ),
                                if (totalLabel != null) ...[
                                  if (saleId != null) const SizedBox(height: 16),
                                  Text(
                                    'Toplam tutar',
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    totalLabel,
                                    style: theme.textTheme.headlineMedium?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                ],
                                if (flags.kind != null) ...[
                                  const SizedBox(height: 18),
                                  Icon(
                                    Icons.flag_rounded,
                                    size: 28,
                                    color: SaleFlagStyle.of(flags.kind!).color,
                                  ),
                                ],
                                if (orderRequestId != null) ...[
                                  const SizedBox(height: 18),
                                  const Divider(height: 1),
                                  const SizedBox(height: 14),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: _SummaryRow(
                                          icon: Icons.assignment_outlined,
                                          label: 'Kaynak talep',
                                          value: '#$orderRequestId',
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () => context
                                            .push('/orders/$orderRequestId'),
                                        child: const Text('Görüntüle'),
                                      ),
                                    ],
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
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (saleId != null)
                    OutlinedButton.icon(
                      onPressed: () => context.push('/sales/$saleId'),
                      icon: const Icon(Icons.open_in_new_rounded),
                      label: const Text('Satışı Görüntüle'),
                    ),
                  if (saleId != null) const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: () => context.go('/home'),
                    icon: const Icon(Icons.home_outlined),
                    label: const Text('Ana Sayfa'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
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
        Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
