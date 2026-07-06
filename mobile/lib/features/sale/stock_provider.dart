import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/json_field.dart';
import '../../core/network/sp_client.dart';
import '../auth/auth_provider.dart';

class StockRepository {
  StockRepository(this._client);

  final SpClient _client;

  Future<double?> addEntry({
    required int sizeId,
    required int quantity,
    String? note,
  }) async {
    final response = await _client.exec('Stock.Entry', {
      'SizeId': sizeId,
      'Quantity': quantity,
      'Note': ?note,
    });
    if (!response.success) {
      throw Exception(response.error ?? 'Stok girişi yapılamadı');
    }
    final rows = parseRowList(response.data);
    if (rows.isEmpty) return null;
    return (rows.first['StockQty'] as num?)?.toDouble();
  }
}

final stockRepositoryProvider = Provider<StockRepository>((ref) {
  return StockRepository(ref.watch(spClientProvider));
});
