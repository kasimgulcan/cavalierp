import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/sp_client.dart';
import '../auth/auth_provider.dart';
import 'currency_selection.dart';
import 'models/cart_line.dart';
import 'models/product.dart';

final cartProvider = StateNotifierProvider<CartNotifier, List<CartLine>>((ref) {
  return CartNotifier(ref.watch(spClientProvider), ref);
});

class CartNotifier extends StateNotifier<List<CartLine>> {
  CartNotifier(this._spClient, this._ref) : super([]);

  final SpClient _spClient;
  final Ref _ref;

  double get total => state.fold(0, (sum, line) => sum + line.lineTotal);

  void addProduct(Product product, {int quantity = 1, double? unitPrice}) {
    final existing = state.indexWhere(
      (l) => l.product.sizeId == product.sizeId,
    );
    if (existing >= 0) {
      final updated = [...state];
      updated[existing].quantity += quantity;
      state = updated;
      return;
    }
    state = [
      ...state,
      CartLine(
        product: product,
        quantity: quantity,
        unitPrice: unitPrice ?? product.unitPrice,
      ),
    ];
  }

  void updateQuantity(int sizeId, int quantity) {
    state = [
      for (final line in state)
        if (line.product.sizeId == sizeId)
          CartLine(
            product: line.product,
            quantity: quantity,
            unitPrice: line.unitPrice,
          )
        else
          line,
    ];
  }

  void removeLine(int sizeId) {
    state = state.where((l) => l.product.sizeId != sizeId).toList();
  }

  void clear() => state = [];

  Future<Product?> lookupBarcode(String barcode) async {
    final currencyId = effectiveCurrencyId(
      _ref.read(selectedCurrencyIdProvider),
    );

    final response = await _spClient.exec('Product.GetByBarcode', {
      'Barcode': barcode,
      'CurrencyId': currencyId,
    });
    if (!response.success) return null;
    final rows = response.data as List<dynamic>;
    if (rows.isEmpty) return null;
    return Product.fromJson(Map<String, dynamic>.from(rows.first as Map));
  }

  Future<Map<String, dynamic>?> completeSale({
    required int currencyId,
    String? customer,
    int? paymentTypeId,
    String? note,
  }) async {
    final lines = _linesPayload();

    final response = await _spClient.exec('Sale.Create', {
      'CurrencyId': currencyId,
      'Customer': customer,
      'PaymentTypeId': paymentTypeId,
      'Lines': lines,
      'Note': note ?? '',
    });

    if (!response.success) return null;
    final rows = response.data as List<dynamic>;
    if (rows.isEmpty) return null;
    return Map<String, dynamic>.from(rows.first as Map);
  }

  Future<Map<String, dynamic>?> submitOrderRequest({
    required int currencyId,
    String? customer,
    String? note,
  }) async {
    final lines = _linesPayload();

    final response = await _spClient.exec('OrderRequest.Create', {
      'CurrencyId': currencyId,
      'Customer': customer,
      'Lines': lines,
      'Note': note ?? '',
    });

    if (!response.success) return null;
    final rows = response.data as List<dynamic>;
    if (rows.isEmpty) return null;
    return Map<String, dynamic>.from(rows.first as Map);
  }

  List<Map<String, dynamic>> _linesPayload() => state
      .map(
        (l) => {
          'SizeId': l.product.sizeId,
          'Product': l.product.displayName,
          'Quantity': l.quantity,
          'UnitPrice': l.unitPrice,
          'ListPrice': l.product.listPrice,
        },
      )
      .toList();
}
