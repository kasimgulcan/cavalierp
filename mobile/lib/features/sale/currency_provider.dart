import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/json_field.dart';
import '../auth/auth_provider.dart';
import 'currency_selection.dart';

final currenciesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final client = ref.watch(spClientProvider);
  final response = await client.exec('GetCurrency', {}, auth: false);
  if (!response.success) {
    throw Exception(response.error ?? 'Para birimleri yüklenemedi');
  }

  final rows = parseRowList(response.data);
  if (rows.isEmpty) {
    throw Exception('Para birimi listesi boş');
  }
  return rows;
});

final selectedCurrencyProvider = Provider<Map<String, dynamic>?>((ref) {
  final currencyId = ref.watch(selectedCurrencyIdProvider);
  final currencies = ref.watch(currenciesProvider);
  return currencies.maybeWhen(
    data: (items) {
      if (items.isEmpty) return null;
      return items.cast<Map<String, dynamic>?>().firstWhere(
            (c) => c!.intField('CurrencyId') == currencyId,
            orElse: () => items.first,
          );
    },
    orElse: () => null,
  );
});
