import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format/price_format.dart';
import 'currency_display.dart';
import 'currency_provider.dart';
import 'models/sales_report.dart';
import 'report_provider.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  DateTime? _dateFrom;
  DateTime? _dateTo;
  late SalesReportFilter _filter;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _dateFrom = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 30));
    _dateTo = DateTime(now.year, now.month, now.day);
    _filter = _buildFilter();
  }

  SalesReportFilter _buildFilter() => SalesReportFilter(
        dateFrom: _dateFrom,
        dateTo: _dateTo,
      );

  void _applyFilter() => setState(() => _filter = _buildFilter());

  Future<void> _pickDate({required bool isFrom}) async {
    final initial = isFrom ? _dateFrom : _dateTo;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _dateFrom = DateTime(picked.year, picked.month, picked.day);
      } else {
        _dateTo = DateTime(picked.year, picked.month, picked.day);
      }
    });
    _applyFilter();
  }

  String _formatDisplayDate(DateTime? date) {
    if (date == null) return '—';
    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final reportAsync = ref.watch(salesReportProvider(_filter));
    final currency = ref.watch(selectedCurrencyProvider);
    final symbol = currencySymbolFrom(currency);

    return Scaffold(
      appBar: AppBar(title: const Text('Raporlar')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Text(
              'Satış raporu',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDate(isFrom: true),
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: Text(_formatDisplayDate(_dateFrom)),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('—'),
                ),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDate(isFrom: false),
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: Text(_formatDisplayDate(_dateTo)),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: reportAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _ReportError(
                message: error.toString(),
                onRetry: () => ref.invalidate(salesReportProvider(_filter)),
              ),
              data: (report) => RefreshIndicator(
                onRefresh: () async =>
                    ref.invalidate(salesReportProvider(_filter)),
                child: report.products.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 64),
                          Center(child: Text('Bu tarih aralığında satış yok')),
                        ],
                      )
                    : ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                        children: [
                          _ReportSummaryCard(
                            quantity: report.totalQuantity,
                            amount: report.totalAmount,
                            symbol: symbol,
                          ),
                          const SizedBox(height: 12),
                          ...report.products.map(
                            (group) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _ProductReportTile(
                                group: group,
                                symbol: symbol,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportSummaryCard extends StatelessWidget {
  const _ReportSummaryCard({
    required this.quantity,
    required this.amount,
    required this.symbol,
  });

  final int quantity;
  final double amount;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
                label: 'Toplam adet',
                value: formatStock(quantity.toDouble()),
              ),
            ),
            Container(
              width: 1,
              height: 40,
              color: colorScheme.outlineVariant,
            ),
            Expanded(
              child: _SummaryMetric(
                label: 'Toplam tutar',
                value: formatPriceWithSymbol(roundSaleMoney(amount), symbol, decimals: 0),
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

    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _ProductReportTile extends StatelessWidget {
  const _ProductReportTile({
    required this.group,
    required this.symbol,
  });

  final SalesReportProductGroup group;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final styleName = group.styleName?.trim();

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      color: colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (styleName != null && styleName.isNotEmpty)
                Text(
                  styleName,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              Text(
                group.productName,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (group.color?.trim().isNotEmpty == true) ...[
                const SizedBox(height: 2),
                Text(
                  group.color!.trim(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              '${group.totalQuantity} adet · ${formatPriceWithSymbol(roundSaleMoney(group.totalAmount), symbol, decimals: 0)}',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          children: [
            const Divider(height: 1),
            const SizedBox(height: 8),
            ...group.sizes.map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _SizeReportRow(line: line, symbol: symbol),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SizeReportRow extends StatelessWidget {
  const _SizeReportRow({required this.line, required this.symbol});

  final SalesReportSizeLine line;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sizeLabel = line.sizeLabel?.trim();

    return Row(
      children: [
        Expanded(
          child: Text(
            sizeLabel != null && sizeLabel.isNotEmpty
                ? 'Beden: $sizeLabel'
                : line.productName,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          '${line.quantity} adet',
          style: theme.textTheme.labelMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          formatPriceWithSymbol(roundSaleMoney(line.amount), symbol, decimals: 0),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ReportError extends StatelessWidget {
  const _ReportError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 48),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(message, textAlign: TextAlign.center),
        ),
        const SizedBox(height: 16),
        Center(
          child: FilledButton(
            onPressed: onRetry,
            child: const Text('Tekrar dene'),
          ),
        ),
      ],
    );
  }
}
