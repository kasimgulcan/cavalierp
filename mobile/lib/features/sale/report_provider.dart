import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/json_field.dart';
import '../auth/auth_provider.dart';
import 'models/sales_report.dart';

class SalesReportFilter {
  const SalesReportFilter({
    this.dateFrom,
    this.dateTo,
  });

  final DateTime? dateFrom;
  final DateTime? dateTo;

  @override
  bool operator ==(Object other) =>
      other is SalesReportFilter &&
      other.dateFrom == dateFrom &&
      other.dateTo == dateTo;

  @override
  int get hashCode => Object.hash(dateFrom, dateTo);
}

String? _formatDate(DateTime? date) {
  if (date == null) return null;
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

final salesReportProvider = FutureProvider.autoDispose
    .family<SalesReport, SalesReportFilter>((ref, filter) async {
  final client = ref.watch(spClientProvider);
  final response = await client.exec('Report.SalesByProduct', {
    'DateFrom': _formatDate(filter.dateFrom),
    'DateTo': _formatDate(filter.dateTo),
  });
  if (!response.success) {
    throw Exception(response.error ?? 'Rapor yüklenemedi');
  }
  return SalesReport.fromRows(parseRowList(response.data));
});
